param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json"
)

$ErrorActionPreference = 'Continue'
if ($PSVersionTable.PSEdition -eq 'Core') {
    $ps5 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $proc = Start-Process -FilePath $ps5 -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath,'-ConfigPath',$ConfigPath) -Wait -PassThru -WindowStyle Hidden
    exit $proc.ExitCode
}

$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.StateDir, $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'stay-awake.log'

function Write-StayAwakeLog {
    param([string]$Message)
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
}

$system32 = Join-Path $env:SystemRoot 'System32'
$powercfg = Join-Path $system32 'powercfg.exe'

Remove-Item -LiteralPath (Join-Path $config.StateDir 'sleep-toggle-state.txt') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath (Join-Path $config.StateDir 'hibernate-toggle-state.txt') -Force -ErrorAction SilentlyContinue

function Invoke-PowerCfg {
    param([string[]]$Arguments)
    $output = & $powercfg @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $joined = (($output | Out-String) -replace '\r?\n', ' | ').Trim()
    Write-StayAwakeLog ("POWERCFG args=""{0}"" exit={1} output=""{2}""" -f ($Arguments -join ' '), $exitCode, $joined)
    return $exitCode
}

function Get-RccWakeablePowerScheme {
    $planName = 'RemoteCommandCenter_Wakeable'
    $list = (& $powercfg /list | Out-String)
    $existing = [regex]::Match($list, 'Power Scheme GUID:\s+([0-9a-fA-F-]{36})\s+\(' + [regex]::Escape($planName) + '\)')
    if ($existing.Success) {
        Write-StayAwakeLog "POWER_SCHEME_FOUND guid=$($existing.Groups[1].Value) name=$planName"
        return $existing.Groups[1].Value
    }

    $createdText = (& $powercfg /duplicatescheme SCHEME_CURRENT | Out-String)
    $created = [regex]::Match($createdText, '([0-9a-fA-F-]{36})')
    if (-not $created.Success) {
        Write-StayAwakeLog "POWER_SCHEME_CREATE_FAILED output=""$($createdText -replace '\r?\n', ' | ')"""
        return 'SCHEME_CURRENT'
    }

    $guid = $created.Groups[1].Value
    & $powercfg /changename $guid $planName "RemoteCommandCenter wakeable sleep and Wake-on-LAN profile" | Out-Null
    Write-StayAwakeLog "POWER_SCHEME_CREATED guid=$guid name=$planName exit=$LASTEXITCODE"
    return $guid
}

function Set-RccAdapterProperty {
    param(
        [Parameter(Mandatory=$true)][string]$AdapterName,
        [Parameter(Mandatory=$true)][string]$DisplayName,
        [Parameter(Mandatory=$true)][string]$DisplayValue
    )

    if (-not (Get-Command Set-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue)) {
        Write-StayAwakeLog "NETADAPTER_PROPERTY_UNAVAILABLE adapter=""$AdapterName"" name=""$DisplayName"""
        return
    }

    try {
        Set-NetAdapterAdvancedProperty -Name $AdapterName -DisplayName $DisplayName -DisplayValue $DisplayValue -NoRestart -ErrorAction Stop
        Write-StayAwakeLog "NETADAPTER_PROPERTY_SET adapter=""$AdapterName"" name=""$DisplayName"" value=""$DisplayValue"""
    } catch {
        Write-StayAwakeLog "NETADAPTER_PROPERTY_FAILED adapter=""$AdapterName"" name=""$DisplayName"" value=""$DisplayValue"" error=""$($_.Exception.Message)"""
    }
}

