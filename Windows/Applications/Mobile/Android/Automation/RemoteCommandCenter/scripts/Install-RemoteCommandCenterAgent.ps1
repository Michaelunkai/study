param(
    [string]$InstallDir = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -eq 'Core') {
    $ps5 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $proc = Start-Process -FilePath $ps5 -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath,'-InstallDir',$InstallDir) -Wait -PassThru
    exit $proc.ExitCode
}

$runtime = Join-Path $InstallDir 'runtime'
$logDir = Join-Path $runtime 'logs'
New-Item -ItemType Directory -Force -Path $runtime, $logDir, (Join-Path $runtime 'local-queue') | Out-Null
$psExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$tray = Join-Path $PSScriptRoot 'Start-RemoteCommandCenterTray.ps1'
$trayExe = Join-Path $InstallDir 'dist\RemoteCommandCenterTray.exe'
$stayAwake = Join-Path $PSScriptRoot 'Set-RemoteCommandCenterStayAwake.ps1'
$powerGuard = Join-Path $PSScriptRoot 'Start-RemoteCommandCenterPowerGuard.ps1'
$wakeSettings = Join-Path $PSScriptRoot 'Ensure-RemoteCommandCenterWakeSettings.ps1'
$moonlightGuard = Join-Path $PSScriptRoot 'Start-RemoteCommandCenterMoonlightGuard.ps1'
$stayAwakeCmd = Join-Path $runtime 'run-stay-awake.cmd'
$powerGuardCmd = Join-Path $runtime 'run-power-guard.cmd'
$config = Join-Path $PSScriptRoot 'rcc-config.json'
$schtasks = Join-Path $env:SystemRoot 'System32\schtasks.exe'
$netsh = Join-Path $env:SystemRoot 'System32\netsh.exe'
$installLog = Join-Path $logDir 'install.log'
Set-Content -LiteralPath $stayAwakeCmd -Encoding ASCII -Value "@echo off`r`n`"$psExe`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$stayAwake`" -ConfigPath `"$config`"`r`n"
Set-Content -LiteralPath $powerGuardCmd -Encoding ASCII -Value "@echo off`r`n`"$psExe`" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$powerGuard`" -ConfigPath `"$config`" -IntervalSeconds 5`r`n"

function Write-InstallLog {
    param([string]$Message)
    Add-Content -LiteralPath $installLog -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message)
}

