param(
    [Parameter(Mandatory = $true)]
    [string]$Action,
    [Parameter(Mandatory = $true)]
    [string]$Nonce,
    [string]$RequestHash = '',
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [switch]$ProofOnly
)

$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
. (Join-Path $PSScriptRoot 'RemoteCommandCenter.Protocol.ps1')
$statusDir = Join-Path $config.StateDir 'action-status'
New-Item -ItemType Directory -Force -Path $statusDir | Out-Null
$safeNonce = $Nonce -replace '[^A-Za-z0-9_-]', '_'
$statusPath = Join-Path $statusDir "$safeNonce.json"

function Write-ActionStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$State,
        [int]$ExitCode = 0,
        [string]$Message = ''
    )
    $safeMessage = [string]$Message
    foreach ($secret in @([string]$config.SharedKey, [string]$config.TvToken, [string]$config.CommandTopic, [string]$config.StatusTopic)) {
        if (-not [string]::IsNullOrWhiteSpace($secret)) { $safeMessage = $safeMessage.Replace($secret, '[redacted]') }
    }
    if ($safeMessage.Length -gt 240) { $safeMessage = $safeMessage.Substring(0, 240) }
    $record = New-RccActionStatus -Nonce $Nonce -Action $Action -RequestHash $RequestHash -State $State -ExitCode $ExitCode -Message $safeMessage -SharedKey ([string]$config.SharedKey)
    Write-RccActionStatusFile -Path $statusPath -Record $record | Out-Null
    if ($State -in @('running', 'completed', 'failed', 'skipped', 'unconfirmed')) {
        Publish-RccActionStatus -Record $record -Config $config | Out-Null
    }
}

function Get-ActionLockName {
    $baseAction = $Action
    if ($baseAction -like 'terminal_line:*') { $baseAction = 'terminal_line' }
    if ($baseAction -like 'tv_set_volume:*') { $baseAction = 'tv_set_volume' }
    $safeAction = $baseAction -replace '[^A-Za-z0-9_-]', '_'
    return "Global\RemoteCommandCenterAction_$safeAction"
}

function Get-ActionTimeoutSeconds {
    if ($Action -like 'terminal_line:*') { return 330 }
    switch ($Action) {
        'youtube_tizen' { return 180 }
        'moonlight_toggle' { return 180 }
        'tv_force_reboot' { return 240 }
        default { return 180 }
    }
}

if ($RequestHash -eq '') {
    try { $RequestHash = [string](Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json).requestHash } catch {}
}
if (-not (Test-RccAction -Action $Action) -or $Nonce -cnotmatch '^[A-Za-z0-9_-]{16,128}$') {
    Write-ActionStatus -State 'failed' -ExitCode 2 -Message 'Unsupported action or invalid request nonce.'
    exit 2
}

$mutex = [Threading.Mutex]::new($false, (Get-ActionLockName))
$lockTaken = $false
try {
    try {
        $lockTaken = $mutex.WaitOne(0)
    } catch [Threading.AbandonedMutexException] {
        $lockTaken = $true
    }
    if (-not $lockTaken) {
        Write-ActionStatus -State 'skipped' -Message 'An action with the same single-flight key is already running.'
        exit 0
    }

    Write-ActionStatus -State 'running'
    $actionScript = Join-Path $PSScriptRoot 'Invoke-RemoteCommandCenterAction.ps1'
    $arguments = @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        $actionScript,
        '-Action',
        $Action,
        '-Nonce',
        $Nonce,
        '-ConfigPath',
        $ConfigPath
    )
    if ($ProofOnly) { $arguments += '-ProofOnly' }

    $process = Start-Process `
        -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
        -ArgumentList $arguments `
        -WindowStyle Hidden `
        -PassThru
    $timeoutSeconds = Get-ActionTimeoutSeconds
    if ($timeoutSeconds -gt 0) {
        if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
            $workerPid = $process.Id
            try {
                & "$env:SystemRoot\System32\taskkill.exe" /PID $workerPid /T /F 2>$null | Out-Null
            } catch {
            }
            $timeoutState = if ($Action -like 'terminal_line:*') { 'unconfirmed' } else { 'failed' }
            $timeoutMessage = if ($Action -like 'terminal_line:*') {
                'The terminal runner did not report a result before the bounded wait ended.'
            } else {
                "Action exceeded its $timeoutSeconds-second completion limit."
            }
            Write-ActionStatus -State $timeoutState -ExitCode 124 -Message $timeoutMessage
            exit 124
        }
    } else {
        $process.WaitForExit()
    }
    if ($process.ExitCode -ne 0) {
        if ($Action -like 'terminal_line:*' -and $process.ExitCode -eq 124) {
            Write-ActionStatus -State 'unconfirmed' -ExitCode 124 -Message 'The terminal runner did not report a result before the bounded wait ended.'
            exit 124
        }
        Write-ActionStatus -State 'failed' -ExitCode $process.ExitCode -Message "Action process exited with code $($process.ExitCode)."
        exit $process.ExitCode
    }
    Write-ActionStatus -State 'completed'
} catch {
    Write-ActionStatus -State 'failed' -ExitCode 1 -Message $_.Exception.Message
    exit 1
} finally {
    if ($lockTaken) {
        try { $mutex.ReleaseMutex() } catch {}
    }
    $mutex.Dispose()
}
