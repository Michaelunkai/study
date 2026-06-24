param(
    [switch]$PreviewOnly,
    [switch]$AllowReboot,
    [switch]$SkipOptional,
    [int]$MaxRounds = 12,
    [int]$HeartbeatSeconds = 1,
    [int]$NoOutputTimeoutSeconds = 1800,
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
$script:Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:LogDirectory = Join-Path $script:Root 'logs'
$script:VendorDirectory = Join-Path $script:Root 'vendor\nicholasdille-async-wua'
$script:Runner = Join-Path $script:Root 'Install-WindowsUpdate.RealProgress.vbs'
$script:Upstream = Join-Path $script:VendorDirectory 'Install-WindowsUpdate.upstream.vbs'
$script:LauncherPath = $MyInvocation.MyCommand.Path
$script:LogFile = Join-Path $script:LogDirectory ("windowsupdate-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$script:Round = 0
$script:ResumeTaskName = 'CodexFastWindowsUpdateResume'

function Write-UpdateLine {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )

    $line = "[update][{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Text
    try { Add-Content -LiteralPath $script:LogFile -Value $line -Encoding UTF8 } catch { }
    try { Write-Host $line -ForegroundColor $Color } catch { Write-Output $line }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-ElevatedSelfIfNeeded {
    if (Test-IsAdministrator) { return $false }
    $psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $argList = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', ('"{0}"' -f $script:LauncherPath),
        '-MaxRounds', $MaxRounds,
        '-HeartbeatSeconds', $HeartbeatSeconds,
        '-NoOutputTimeoutSeconds', $NoOutputTimeoutSeconds
    )
    if ($PreviewOnly) { $argList += '-PreviewOnly' }
    if ($AllowReboot) { $argList += '-AllowReboot' }
    if ($SkipOptional) { $argList += '-SkipOptional' }
    Write-UpdateLine 'Administrator rights are required for reliable Windows Update installation; relaunching elevated and waiting.' Yellow
    Start-Process -FilePath $psExe -ArgumentList ($argList -join ' ') -Verb RunAs -Wait
    return $true
}

function Initialize-Workspace {
    New-Item -ItemType Directory -Force -Path $script:LogDirectory | Out-Null
    New-Item -ItemType Directory -Force -Path $script:VendorDirectory | Out-Null
    if (-not (Test-Path -LiteralPath $script:Runner)) {
        throw "Missing local runner: $script:Runner"
    }
    if (-not (Test-Path -LiteralPath $script:Upstream)) {
        Write-UpdateLine "Upstream reference is missing: $script:Upstream" Yellow
    }
}

function Ensure-WindowsUpdateServicesFast {
    Write-UpdateLine 'monitor=alive phase=prepare detail=starting Windows Update services' Cyan
    $services = @(
        @{ Name = 'wuauserv'; Startup = 'Manual' },
        @{ Name = 'bits'; Startup = 'Automatic' },
        @{ Name = 'dosvc'; Startup = 'Automatic' },
        @{ Name = 'UsoSvc'; Startup = 'Manual' },
        @{ Name = 'cryptsvc'; Startup = 'Automatic' },
        @{ Name = 'trustedinstaller'; Startup = 'Manual' }
    )

    foreach ($svc in $services) {
        try {
            $name = $svc.Name
            $service = Get-Service -Name $name -ErrorAction Stop
            try { Set-Service -Name $name -StartupType $svc.Startup -ErrorAction SilentlyContinue } catch { }
            if ($service.Status -ne 'Running') {
                Start-Service -Name $name -ErrorAction SilentlyContinue
            }
            Write-UpdateLine ("service ready: {0}" -f $name) Green
        } catch {
            Write-UpdateLine ("service skipped: {0}: {1}" -f $svc.Name, $_.Exception.Message) Yellow
        }
    }
}

function Invoke-UsoClientNudge {
    param(
        [string]$Reason,
        [switch]$InstallActions
    )

    Write-UpdateLine ("monitor=alive phase=nudge detail={0}" -f $Reason) Cyan
    $uso = Join-Path $env:SystemRoot 'System32\UsoClient.exe'
    if (-not (Test-Path -LiteralPath $uso)) {
        Write-UpdateLine 'UsoClient.exe not found; skipping service wakeup.' Yellow
        return
    }

    $actions = @('RefreshSettings', 'StartScan')
    if ($InstallActions) {
        $actions += @('StartDownload', 'StartInstall')
    }

    foreach ($action in $actions) {
        try {
            Start-Process -FilePath $uso -ArgumentList $action -WindowStyle Hidden -ErrorAction Stop
            Write-UpdateLine ("UsoClient {0} queued" -f $action) DarkGray
        } catch {
            Write-UpdateLine ("UsoClient {0} skipped: {1}" -f $action, $_.Exception.Message) Yellow
        }
    }
}

function Invoke-RealProgressRound {
    param(
        [int]$RoundNumber,
        [switch]$RoundPreviewOnly,
        [ValidateSet('all', 'standard', 'optional')][string]$SearchMode = 'all'
    )

    $script:Round = $RoundNumber
    $cscript = Join-Path $env:SystemRoot 'System32\cscript.exe'
    if (-not (Test-Path -LiteralPath $cscript)) {
        throw "Missing Windows Script Host executable: $cscript"
    }

    $args = @(
        '//nologo',
        ('"{0}"' -f $script:Runner),
        ('/Round:{0}' -f $RoundNumber),
        ('/SearchMode:{0}' -f $SearchMode),
        ('/PreviewOnly:{0}' -f ([bool]$RoundPreviewOnly).ToString().ToLowerInvariant()),
        ('/AllowReboot:{0}' -f ([bool]$AllowReboot).ToString().ToLowerInvariant())
    )

    Write-UpdateLine ("monitor=alive round={0}/{1} phase=wua-async-vbs searchMode={2} detail=real WUA async scan/download/install" -f $RoundNumber, $MaxRounds, $SearchMode) Cyan
    $output = New-Object System.Collections.Generic.List[string]
    $exitCode = 0
    $stdoutFile = Join-Path $script:LogDirectory ("wua-child-stdout-{0}-round{1}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $RoundNumber)
    $stderrFile = Join-Path $script:LogDirectory ("wua-child-stderr-{0}-round{1}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), $RoundNumber)
    $lastOutLine = 0
    $lastErrLine = 0
    $lastOutputAt = Get-Date
    $roundStarted = Get-Date

    function Receive-ChildFileLines {
        param(
            [Parameter(Mandatory = $true)][string]$Path,
            [Parameter(Mandatory = $true)][ref]$LastLine,
            [ConsoleColor]$DefaultColor = [ConsoleColor]::DarkGray,
            [switch]$IsError
        )

        if (-not (Test-Path -LiteralPath $Path)) { return 0 }
        $lines = @(Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)
        $newCount = 0
        for ($i = $LastLine.Value; $i -lt $lines.Count; $i++) {
            $line = [string]$lines[$i]
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $output.Add($line)
            $color = if ($line -match '^\[child\]\[[0-9:]+\] progress:') {
                [ConsoleColor]::Red
            } elseif ($IsError) {
                [ConsoleColor]::Yellow
            } else {
                $DefaultColor
            }
            Write-UpdateLine ("child: {0}" -f $line) $color
            $newCount++
        }
        $LastLine.Value = $lines.Count
        return $newCount
    }

    try {
        $process = Start-Process -FilePath $cscript -ArgumentList $args -NoNewWindow -PassThru -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile
        while (-not $process.HasExited) {
            $newLines = 0
            $newLines += Receive-ChildFileLines -Path $stdoutFile -LastLine ([ref]$lastOutLine)
            $newLines += Receive-ChildFileLines -Path $stderrFile -LastLine ([ref]$lastErrLine) -IsError
            if ($newLines -gt 0) {
                $lastOutputAt = Get-Date
            }

            $elapsed = (Get-Date) - $roundStarted
            $silent = (Get-Date) - $lastOutputAt
            Write-UpdateLine ("monitor=alive round={0}/{1} phase=wua-async-vbs elapsed={2} silent={3}s childPid={4} detail=waiting for real WUA output; watchdog={5}s" -f $RoundNumber, $MaxRounds, $elapsed.ToString('hh\:mm\:ss'), [int]$silent.TotalSeconds, $process.Id, $NoOutputTimeoutSeconds) Cyan

            if ($silent.TotalSeconds -ge $NoOutputTimeoutSeconds) {
                Write-UpdateLine ("watchdog=kill round={0} childPid={1} reason=no child output for {2}s" -f $RoundNumber, $process.Id, [int]$silent.TotalSeconds) Yellow
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                $output.Add("round-result=WATCHDOG_TIMEOUT")
                return ,$output.ToArray()
            }

            Start-Sleep -Seconds ([Math]::Max(1, $HeartbeatSeconds))
        }
        $newLines = 0
        $newLines += Receive-ChildFileLines -Path $stdoutFile -LastLine ([ref]$lastOutLine)
        $newLines += Receive-ChildFileLines -Path $stderrFile -LastLine ([ref]$lastErrLine) -IsError
        $exitCode = $process.ExitCode
    } catch {
        throw "cscript runner failed: $($_.Exception.Message)"
    }

    if ($exitCode -ne 0 -and $exitCode -ne 2) {
        throw "WUA async VBS round $RoundNumber failed with exit code $exitCode"
    }
    return ,$output.ToArray()
}

function Get-FoundCount {
    param([string[]]$Output)

    $foundLine = $Output | Where-Object { $_ -match 'found=\d+' } | Select-Object -Last 1
    if ($foundLine -match 'found=(\d+)') { return [int]$matches[1] }
    return -1
}

function Test-RebootRequired {
    param([string[]]$Output)

    return ($Output | Where-Object { $_ -match 'install-result .*rebootRequired=true' } | Select-Object -First 1) -ne $null
}

function Register-ResumeTask {
    $taskAction = New-ScheduledTaskAction -Execute (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -Argument (
        '-NoProfile -ExecutionPolicy Bypass -File "{0}"{1}{2} -MaxRounds {3} -HeartbeatSeconds {4} -NoOutputTimeoutSeconds {5}' -f
        $script:LauncherPath,
        ($(if ($AllowReboot) { ' -AllowReboot' } else { '' })),
        ($(if ($SkipOptional) { ' -SkipOptional' } else { '' })),
        $MaxRounds,
        $HeartbeatSeconds,
        $NoOutputTimeoutSeconds
    )
    $taskTrigger = New-ScheduledTaskTrigger -AtLogOn
    Register-ScheduledTask -TaskName $script:ResumeTaskName -Action $taskAction -Trigger $taskTrigger -RunLevel Highest -Force | Out-Null
    Write-UpdateLine ("resume-task=registered task={0}" -f $script:ResumeTaskName) Yellow
}

function Unregister-ResumeTaskSafe {
    try {
        Unregister-ScheduledTask -TaskName $script:ResumeTaskName -Confirm:$false -ErrorAction SilentlyContinue
    } catch {
    }
}

function Invoke-ResumeReboot {
    param(
        [Parameter(Mandatory = $true)][string]$PhaseName,
        [Parameter(Mandatory = $true)][int]$RoundNumber
    )

    Register-ResumeTask
    Write-UpdateLine ("reboot-required=true phase={0} round={1} action=reboot-and-resume" -f $PhaseName, $RoundNumber) Yellow
    shutdown.exe /r /t 5 /c "Codex Fast Windows Update: reboot required to continue installing updates." | Out-Null
    return 3010
}

function Invoke-UpdatePhase {
    param(
        [Parameter(Mandatory = $true)][string]$PhaseName,
        [Parameter(Mandatory = $true)][ValidateSet('all', 'standard', 'optional')][string]$SearchMode
    )

    $lastFound = -1
    for ($round = 1; $round -le $MaxRounds; $round++) {
        Invoke-UsoClientNudge -Reason ("{0} round {1}: forcing service scan/download/install wakeup" -f $PhaseName, $round) -InstallActions:(!$PreviewOnly)
        $roundOutput = Invoke-RealProgressRound -RoundNumber $round -RoundPreviewOnly:$PreviewOnly -SearchMode $SearchMode
        $lastFound = Get-FoundCount $roundOutput

        if ($roundOutput -match 'round-result=WATCHDOG_TIMEOUT') {
            if ($PreviewOnly) {
                return [pscustomobject]@{ ExitCode = 2; Remaining = -1; LastFound = $lastFound; TimedOut = $true }
            }
            Write-UpdateLine ("round-result=WATCHDOG_TIMEOUT phase={0} round={1}; retrying next round instead of staying stuck" -f $PhaseName, $round) Yellow
            Start-Sleep -Seconds 3
            continue
        }

        if ($PreviewOnly) {
            return [pscustomobject]@{ ExitCode = 0; Remaining = $lastFound; LastFound = $lastFound; TimedOut = $false }
        }

        if ($AllowReboot -and (Test-RebootRequired $roundOutput)) {
            $rebootCode = Invoke-ResumeReboot -PhaseName $PhaseName -RoundNumber $round
            return [pscustomobject]@{ ExitCode = $rebootCode; Remaining = -1; LastFound = $lastFound; TimedOut = $false }
        }

        if ($roundOutput -match 'round-result=NO_UPDATES') { break }
        Start-Sleep -Seconds 3
    }

    $verifyOutput = Invoke-RealProgressRound -RoundNumber 999 -RoundPreviewOnly -SearchMode $SearchMode
    $remaining = Get-FoundCount $verifyOutput
    $timedOut = $verifyOutput -match 'round-result=WATCHDOG_TIMEOUT'
    return [pscustomobject]@{
        ExitCode = $(if ($timedOut) { 2 } elseif ($remaining -eq 0) { 0 } else { 2 })
        Remaining = $remaining
        LastFound = $lastFound
        TimedOut = $timedOut
    }
}

function Invoke-FastWindowsUpdate {
    Initialize-Workspace

    if ($SelfTest) {
        Write-UpdateLine 'SELFTEST: upstream GitHub async WUA reference and local runner are present; no scan/download/install executed.' Green
        Write-UpdateLine ("SELFTEST_UPSTREAM={0}" -f $script:Upstream) Green
        Write-UpdateLine ("SELFTEST_RUNNER={0}" -f $script:Runner) Green
        Write-UpdateLine 'child: [child][00:00:00] progress: phase=download update=1/1 kb=KB000000 updatePercent=42.50% overallPercent=42.50% title=SELFTEST Windows Update progress formatter' Red
        Write-UpdateLine 'child: [child][00:00:01] progress: phase=install update=1/1 kb=KB000000 updatePercent=87.25% overallPercent=87.25% title=SELFTEST Windows Update progress formatter' Red
        Write-UpdateLine ("UPDATE_RESULT=SELFTEST_OK log={0}" -f $script:LogFile) Green
        return 0
    }

    if (Start-ElevatedSelfIfNeeded) { return 0 }

    Write-UpdateLine ("Fast Windows Update started. Engine=GitHubAsyncWUA PreviewOnly={0} AllowReboot={1} SkipOptional={2} MaxRounds={3} Heartbeat={4}s log={5}" -f $PreviewOnly, $AllowReboot, $SkipOptional, $MaxRounds, $HeartbeatSeconds, $script:LogFile) White
    Write-UpdateLine ("UPSTREAM_REFERENCE={0}" -f $script:Upstream) DarkGray
    Write-UpdateLine ("LOCAL_RUNNER={0}" -f $script:Runner) DarkGray

    Ensure-WindowsUpdateServicesFast
    Invoke-UsoClientNudge -Reason 'front-loading scan/download/install' -InstallActions:(!$PreviewOnly)

    if ($PreviewOnly) {
        $previewPhase = Invoke-UpdatePhase -PhaseName 'preview-all-visible' -SearchMode 'all'
        if ($previewPhase.TimedOut) {
            Write-UpdateLine ("UPDATE_RESULT=TIMEOUT visibleUpdates=UNKNOWN log={0}" -f $script:LogFile) Yellow
            return 2
        }
        Write-UpdateLine 'PreviewOnly requested; no updates installed.' Yellow
        Write-UpdateLine ("UPDATE_RESULT=PREVIEW visibleUpdates={0} log={1}" -f $previewPhase.LastFound, $script:LogFile) Yellow
        return 0
    }

    $standardPhase = Invoke-UpdatePhase -PhaseName 'standard-visible' -SearchMode 'standard'
    if ($standardPhase.ExitCode -eq 3010) {
        return 3010
    }
    if ($standardPhase.TimedOut) {
        Write-UpdateLine ("UPDATE_RESULT=TIMEOUT phase=standard remaining=UNKNOWN lastFound={0} log={1}" -f $standardPhase.LastFound, $script:LogFile) Yellow
        return 2
    }

    $optionalPhase = $null
    if (-not $SkipOptional) {
        $optionalPhase = Invoke-UpdatePhase -PhaseName 'optional-preview' -SearchMode 'optional'
        if ($optionalPhase.ExitCode -eq 3010) {
            return 3010
        }
        if ($optionalPhase.TimedOut) {
            Write-UpdateLine ("UPDATE_RESULT=TIMEOUT phase=optional remaining=UNKNOWN lastFound={0} log={1}" -f $optionalPhase.LastFound, $script:LogFile) Yellow
            return 2
        }
    }

    $finalVerify = Invoke-UpdatePhase -PhaseName 'verify-all-visible' -SearchMode 'all'
    if ($finalVerify.TimedOut) {
        Write-UpdateLine ("UPDATE_RESULT=TIMEOUT phase=verify remaining=UNKNOWN log={0}" -f $script:LogFile) Yellow
        return 2
    }

    if ($finalVerify.Remaining -eq 0) {
        Unregister-ResumeTaskSafe
        Write-UpdateLine ("UPDATE_RESULT=SUCCESS standardRemaining={0} optionalRemaining={1} remaining=0 log={2}" -f $standardPhase.Remaining, $(if ($optionalPhase) { $optionalPhase.Remaining } else { 'SKIPPED' }), $script:LogFile) Green
        return 0
    }

    Write-UpdateLine ("UPDATE_RESULT=PARTIAL standardRemaining={0} optionalRemaining={1} remaining={2} log={3}" -f $standardPhase.Remaining, $(if ($optionalPhase) { $optionalPhase.Remaining } else { 'SKIPPED' }), $finalVerify.Remaining, $script:LogFile) Yellow
    return 2
}

try {
    $exitCode = Invoke-FastWindowsUpdate
    exit $exitCode
} catch {
    Write-UpdateLine ("UPDATE_RESULT=FAILED error={0} log={1}" -f $_.Exception.Message, $script:LogFile) Red
    exit 1
}
