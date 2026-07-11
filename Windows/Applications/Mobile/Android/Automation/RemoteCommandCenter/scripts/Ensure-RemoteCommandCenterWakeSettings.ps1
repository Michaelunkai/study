param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [switch]$VerifyOnly,
    [switch]$PowerOnly
)

$ErrorActionPreference = 'Continue'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'wake-settings.log'
$powercfg = Join-Path $env:SystemRoot 'System32\powercfg.exe'

function Write-WakeLog {
    param([string]$Message)
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
}

if (-not $VerifyOnly) {
    & $powercfg /hibernate on | Out-Null
    & $powercfg /hibernate /type full | Out-Null
    if (-not $PowerOnly) {
        & $powercfg /deviceenablewake 'Realtek PCIe 2.5GbE Family Controller' | Out-Null

        foreach ($setting in @(
            @{ DisplayName = 'Wake on Magic Packet'; DisplayValue = 'Enabled' },
            @{ DisplayName = 'Wake on magic packet when system is in the S0ix power state'; DisplayValue = 'Enabled' },
            @{ DisplayName = 'Wake on pattern match'; DisplayValue = 'Enabled' },
            @{ DisplayName = 'Shutdown Wake-On-Lan'; DisplayValue = 'Enabled' },
            @{ DisplayName = 'WOL & Shutdown Link Speed'; DisplayValue = 'Not Speed Down' },
            @{ DisplayName = 'Energy-Efficient Ethernet'; DisplayValue = 'Disabled' },
            @{ DisplayName = 'Green Ethernet'; DisplayValue = 'Disabled' },
            @{ DisplayName = 'Advanced EEE'; DisplayValue = 'Disabled' },
            @{ DisplayName = 'Power Saving Mode'; DisplayValue = 'Disabled' },
            @{ DisplayName = 'Gigabit Lite'; DisplayValue = 'Disabled' }
        )) {
            try {
                Set-NetAdapterAdvancedProperty -Name 'Ethernet' -DisplayName $setting.DisplayName `
                    -DisplayValue $setting.DisplayValue -NoRestart -ErrorAction Stop
            } catch {
                Write-WakeLog "WAKE_PROPERTY_SKIPPED name=`"$($setting.DisplayName)`" error=`"$($_.Exception.Message)`""
            }
        }
    }

    $schemeText = (& $powercfg /getactivescheme | Out-String)
    $schemeMatch = [regex]::Match($schemeText, '([0-9a-fA-F-]{36})')
    if ($schemeMatch.Success) {
        $scheme = $schemeMatch.Groups[1].Value
        $subSleep = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
        $hibernateAfter = '9d7815a6-7ee4-497e-8888-515a05f02364'
        $hybridSleep = '94ac6d29-73ce-41a6-809f-6363ba21b47e'
        $allowStandby = 'abfc2519-3608-4c2a-94ea-171b0ed546ab'
        & $powercfg /setacvalueindex $scheme $subSleep $hibernateAfter 0 | Out-Null
        & $powercfg /setdcvalueindex $scheme $subSleep $hibernateAfter 0 | Out-Null
        & $powercfg /setacvalueindex $scheme $subSleep $hybridSleep 0 | Out-Null
        & $powercfg /setdcvalueindex $scheme $subSleep $hybridSleep 0 | Out-Null
        & $powercfg /setacvalueindex $scheme $subSleep $allowStandby 1 | Out-Null
        & $powercfg /setdcvalueindex $scheme $subSleep $allowStandby 1 | Out-Null
        & $powercfg /setactive $scheme | Out-Null
    }

    # Apply hibernation last. On this firmware, changing Allow Standby can briefly
    # hide hibernation until the full hiberfile is recreated.
    & $powercfg /hibernate on | Out-Null
    & $powercfg /hibernate /type full | Out-Null
}

$availableStates = (& $powercfg /a | Out-String)
$wakeDevices = (& $powercfg /devicequery wake_armed | Out-String)
$adapter = Get-NetAdapter -Name 'Ethernet' -ErrorAction SilentlyContinue
$magic = Get-NetAdapterAdvancedProperty -Name 'Ethernet' -DisplayName 'Wake on Magic Packet' -ErrorAction SilentlyContinue
$shutdownWol = Get-NetAdapterAdvancedProperty -Name 'Ethernet' -DisplayName 'Shutdown Wake-On-Lan' -ErrorAction SilentlyContinue
$result = [ordered]@{
    ok = [bool]$adapter
    verifyOnly = [bool]$VerifyOnly
    powerOnly = [bool]$PowerOnly
    adapterStatus = if ($adapter) { [string]$adapter.Status } else { 'missing' }
    wakeArmed = $wakeDevices -match 'Realtek PCIe 2\.5GbE Family Controller'
    magicPacket = [string]$magic.DisplayValue
    shutdownWakeOnLan = [string]$shutdownWol.DisplayValue
    s3Available = $availableStates -match 'Standby \(S3\)'
    hibernateAvailable = ($availableStates -split 'The following sleep states are not available on this system:')[0] -match 'Hibernate'
}
Write-WakeLog ("WAKE_SETTINGS_RESULT " + ($result | ConvertTo-Json -Compress))
$result | ConvertTo-Json -Compress
if (-not $result.ok -or -not $result.wakeArmed -or $result.magicPacket -ne 'Enabled' -or -not $result.s3Available -or -not $result.hibernateAvailable) {
    exit 1
}
