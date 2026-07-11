param(
    [Parameter(Mandatory = $true)]
    [string]$Action,
    [Parameter(Mandatory = $true)]
    [string]$Nonce,
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [switch]$ProofOnly
)

$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
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
    $record = [ordered]@{
        ok = ($State -in @('accepted', 'running', 'completed', 'skipped'))
        nonce = $Nonce
        action = $Action
        state = $State
        exitCode = $ExitCode
        message = $Message
        updatedUtc = [DateTimeOffset]::UtcNow.ToString('o')
    }
    [IO.File]::WriteAllText($statusPath, ($record | ConvertTo-Json -Compress), (New-Object Text.UTF8Encoding($false)))
}

function Get-ActionLockName {
    $baseAction = $Action
    if ($baseAction -like 'terminal_line:*') { $baseAction = 'terminal_line' }
    if ($baseAction -like 'tv_set_volume:*') { $baseAction = 'tv_set_volume' }
    $safeAction = $baseAction -replace '[^A-Za-z0-9_-]', '_'
    return "Global\RemoteCommandCenterAction_$safeAction"
}

function Get-ActionTimeoutSeconds {
    switch ($Action) {
        'youtube_tizen' { return 100 }
        default { return 0 }
    }
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
            Write-ActionStatus -State 'failed' -ExitCode 124 -Message "Action exceeded its $timeoutSeconds-second completion limit."
            exit 124
        }
    } else {
        $process.WaitForExit()
    }
    if ($process.ExitCode -ne 0) {
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
