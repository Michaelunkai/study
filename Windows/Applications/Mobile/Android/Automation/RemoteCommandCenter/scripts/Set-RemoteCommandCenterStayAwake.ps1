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
    try {
        if ((Test-Path -LiteralPath $log) -and ((Get-Item -LiteralPath $log -ErrorAction Stop).Length -gt 5242880)) {
            $archive = Join-Path (Split-Path -Parent $log) ('stay-awake.{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
            Move-Item -LiteralPath $log -Destination $archive -Force -ErrorAction Stop
        }
        $line = "[{0}] {1}{2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message, [Environment]::NewLine
        [System.IO.File]::AppendAllText($log, $line, [System.Text.UTF8Encoding]::new($false))
    } catch {
        try {
            $fallback = Join-Path $env:TEMP 'RemoteCommandCenter-stay-awake-fallback.log'
            $line = "[{0}] LOG_WRITE_FAILED target=""{1}"" error=""{2}"" original=""{3}""{4}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $log, $_.Exception.Message, $Message, [Environment]::NewLine
            [System.IO.File]::AppendAllText($fallback, $line, [System.Text.UTF8Encoding]::new($false))
        } catch {}
    }
}

$stayAwakeMutexCreated = $false
$stayAwakeMutex = New-Object System.Threading.Mutex($true, 'Global\RemoteCommandCenterStayAwake', [ref]$stayAwakeMutexCreated)
if (-not $stayAwakeMutexCreated) {
    Write-StayAwakeLog 'STAY_AWAKE_ALREADY_RUNNING exit=True'
    exit 0
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

function Enable-RccFullHibernate {
    Invoke-PowerCfg @('/hibernate','on') | Out-Null
    $typeExit = Invoke-PowerCfg @('/hibernate','/type','full')
    if ($typeExit -ne 0) {
        Write-StayAwakeLog "HIBERNATE_FULL_RETRY reason=powercfg_type_full_exit_$typeExit delayMs=1200"
        Start-Sleep -Milliseconds 1200
        Invoke-PowerCfg @('/hibernate','on') | Out-Null
        $typeExit = Invoke-PowerCfg @('/hibernate','/type','full')
    }

    $available = (& $powercfg /a | Out-String)
    $hibernateAvailable = ($available -match '(?m)^\s*Hibernate\s*$')
    Write-StayAwakeLog "HIBERNATE_FULL_VERIFY available=$hibernateAvailable"
    if (-not $hibernateAvailable) {
        Write-StayAwakeLog "HIBERNATE_FULL_RETRY reason=verification_failed delayMs=1200"
        Start-Sleep -Milliseconds 1200
        Invoke-PowerCfg @('/hibernate','on') | Out-Null
        Invoke-PowerCfg @('/hibernate','/type','full') | Out-Null
        $available = (& $powercfg /a | Out-String)
        $hibernateAvailable = ($available -match '(?m)^\s*Hibernate\s*$')
        Write-StayAwakeLog "HIBERNATE_FULL_VERIFY available=$hibernateAvailable afterRetry=True"
    }
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
            foreach ($registrySetting in @(
                @{ Name = 'PowerDownPll'; Value = '0' },
                @{ Name = 'ReduceSpeedOnPowerDown'; Value = '0' },
                @{ Name = 'WolShutdownLinkSpeed'; Value = '2' },
                @{ Name = 'S5WakeOnLan'; Value = '1' },
                @{ Name = '*WakeOnMagicPacket'; Value = '1' },
                @{ Name = '*WakeOnPattern'; Value = '1' },
                @{ Name = '*ModernStandbyWoLMagicPacket'; Value = '1' },
                @{ Name = 'GigaLite'; Value = '0' }
            )) {
                $settingBefore = (Get-ItemProperty -LiteralPath $classKey.PsPath -Name $registrySetting.Name -ErrorAction SilentlyContinue).($registrySetting.Name)
                New-ItemProperty -LiteralPath $classKey.PsPath -Name $registrySetting.Name -PropertyType String -Value $registrySetting.Value -Force -ErrorAction Stop | Out-Null
                Write-StayAwakeLog "NETADAPTER_REGISTRY_SET adapter=""$($Adapter.Name)"" key=""$($classKey.PSChildName)"" name=""$($registrySetting.Name)"" before=""$settingBefore"" value=""$($registrySetting.Value)"""
            }
            if ($before -ne $null -and [int]$before -ne 0) {
                Write-StayAwakeLog "NETADAPTER_RESTART_DEFERRED adapter=""$($Adapter.Name)"" reason=""preserve active network session; setting applies at next boot/resume"""
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
        Set-RccAdapterProperty -AdapterName $adapter.Name -DisplayName 'WOL & Shutdown Link Speed' -DisplayValue 'Not Speed Down'
        try {
            Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword 'WolShutdownLinkSpeed' -RegistryValue 2 -NoRestart -ErrorAction Stop
            Write-StayAwakeLog "NETADAPTER_PROPERTY_SET adapter=""$($adapter.Name)"" keyword=""WolShutdownLinkSpeed"" value=""2"""
        } catch {
            Write-StayAwakeLog "NETADAPTER_PROPERTY_FAILED adapter=""$($adapter.Name)"" keyword=""WolShutdownLinkSpeed"" value=""2"" error=""$($_.Exception.Message)"""
        }
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
    $standbyIdle = '29f6c1db-86da-48c5-9fdb-f2b67b1f44da'
    $allowStandby = 'abfc2519-3608-4c2a-94ea-171b0ed546ab'
    $wakeTimers = 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d'
    $remoteFileSleep = 'd4c1d4c8-d5cc-43d3-b83e-fc51215cb04d'
    $unattendedSleepTimeout = '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0'
    $subPciExpress = '501a4d13-42af-4429-9fd1-a8218c268e20'
    $linkStatePowerManagement = 'ee12f906-d277-404b-b6da-e5fa1a576df5'

    foreach ($setting in @($allowStandby, $wakeTimers, $remoteFileSleep)) {
        Invoke-PowerCfg @('/setacvalueindex',$scheme,$subSleep,$setting,'1') | Out-Null
        Invoke-PowerCfg @('/setdcvalueindex',$scheme,$subSleep,$setting,'1') | Out-Null
    }
    Invoke-PowerCfg @('/setacvalueindex',$scheme,$subSleep,$standbyIdle,'86400') | Out-Null
    Invoke-PowerCfg @('/setdcvalueindex',$scheme,$subSleep,$standbyIdle,'86400') | Out-Null
    Invoke-PowerCfg @('/setacvalueindex',$scheme,$subSleep,$unattendedSleepTimeout,'86400') | Out-Null
    Invoke-PowerCfg @('/setdcvalueindex',$scheme,$subSleep,$unattendedSleepTimeout,'86400') | Out-Null
    Invoke-PowerCfg @('/setacvalueindex',$scheme,$subPciExpress,$linkStatePowerManagement,'0') | Out-Null
    Invoke-PowerCfg @('/setdcvalueindex',$scheme,$subPciExpress,$linkStatePowerManagement,'0') | Out-Null
    Invoke-PowerCfg @('/setactive',$scheme) | Out-Null
    return $scheme
}

Enable-RccFullHibernate
$wakeableScheme = Enable-RccWakeablePowerPolicy
# A zero standby timeout disables S3 on this Windows/firmware combination.
# Keep manual sleep available while making idle and unattended sleep practically unreachable.
Invoke-PowerCfg @('/setacvalueindex',$wakeableScheme,'238c9fa8-0aad-41ed-83f4-97be242c8f20','29f6c1db-86da-48c5-9fdb-f2b67b1f44da','86400') | Out-Null
Invoke-PowerCfg @('/setdcvalueindex',$wakeableScheme,'238c9fa8-0aad-41ed-83f4-97be242c8f20','29f6c1db-86da-48c5-9fdb-f2b67b1f44da','86400') | Out-Null
Invoke-PowerCfg @('/setacvalueindex',$wakeableScheme,'238c9fa8-0aad-41ed-83f4-97be242c8f20','7bc4a2f9-d8fc-4469-b07b-33eb785aaca0','86400') | Out-Null
Invoke-PowerCfg @('/setdcvalueindex',$wakeableScheme,'238c9fa8-0aad-41ed-83f4-97be242c8f20','7bc4a2f9-d8fc-4469-b07b-33eb785aaca0','86400') | Out-Null
Invoke-PowerCfg @('/setacvalueindex',$wakeableScheme,'501a4d13-42af-4429-9fd1-a8218c268e20','ee12f906-d277-404b-b6da-e5fa1a576df5','0') | Out-Null
Invoke-PowerCfg @('/setdcvalueindex',$wakeableScheme,'501a4d13-42af-4429-9fd1-a8218c268e20','ee12f906-d277-404b-b6da-e5fa1a576df5','0') | Out-Null
Invoke-PowerCfg @('/change','hibernate-timeout-ac','0') | Out-Null
Invoke-PowerCfg @('/change','hibernate-timeout-dc','0') | Out-Null
Invoke-PowerCfg @('/change','monitor-timeout-ac','0') | Out-Null
Invoke-PowerCfg @('/change','monitor-timeout-dc','0') | Out-Null
Enable-RccWakeOnLan

Enable-RccFullHibernate
try {
    New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Force -ErrorAction SilentlyContinue | Out-Null
    # Keep the hiberfile-backed Fast Startup path available while preserving the full hibernate and Wake-on-LAN setup above.
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' -Name 'HiberbootEnabled' -Type DWord -Value 1 -Force
    Write-StayAwakeLog 'FAST_STARTUP_ENABLED name=HiberbootEnabled value=1 reason=boot-readiness optimization; full hibernate and Wake-on-LAN setup retained'
} catch {
    Write-StayAwakeLog "FAST_STARTUP_DISABLE_FAILED error=""$($_.Exception.Message)"""
}
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
Write-StayAwakeLog "STAY_AWAKE_APPLIED scheme=$wakeableScheme standbyTimeoutSeconds=86400 unattendedSleepTimeoutSeconds=86400 hibernateTimeout=0 monitorTimeout=0 hibernate=full wolProperties=enabled staleMarkers=removed powercfgA=""$available"" wakeArmed=""$wakeArmed"" wakeProps=""$wakeProps"""
try { $stayAwakeMutex.ReleaseMutex() | Out-Null } catch {}
$stayAwakeMutex.Dispose()
