param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [int]$IntervalSeconds = 5
)

$ErrorActionPreference = 'Continue'
$script = Join-Path $PSScriptRoot 'Set-RemoteCommandCenterStayAwake.ps1'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'power-guard.log'

function Write-PowerGuardLog {
    param([string]$Message)
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\RemoteCommandCenterPowerGuard', [ref]$createdNew)
if (-not $createdNew) {
    Write-PowerGuardLog 'POWER_GUARD_ALREADY_RUNNING exit=True'
    exit 0
}

try {
    Write-PowerGuardLog "POWER_GUARD_STARTED intervalSeconds=$IntervalSeconds"
    while ($true) {
        try {
            & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $script -ConfigPath $ConfigPath | Out-Null
            Write-PowerGuardLog 'POWER_GUARD_APPLIED'
        } catch {
            Write-PowerGuardLog "POWER_GUARD_FAILED error=""$($_.Exception.Message)"""
        }
        Start-Sleep -Seconds ([Math]::Max(1, $IntervalSeconds))
    }
} finally {
    try { $mutex.ReleaseMutex() | Out-Null } catch {}
    $mutex.Dispose()
}
