param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [int]$IntervalSeconds = 300,
    [switch]$RunOnce
)

$ErrorActionPreference = 'Continue'
if ($PSVersionTable.PSEdition -eq 'Core') {
    $ps5 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath,'-ConfigPath',$ConfigPath,'-IntervalSeconds',[string]$IntervalSeconds)
    if ($RunOnce) { $args += '-RunOnce' }
    $proc = Start-Process -FilePath $ps5 -ArgumentList $args -Wait -PassThru -WindowStyle Hidden
    exit $proc.ExitCode
}

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.StateDir, $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'moonlight-guard.log'
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

function Write-MoonlightGuardLog {
    param([string]$Message)
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
}

function Get-RecoveryScript {
    param([Parameter(Mandatory=$true)][string]$Name)
    $roots = @(
        'F:\backup\windowsapps\installed\tv\tizen\moonlight-setup-guardian\bin',
        'F:\study\Systems\Windows\Media\GameStreaming\SamsungTizenMoonlightHostKit\scripts\Recovery',
        'F:\backup\windowsapps\installed\tv\tizen\fresh-windows-moonlight-bootstrap\payload\Recovery',
        'F:\backup\windowsapps\install\SamsungTvMoonlightRecovery\Recovery',
        'F:\backup\windowsapps\install\SamsungTvMoonlightRecovery'
    )
    foreach ($root in $roots) {
        $candidate = Join-Path $root $Name
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }
    return $null
}

function Invoke-RecoveryScript {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string[]]$Arguments = @(),
        [switch]$IgnoreFailure
    )
    $script = Get-RecoveryScript -Name $Name
    if (-not $script) {
        Write-MoonlightGuardLog "SCRIPT_MISSING name=$Name"
        if (-not $IgnoreFailure) { throw "Moonlight recovery script missing: $Name" }
        return
    }
    Write-MoonlightGuardLog "SCRIPT_READY name=$Name path=`"$script`" args=$($Arguments -join ' ')"
    $output = & $ps -NoProfile -ExecutionPolicy Bypass -File $script @Arguments 2>&1
    $exit = $LASTEXITCODE
    $joined = (($output | Out-String) -replace '\r?\n',' | ').Trim()
    Write-MoonlightGuardLog "SCRIPT_EXIT name=$Name exit=$exit output=`"$joined`""
    if ($exit -ne 0 -and -not $IgnoreFailure) {
        throw "$Name failed with exit $exit"
    }
}

function Ensure-MoonlightRecoveryStablePath {
    $payloadRecovery = 'F:\backup\windowsapps\installed\tv\tizen\fresh-windows-moonlight-bootstrap\payload\Recovery'
    $stableRoot = 'F:\backup\windowsapps\install\SamsungTvMoonlightRecovery'
    $stableRecovery = Join-Path $stableRoot 'Recovery'
    $requiredScripts = @(
        'Ensure-SunshineTizenStable1080p60.ps1',
        'Protect-MoonlightStreamRealtime.ps1',
        'Start-AppOnMoonlightVddOnce.ps1',
        'Recover-SamsungTvMoonlight.ps1',
        'Test-MoonlightPerformanceReadiness.ps1'
    )

    if (-not (Test-Path -LiteralPath $payloadRecovery -PathType Container)) {
        Write-MoonlightGuardLog "MOONLIGHT_RECOVERY_PAYLOAD_MISSING path=`"$payloadRecovery`""
        return
    }

    foreach ($target in @($stableRoot, $stableRecovery)) {
        try {
            New-Item -ItemType Directory -Force -Path $target | Out-Null
            foreach ($scriptName in $requiredScripts) {
                $source = Join-Path $payloadRecovery $scriptName
                $destination = Join-Path $target $scriptName
                if ((Test-Path -LiteralPath $source -PathType Leaf) -and -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
                    Copy-Item -LiteralPath $source -Destination $destination -Force -ErrorAction Stop
                    Write-MoonlightGuardLog "MOONLIGHT_RECOVERY_SCRIPT_RESTORED target=`"$destination`" source=`"$source`""
                }
            }
        } catch {
            Write-MoonlightGuardLog "MOONLIGHT_RECOVERY_STABLE_PATH_REPAIR_FAILED target=`"$target`" error=`"$($_.Exception.Message)`""
        }
    }
}