function Set-RccNetworkAdapterWakePowerManagement {
    param([Parameter(Mandatory=$true)]$Adapter)

    if (Get-Command Set-NetAdapterPowerManagement -ErrorAction SilentlyContinue) {
        try {
            Get-NetAdapterPowerManagement -Name $Adapter.Name -ErrorAction Stop |
                Set-NetAdapterPowerManagement -WakeOnMagicPacket Enabled -WakeOnPattern Enabled -ArpOffload Enabled -NSOffload Enabled -ErrorAction Stop
            Write-StayAwakeLog "NETADAPTER_POWER_SET adapter=""$($Adapter.Name)"" wakeMagic=Enabled wakePattern=Enabled arp=Enabled ns=Enabled"
        } catch {
            Write-StayAwakeLog "NETADAPTER_POWER_PARTIAL_FAILED adapter=""$($Adapter.Name)"" error=""$($_.Exception.Message)"""
            try {
                Get-NetAdapterPowerManagement -Name $Adapter.Name -ErrorAction Stop |
                    Set-NetAdapterPowerManagement -WakeOnMagicPacket Enabled -WakeOnPattern Enabled -ErrorAction Stop
                Write-StayAwakeLog "NETADAPTER_POWER_SET adapter=""$($Adapter.Name)"" wakeMagic=Enabled wakePattern=Enabled"
            } catch {
                Write-StayAwakeLog "NETADAPTER_POWER_FAILED adapter=""$($Adapter.Name)"" error=""$($_.Exception.Message)"""
            }
        }
    } else {
        Write-StayAwakeLog "NETADAPTER_POWER_CMDLET_UNAVAILABLE adapter=""$($Adapter.Name)"""
    }

    try {
        $classPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
        $classKey = Get-ChildItem -LiteralPath $classPath -ErrorAction Stop | Where-Object {
            $props = Get-ItemProperty -LiteralPath $_.PsPath -ErrorAction SilentlyContinue
            $props.NetCfgInstanceId -eq $Adapter.InterfaceGuid.Guid -or $props.DriverDesc -eq $Adapter.InterfaceDescription
        } | Select-Object -First 1
        if ($classKey) {
            $before = (Get-ItemProperty -LiteralPath $classKey.PsPath -ErrorAction SilentlyContinue).PnPCapabilities
            New-ItemProperty -LiteralPath $classKey.PsPath -Name 'PnPCapabilities' -PropertyType DWord -Value 0 -Force -ErrorAction Stop | Out-Null
            Write-StayAwakeLog "NETADAPTER_PNPCAPABILITIES_SET adapter=""$($Adapter.Name)"" key=""$($classKey.PSChildName)"" before=$before value=0"
            if ($before -ne $null -and [int]$before -ne 0) {
                try {
                    Disable-NetAdapter -Name $Adapter.Name -Confirm:$false -ErrorAction Stop
                    Start-Sleep -Seconds 2
                    Enable-NetAdapter -Name $Adapter.Name -Confirm:$false -ErrorAction Stop
                    Write-StayAwakeLog "NETADAPTER_RESTARTED_FOR_PNPCAPABILITIES adapter=""$($Adapter.Name)"""
                } catch {
                    Write-StayAwakeLog "NETADAPTER_RESTART_FOR_PNPCAPABILITIES_FAILED adapter=""$($Adapter.Name)"" error=""$($_.Exception.Message)"""
                }
            }
        } else {
            Write-StayAwakeLog "NETADAPTER_PNPCAPABILITIES_KEY_NOT_FOUND adapter=""$($Adapter.Name)"" guid=""$($Adapter.InterfaceGuid)"""
        }
    } catch {
        Write-StayAwakeLog "NETADAPTER_PNPCAPABILITIES_FAILED adapter=""$($Adapter.Name)"" error=""$($_.Exception.Message)"""
    }

    try {
        $idx = $Adapter.ifIndex
        if ($idx) {
            $netshOutput = & (Join-Path $env:SystemRoot 'System32\netsh.exe') interface ipv4 set interface $idx forcearpndwolpattern=enabled 2>&1
            Write-StayAwakeLog "NETSH_ARP_NS_WOL_SET adapter=""$($Adapter.Name)"" ifIndex=$idx exit=$LASTEXITCODE output=""$((($netshOutput | Out-String) -replace '\r?\n',' | ').Trim())"""
        }
    } catch {
        Write-StayAwakeLog "NETSH_ARP_NS_WOL_FAILED adapter=""$($Adapter.Name)"" error=""$($_.Exception.Message)"""
    }
}