function Enable-RccPowerWake {
    $powercfg = Join-Path $env:SystemRoot 'System32\powercfg.exe'
    try {
        & $powercfg /hibernate on | Out-Null
        & $powercfg /hibernate /type full | Out-Null
        $state = (& $powercfg /a | Out-String)
        if (($state -split 'The following sleep states are not available on this system:')[0] -match 'Hibernate') {
            Write-InstallLog 'HIBERNATE_FULL_ENABLED verified=True'
        } else {
            Write-InstallLog "HIBERNATE_FULL_ENABLED verified=False powercfgA=$(($state -replace '\r?\n', ' | '))"
        }
    } catch {
        Write-InstallLog "HIBERNATE_FULL_FAILED error=$($_.Exception.Message)"
    }
    foreach ($device in @('Realtek PCIe 2.5GbE Family Controller')) {
        try {
            & $powercfg /deviceenablewake $device | Out-Null
            Write-InstallLog "WAKE_DEVICE_ENABLED device=`"$device`""
        } catch {
            Write-InstallLog "WAKE_DEVICE_ENABLE_FAILED device=`"$device`" error=$($_.Exception.Message)"
        }
    }
    if (Get-Command Set-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue) {
        $adapterNames = @('Ethernet')
        foreach ($adapterName in $adapterNames) {
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
                    Set-NetAdapterAdvancedProperty -Name $adapterName -DisplayName $setting.DisplayName -DisplayValue $setting.DisplayValue -NoRestart -ErrorAction Stop
                    Write-InstallLog "WAKE_ADAPTER_PROPERTY_SET adapter=`"$adapterName`" name=`"$($setting.DisplayName)`" value=`"$($setting.DisplayValue)`""
                } catch {
                    Write-InstallLog "WAKE_ADAPTER_PROPERTY_SKIPPED adapter=`"$adapterName`" name=`"$($setting.DisplayName)`" error=$($_.Exception.Message)"
                }
            }
            try {
                Set-NetAdapterAdvancedProperty -Name $adapterName -RegistryKeyword 'WolShutdownLinkSpeed' -RegistryValue 2 -NoRestart -ErrorAction Stop
                Write-InstallLog "WAKE_ADAPTER_PROPERTY_SET adapter=`"$adapterName`" keyword=`"WolShutdownLinkSpeed`" value=`"2`""
            } catch {
                Write-InstallLog "WAKE_ADAPTER_PROPERTY_SKIPPED adapter=`"$adapterName`" keyword=`"WolShutdownLinkSpeed`" error=$($_.Exception.Message)"
            }
            try {
                $adapter = Get-NetAdapter -Name $adapterName -ErrorAction Stop
                $classPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
                $classKey = Get-ChildItem -LiteralPath $classPath -ErrorAction Stop | Where-Object {
                    $props = Get-ItemProperty -LiteralPath $_.PsPath -ErrorAction SilentlyContinue
                    $props.NetCfgInstanceId -eq $adapter.InterfaceGuid.Guid -or $props.DriverDesc -eq $adapter.InterfaceDescription
                } | Select-Object -First 1
                if ($classKey) {
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
                        Write-InstallLog "WAKE_ADAPTER_REGISTRY_SET adapter=`"$adapterName`" key=`"$($classKey.PSChildName)`" name=`"$($registrySetting.Name)`" before=`"$settingBefore`" value=`"$($registrySetting.Value)`""
                    }
                } else {
                    Write-InstallLog "WAKE_ADAPTER_REGISTRY_KEY_NOT_FOUND adapter=`"$adapterName`""
                }
            } catch {
                Write-InstallLog "WAKE_ADAPTER_REGISTRY_FAILED adapter=`"$adapterName`" error=$($_.Exception.Message)"
            }
        }
    }
    try {
        $schemeText = (& $powercfg /getactivescheme | Out-String)
        $schemeMatch = [regex]::Match($schemeText, '([0-9a-fA-F-]{36})')
        if ($schemeMatch.Success) {
            $scheme = $schemeMatch.Groups[1].Value
            $subSleep = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
            foreach ($setting in @(
                '29f6c1db-86da-48c5-9fdb-f2b67b1f44da',
                '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0'
            )) {
                & $powercfg /setacvalueindex $scheme $subSleep $setting 86400 | Out-Null
                Write-InstallLog "POWER_POLICY_SET setting=$setting ac value=86400 reason=keep-s3-available-and-prevent-immediate-resleep exit=$LASTEXITCODE"
                & $powercfg /setdcvalueindex $scheme $subSleep $setting 86400 | Out-Null
                Write-InstallLog "POWER_POLICY_SET setting=$setting dc value=86400 reason=keep-s3-available-and-prevent-immediate-resleep exit=$LASTEXITCODE"
            }
            $subPciExpress = '501a4d13-42af-4429-9fd1-a8218c268e20'
            $linkStatePowerManagement = 'ee12f906-d277-404b-b6da-e5fa1a576df5'
            & $powercfg /setacvalueindex $scheme $subPciExpress $linkStatePowerManagement 0 | Out-Null
            Write-InstallLog "POWER_POLICY_SET setting=$linkStatePowerManagement ac value=0 reason=disable-pcie-link-state-power-management-for-wol exit=$LASTEXITCODE"
            & $powercfg /setdcvalueindex $scheme $subPciExpress $linkStatePowerManagement 0 | Out-Null
            Write-InstallLog "POWER_POLICY_SET setting=$linkStatePowerManagement dc value=0 reason=disable-pcie-link-state-power-management-for-wol exit=$LASTEXITCODE"
            & $powercfg /setactive $scheme | Out-Null
        }
    } catch {
        Write-InstallLog "POWER_POLICY_STANDBY_TIMEOUT_FAILED error=$($_.Exception.Message)"
    }
}