function Remove-MoonlightStandaloneTrayStartup {
    try {
        $runPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
        $value = (Get-ItemProperty -Path $runPath -Name 'MoonlightSetupGuardian' -ErrorAction SilentlyContinue).MoonlightSetupGuardian
        if ($value) {
            Remove-ItemProperty -Path $runPath -Name 'MoonlightSetupGuardian' -ErrorAction SilentlyContinue
            Write-MoonlightGuardLog "STANDALONE_TRAY_RUN_REMOVED value=`"$value`""
        }
    } catch {
        Write-MoonlightGuardLog "STANDALONE_TRAY_RUN_REMOVE_FAILED error=`"$($_.Exception.Message)`""
    }

    foreach ($taskName in @('MoonlightSetupGuardian','moonlight','\MichStartupMaster\moonlight')) {
        $output = & (Join-Path $env:SystemRoot 'System32\schtasks.exe') /Delete /F /TN $taskName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-MoonlightGuardLog "STANDALONE_TRAY_TASK_DELETED name=$taskName"
        } elseif (($output -join ' ') -notmatch 'cannot find|does not exist|ERROR: The system cannot find') {
            Write-MoonlightGuardLog "STANDALONE_TRAY_TASK_DELETE_SKIPPED name=$taskName output=`"$((($output | Out-String) -replace '\r?\n',' | ').Trim())`""
        }
    }

    Get-CimInstance Win32_Process |
        Where-Object { $_.ExecutablePath -ieq 'F:\backup\windowsapps\installed\tv\tizen\moonlight-setup-guardian\bin\MoonlightSetupGuardian.exe' } |
        ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            Write-MoonlightGuardLog "STANDALONE_TRAY_PROCESS_STOPPED pid=$($_.ProcessId)"
        }
}

function Remove-PrimaryForcingFromSunshineApps {
    $appsJson = 'C:\Program Files\Sunshine\config\apps.json'
    if (-not (Test-Path -LiteralPath $appsJson -PathType Leaf)) {
        Write-MoonlightGuardLog "SUNSHINE_APPS_JSON_MISSING path=`"$appsJson`""
        return
    }
    try {
        $apps = Get-Content -Raw -LiteralPath $appsJson | ConvertFrom-Json
        foreach ($app in $apps.apps) {
            if ($app.'prep-cmd') {
                $app.'prep-cmd' = @($app.'prep-cmd' | Where-Object {
                    ($_.do -notmatch 'Set-MoonlightVddPrimary|Restore-PhysicalDisplayPrimary|WindowGuard') -and
                    ($_.undo -notmatch 'Set-MoonlightVddPrimary|Restore-PhysicalDisplayPrimary|WindowGuard')
                })
            }
        }
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [IO.File]::WriteAllText($appsJson, ($apps | ConvertTo-Json -Depth 100), $utf8NoBom)
        Write-MoonlightGuardLog "SUNSHINE_APPS_PRIMARY_FORCING_REMOVED path=`"$appsJson`""
    } catch {
        Write-MoonlightGuardLog "SUNSHINE_APPS_PRIMARY_FORCING_REMOVE_FAILED error=`"$($_.Exception.Message)`""
    }
}

function Repair-SunshineLiveInstall {
    $liveRoot = 'C:\Program Files\Sunshine'
    $payloadRoot = 'F:\backup\windowsapps\installed\tv\tizen\fresh-windows-moonlight-bootstrap\payload\Sunshine'
    $required = @(
        (Join-Path $liveRoot 'tools\sunshinesvc.exe'),
        (Join-Path $liveRoot 'config\sunshine.conf'),
        (Join-Path $liveRoot 'config\apps.json')
    )

    $missing = @($required | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
    if ($missing.Count -gt 0) {
        if (-not (Test-Path -LiteralPath $payloadRoot -PathType Container)) {
            Write-MoonlightGuardLog "SUNSHINE_PAYLOAD_MISSING path=`"$payloadRoot`" missing=`"$($missing -join ';')`""
            return
        }
        try {
            New-Item -ItemType Directory -Force -Path $liveRoot | Out-Null
            Get-ChildItem -LiteralPath $payloadRoot -Force | ForEach-Object {
                Copy-Item -LiteralPath $_.FullName -Destination $liveRoot -Recurse -Force -ErrorAction Stop
            }
            Write-MoonlightGuardLog "SUNSHINE_LIVE_INSTALL_RESTORED source=`"$payloadRoot`" target=`"$liveRoot`" missingBefore=`"$($missing -join ';')`""
        } catch {
            Write-MoonlightGuardLog "SUNSHINE_LIVE_INSTALL_RESTORE_FAILED error=`"$($_.Exception.Message)`""
        }
    }

    try {
        $service = Get-Service -Name 'SunshineService' -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -ne 'Running') {
                Start-Service -Name 'SunshineService' -ErrorAction Stop
                Start-Sleep -Seconds 2
            }
            $service = Get-Service -Name 'SunshineService' -ErrorAction Stop
            Write-MoonlightGuardLog "SUNSHINE_SERVICE_STATUS status=$($service.Status) startType=$($service.StartType)"
        } else {
            Write-MoonlightGuardLog 'SUNSHINE_SERVICE_MISSING'
        }
    } catch {
        Write-MoonlightGuardLog "SUNSHINE_SERVICE_START_FAILED error=`"$($_.Exception.Message)`""
    }
}

function Invoke-MoonlightGuardPass {
    Write-MoonlightGuardLog 'MOONLIGHT_GUARD_PASS_START'
    Remove-MoonlightStandaloneTrayStartup
    Ensure-MoonlightRecoveryStablePath
    Repair-SunshineLiveInstall
    Remove-PrimaryForcingFromSunshineApps
    Invoke-RecoveryScript -Name 'Stop-MoonlightVddWindowGuard.ps1' -IgnoreFailure
    Invoke-RecoveryScript -Name 'Repair-WindowsDesktopWallpaper.ps1' -IgnoreFailure
    Invoke-RecoveryScript -Name 'Ensure-PCMonitor4K160.ps1' -Arguments @('-VerifyOnly') -IgnoreFailure
    Invoke-RecoveryScript -Name 'Recover-SamsungTvMoonlight.ps1' -Arguments @('-VerifyOnly','-NoElevate') -IgnoreFailure
    if ($env:SUNSHINE_PASSWORD) {
        Invoke-RecoveryScript -Name 'Test-MoonlightPerformanceReadiness.ps1' -Arguments @('-PingCount','3') -IgnoreFailure
    } else {
        Write-MoonlightGuardLog 'SUNSHINE_API_READINESS_SKIPPED reason=SUNSHINE_PASSWORD_NOT_SET recoveryReadyCheckAlreadyPassed=True'
    }
    Write-MoonlightGuardLog 'MOONLIGHT_GUARD_PASS_DONE'
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\RemoteCommandCenterMoonlightGuard', [ref]$createdNew)
if (-not $createdNew) {
    Write-MoonlightGuardLog 'MOONLIGHT_GUARD_ALREADY_RUNNING exit=True'
    exit 0
}

try {
    Write-MoonlightGuardLog "MOONLIGHT_GUARD_STARTED intervalSeconds=$IntervalSeconds"
    while ($true) {
        try {
            Invoke-MoonlightGuardPass
        } catch {
            Write-MoonlightGuardLog "MOONLIGHT_GUARD_PASS_FAILED error=`"$($_.Exception.Message)`""
        }
        if ($RunOnce) { break }
        Start-Sleep -Seconds ([Math]::Max(30, $IntervalSeconds))
    }
} finally {
    try { $mutex.ReleaseMutex() | Out-Null } catch {}
    $mutex.Dispose()
}