function Enable-RccWakeOnLan {
    $adapters = @()
    if (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue) {
        try {
            $adapters = @(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object {
                $_.Status -ne 'Not Present' -and
                ($_.InterfaceDescription -match 'Realtek|Ethernet|GbE|2\.5GbE' -or $_.Name -match 'Ethernet')
            })
        } catch {
            Write-StayAwakeLog "NETADAPTER_ENUM_FAILED error=""$($_.Exception.Message)"""
        }
    }

    foreach ($adapter in $adapters) {
        Set-RccNetworkAdapterWakePowerManagement -Adapter $adapter
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'Wake on Magic Packet' -DisplayValue 'Enabled'
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'Wake on magic packet when system is in the S0ix power state' -DisplayValue 'Enabled'
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'Wake on pattern match' -DisplayValue 'Enabled'
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'Shutdown Wake-On-Lan' -DisplayValue 'Enabled'
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'WOL & Shutdown Link Speed' -DisplayValue '10 Mbps First'
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'Energy-Efficient Ethernet' -DisplayValue 'Disabled'
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'Green Ethernet' -DisplayValue 'Disabled'
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'Advanced EEE' -DisplayValue 'Disabled'
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'Power Saving Mode' -DisplayValue 'Disabled'
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'Gigabit Lite' -DisplayValue 'Disabled'

        if ($adapter.InterfaceDescription) {
            Invoke-PowerCfg @('/deviceenablewake', $adapter.InterfaceDescription) | Out-Null
        } elseif ($adapter.Name) {
            Invoke-PowerCfg @('/deviceenablewake', $adapter.Name) | Out-Null
        }
    }

    if ($adapters.Count -eq 0) {
        Invoke-PowerCfg @('/deviceenablewake','Realtek PCIe 2.5GbE Family Controller') | Out-Null
        Write-StayAwakeLog 'WAKE_ADAPTER_FALLBACK_USED device="Realtek PCIe 2.5GbE Family Controller"'
    }
}

function Enable-RccWakeablePowerPolicy {
    $scheme = Get-RccWakeablePowerScheme
    $subSleep = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
    $allowStandby = 'abfc2519-3608-4c2a-94ea-171b0ed546ab'
    $wakeTimers = 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d'
    $remoteFileSleep = 'd4c1d4c8-d5cc-43d3-b83e-fc51215cb04d'
    $unattendedSleepTimeout = '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0'

    foreach ($setting in @($allowStandby, $wakeTimers, $remoteFileSleep)) {
        Invoke-PowerCfg @('/setacvalueindex',$scheme,$subSleep,$setting,'1') | Out-Null
        Invoke-PowerCfg @('/setdcvalueindex',$scheme,$subSleep,$setting,'1') | Out-Null
    }
    foreach ($value in @('0')) {
        Invoke-PowerCfg @('/setacvalueindex',$scheme,$subSleep,$unattendedSleepTimeout,$value) | Out-Null
        Invoke-PowerCfg @('/setdcvalueindex',$scheme,$subSleep,$unattendedSleepTimeout,$value) | Out-Null
    }
    Invoke-PowerCfg @('/setactive',$scheme) | Out-Null
    return $scheme
}

Invoke-PowerCfg @('/hibernate','on') | Out-Null
Invoke-PowerCfg @('/hibernate','/type','full') | Out-Null
$wakeableScheme = Enable-RccWakeablePowerPolicy
Invoke-PowerCfg @('/change','standby-timeout-ac','0') | Out-Null
Invoke-PowerCfg @('/change','standby-timeout-dc','0') | Out-Null
Invoke-PowerCfg @('/change','hibernate-timeout-ac','0') | Out-Null
Invoke-PowerCfg @('/change','hibernate-timeout-dc','0') | Out-Null
Invoke-PowerCfg @('/change','monitor-timeout-ac','0') | Out-Null
Invoke-PowerCfg @('/change','monitor-timeout-dc','0') | Out-Null
Enable-RccWakeOnLan

Invoke-PowerCfg @('/hibernate','on') | Out-Null
Invoke-PowerCfg @('/hibernate','/type','full') | Out-Null
Invoke-PowerCfg @('/change','hibernate-timeout-ac','0') | Out-Null
Invoke-PowerCfg @('/change','hibernate-timeout-dc','0') | Out-Null
Invoke-PowerCfg @('/setactive',$wakeableScheme) | Out-Null

$available = (& $powercfg /a | Out-String) -replace '\r?\n', ' | '
$wakeArmed = (& $powercfg /devicequery wake_armed | Out-String) -replace '\r?\n', ' | '
$wakeProps = ''
if (Get-Command Get-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue) {
    $wakeProps = (Get-NetAdapterAdvancedProperty -Name '*' -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -match 'Wake|WOL|Energy|Green|Shutdown|Magic|Pattern' } |
        Select-Object Name,DisplayName,DisplayValue |
        Format-Table -AutoSize | Out-String) -replace '\r?\n', ' | '
}
Write-StayAwakeLog "STAY_AWAKE_APPLIED scheme=$wakeableScheme standbyTimeout=0 hibernateTimeout=0 monitorTimeout=0 hibernate=full wolProperties=enabled staleMarkers=removed powercfgA=""$available"" wakeArmed=""$wakeArmed"" wakeProps=""$wakeProps"""
