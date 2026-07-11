param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [int]$IntervalSeconds = 5,
    [int]$PolicyRefreshSeconds = 1800,
    [int]$NetworkRefreshSeconds = 600,
    [int]$CapabilityCheckSeconds = 30
)

$ErrorActionPreference = 'Continue'
$script = Join-Path $PSScriptRoot 'Set-RemoteCommandCenterStayAwake.ps1'
$wakeSettings = Join-Path $PSScriptRoot 'Ensure-RemoteCommandCenterWakeSettings.ps1'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'power-guard.log'

function Write-PowerGuardLog {
    param([string]$Message)
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
}

function Repair-RccNetworkSurface {
    try {
        $netsh = Join-Path $env:SystemRoot 'System32\netsh.exe'
        & $netsh advfirewall firewall delete rule name='RemoteCommandCenter Local Receiver' | Out-Null
        & $netsh advfirewall firewall delete rule name='RemoteCommandCenter Local Receiver 8777' | Out-Null
        & $netsh advfirewall firewall add rule name='RemoteCommandCenter Local Receiver 8777' dir=in action=allow protocol=TCP localport=8777 profile=any | Out-Null
        Write-PowerGuardLog "NETWORK_GUARD_FIREWALL_SET port=8777 profile=any exit=$LASTEXITCODE"
        $urlAcl = (& $netsh http show urlacl url=http://+:8777/rcc/ 2>&1 | Out-String)
        if ($urlAcl -notmatch 'http://\+:8777/rcc/') {
            & $netsh http add urlacl url=http://+:8777/rcc/ user=Everyone listen=yes | Out-Null
            Write-PowerGuardLog "NETWORK_GUARD_URLACL_ADDED prefix=http://+:8777/rcc/ exit=$LASTEXITCODE"
        } else {
            Write-PowerGuardLog "NETWORK_GUARD_URLACL_PRESENT prefix=http://+:8777/rcc/"
        }
    } catch {
        Write-PowerGuardLog "NETWORK_GUARD_FAILED error=""$($_.Exception.Message)"""
    }
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\RemoteCommandCenterPowerGuard', [ref]$createdNew)
if (-not $createdNew) {
    Write-PowerGuardLog 'POWER_GUARD_ALREADY_RUNNING exit=True'
    exit 0
}

try {
    Write-PowerGuardLog "POWER_GUARD_STARTED intervalSeconds=$IntervalSeconds policyRefreshSeconds=$PolicyRefreshSeconds networkRefreshSeconds=$NetworkRefreshSeconds capabilityCheckSeconds=$CapabilityCheckSeconds"
    $pass = 0
    $lastPolicyRefresh = [datetime]::MinValue
    $lastNetworkRefresh = [datetime]::MinValue
    $lastCapabilityCheck = [datetime]::MinValue
    while ($true) {
        try {
            $now = Get-Date
            if ($pass -eq 0 -or ($now - $lastPolicyRefresh).TotalSeconds -ge [Math]::Max(60, $PolicyRefreshSeconds)) {
                & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $script -ConfigPath $ConfigPath | Out-Null
                & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $wakeSettings -ConfigPath $ConfigPath |
                    ForEach-Object { Write-PowerGuardLog "WAKE_SETTINGS $_" }
                $lastPolicyRefresh = Get-Date
                Write-PowerGuardLog 'POWER_GUARD_POLICY_APPLIED'
            }
            if ($pass -eq 0 -or ($now - $lastNetworkRefresh).TotalSeconds -ge [Math]::Max(60, $NetworkRefreshSeconds)) {
                Repair-RccNetworkSurface
                $lastNetworkRefresh = Get-Date
                Write-PowerGuardLog 'POWER_GUARD_NETWORK_APPLIED'
            }
            if ($pass -eq 0 -or ($now - $lastCapabilityCheck).TotalSeconds -ge [Math]::Max(15, $CapabilityCheckSeconds)) {
                $available = (& "$env:SystemRoot\System32\powercfg.exe" /a | Out-String)
                $s3Available = $available -match '(?m)^\s*Standby \(S3\)\s*$'
                $hibernateAvailable = ($available -split 'The following sleep states are not available on this system:')[0] -match '(?m)^\s*Hibernate\s*$'
                if (-not $s3Available -or -not $hibernateAvailable) {
                    Write-PowerGuardLog "POWER_GUARD_CAPABILITY_REPAIR s3=$s3Available hibernate=$hibernateAvailable"
                    & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $wakeSettings -ConfigPath $ConfigPath -PowerOnly |
                        ForEach-Object { Write-PowerGuardLog "CAPABILITY_REPAIR $_" }
                }
                $lastCapabilityCheck = Get-Date
            }
        } catch {
            Write-PowerGuardLog "POWER_GUARD_FAILED error=""$($_.Exception.Message)"""
        }
        $pass++
        Start-Sleep -Seconds ([Math]::Max(1, $IntervalSeconds))
    }
} finally {
    try { $mutex.ReleaseMutex() | Out-Null } catch {}
    $mutex.Dispose()
}