Get-CimInstance Win32_Process |
    Where-Object { $_.CommandLine -match 'RemoteCommandCenter\\scripts\\(Start-RemoteCommandCenterAgent|Start-RemoteCommandCenterHttpReceiver|Start-RemoteCommandCenterTray|Start-RemoteCommandCenterPowerGuard|Start-RemoteCommandCenterMoonlightGuard|Start-RemoteCommandCenterTvBridge|Set-RemoteCommandCenterStayAwake)\.ps1' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
Get-CimInstance Win32_Process |
    Where-Object { $_.ExecutablePath -ieq $trayExe } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

# Task Scheduler can retain the old interactive task instance briefly after its tray
# process exits. Wait for both layers so the replacement task starts deterministically.
$trayStopDeadline = (Get-Date).AddSeconds(15)
do {
    $trayStillRunning = @(Get-CimInstance Win32_Process | Where-Object { $_.ExecutablePath -ieq $trayExe }).Count -gt 0
    $taskStillRunning = $false
    try {
        $taskStillRunning = (Get-ScheduledTask -TaskName 'RemoteCommandCenterTrayLogon' -ErrorAction Stop).State -eq 'Running'
    } catch {}
    if (-not $trayStillRunning -and -not $taskStillRunning) { break }
    Start-Sleep -Milliseconds 500
} while ((Get-Date) -lt $trayStopDeadline)

if ($trayStillRunning -or $taskStillRunning) {
    throw 'RemoteCommandCenter tray task did not stop before its one-icon restart.'
}

foreach ($name in 'RemoteCommandCenterAgentStartup','RemoteCommandCenterAgentLogon','RemoteCommandCenterAgentKick','RemoteCommandCenterHttpReceiver','RemoteCommandCenterTrayLogon','RemoteCommandCenterPowerGuardLogon','RemoteCommandCenterPowerGuardStartup','RemoteCommandCenterMoonlightGuardLogon','RemoteCommandCenterStayAwakeStartup','RemoteCommandCenterStayAwakeLogon','RemoteCommandCenterStayAwakeResume','RemoteCommandCenterStayAwakePeriodic') {
    $deleteOutput = & "$env:SystemRoot\System32\cmd.exe" /d /c "`"$schtasks`" /Delete /F /TN `"$name`" 2>&1"
    if ($LASTEXITCODE -ne 0 -and ($deleteOutput -join "`n") -notmatch 'cannot find|does not exist|file specified') {
        throw "Failed to delete scheduled task ${name}: $($deleteOutput -join ' ')"
    }
}

foreach ($legacyTaskName in @(
    '\MichStartupMaster\moonlight',
    'MoonlightSetupGuardian',
    'Moonlight Stream Health Watchdog Minute',
    'Moonlight Stream Realtime Protection',
    'Moonlight Stream Realtime Protection Minute',
    'Sunshine Moonlight Self Heal',
    'Samsung TV SDB Control At Logon',
    'Samsung TV SDB Control Self Heal'
)) {
    $deleteOutput = & "$env:SystemRoot\System32\cmd.exe" /d /c "`"$schtasks`" /Delete /F /TN `"$legacyTaskName`" 2>&1"
    if ($LASTEXITCODE -eq 0) {
        Write-InstallLog "LEGACY_MOONLIGHT_STARTUP_TASK_DELETED name=`"$legacyTaskName`""
    } elseif (($deleteOutput -join "`n") -notmatch 'cannot find|does not exist|file specified') {
        Write-InstallLog "LEGACY_MOONLIGHT_STARTUP_TASK_DELETE_FAILED name=`"$legacyTaskName`" output=`"$($deleteOutput -join ' ')`""
    }
}

function Register-RccTask {
    param([string]$Name,[string]$Arguments,[Microsoft.Management.Infrastructure.CimInstance[]]$Trigger,[switch]$System,[switch]$Parallel)
    $action = New-ScheduledTaskAction -Execute $psExe -Argument $Arguments
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances ($(if ($Parallel) { 'Parallel' } else { 'IgnoreNew' }))
    if ($System) {
        $principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
    } else {
        $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Highest
    }
    Register-ScheduledTask -TaskName $Name -Action $action -Trigger $Trigger -Principal $principal -Settings $settings -Force | Out-Null
}

function Set-RccTaskAlwaysAllowed {
    param([string]$Name)
    try {
        $task = Get-ScheduledTask -TaskName $Name -ErrorAction Stop
        $task.Settings.DisallowStartIfOnBatteries = $false
        $task.Settings.StopIfGoingOnBatteries = $false
        $task.Settings.ExecutionTimeLimit = 'PT0S'
        Set-ScheduledTask -InputObject $task | Out-Null
        Write-InstallLog "TASK_POWER_SETTINGS_SET name=$Name allowBattery=True stopOnBattery=False executionTimeLimit=0"
    } catch {
        Write-InstallLog "TASK_POWER_SETTINGS_FAILED name=$Name error=$($_.Exception.Message)"
    }
}

if (Test-Path -LiteralPath $trayExe) {
    $trayAction = New-ScheduledTaskAction -Execute $trayExe -Argument "-ConfigPath `"$config`""
    $traySettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero) -MultipleInstances IgnoreNew
    $trayPrincipal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -TaskName 'RemoteCommandCenterTrayLogon' -Action $trayAction -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Principal $trayPrincipal -Settings $traySettings -Force | Out-Null
    Write-InstallLog "TRAY_TASK_USES_EXE path=`"$trayExe`""
} else {
    Register-RccTask -Name 'RemoteCommandCenterTrayLogon' -Arguments "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tray`" -ConfigPath `"$config`"" -Trigger (New-ScheduledTaskTrigger -AtLogOn)
    Write-InstallLog "TRAY_TASK_USES_SCRIPT path=`"$tray`""
}
Write-InstallLog 'RCC_STARTUP_AUTHORITY_ONLY_TRAY_EXE childWorkers=agent,http,powerGuard,moonlightGuard,tvBridge'
Enable-RccPowerWake
& $psExe -NoProfile -ExecutionPolicy Bypass -File $wakeSettings -ConfigPath $config | ForEach-Object { Write-InstallLog "WAKE_SETTINGS $_" }
& $psExe -NoProfile -ExecutionPolicy Bypass -File $stayAwake -ConfigPath $config | Out-Null

Set-RccTaskAlwaysAllowed -Name 'RemoteCommandCenterTrayLogon'

& $netsh advfirewall firewall delete rule name='RemoteCommandCenter Local Receiver' | Out-Null
& $netsh advfirewall firewall delete rule name='RemoteCommandCenter Local Receiver 8777' | Out-Null
& $netsh advfirewall firewall add rule name='RemoteCommandCenter Local Receiver 8777' dir=in action=allow protocol=TCP localport=8777 profile=any | Out-Null
try {
    $urlAcl = (& $netsh http show urlacl url=http://+:8777/rcc/ 2>&1 | Out-String)
    if ($urlAcl -notmatch 'http://\+:8777/rcc/') {
        & $netsh http add urlacl url=http://+:8777/rcc/ user=Everyone listen=yes | Out-Null
        Write-InstallLog "URLACL_ADDED prefix=http://+:8777/rcc/ exit=$LASTEXITCODE"
    } else {
        Write-InstallLog 'URLACL_PRESENT prefix=http://+:8777/rcc/'
    }
} catch {
    Write-InstallLog "URLACL_SET_FAILED error=$($_.Exception.Message)"
}
try {
    Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'MoonlightSetupGuardian' -ErrorAction SilentlyContinue
    Get-CimInstance Win32_Process |
        Where-Object { $_.ExecutablePath -ieq 'F:\backup\windowsapps\installed\tv\tizen\moonlight-setup-guardian\bin\MoonlightSetupGuardian.exe' } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
    foreach ($legacyTaskName in @('\MichStartupMaster\moonlight','MoonlightSetupGuardian')) {
        & $schtasks /Delete /F /TN $legacyTaskName 2>$null | Out-Null
    }
    Write-InstallLog 'MOONLIGHT_STANDALONE_TRAY_DISABLED integratedInto=RemoteCommandCenterTray'
} catch {
    Write-InstallLog "MOONLIGHT_STANDALONE_TRAY_DISABLE_FAILED error=$($_.Exception.Message)"
}
& $schtasks /Run /TN 'RemoteCommandCenterTrayLogon' | Out-Null
Write-Output 'Installed and started RemoteCommandCenter tray task.'
