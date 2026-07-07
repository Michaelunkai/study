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
                @{ DisplayName = 'WOL & Shutdown Link Speed'; DisplayValue = '10 Mbps First' },
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
        }
    }
}

Get-CimInstance Win32_Process |
    Where-Object { $_.CommandLine -match 'RemoteCommandCenter\\scripts\\(Start-RemoteCommandCenterAgent|Start-RemoteCommandCenterHttpReceiver|Start-RemoteCommandCenterTray|Start-RemoteCommandCenterPowerGuard|Set-RemoteCommandCenterStayAwake)\.ps1' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

foreach ($name in 'RemoteCommandCenterAgentStartup','RemoteCommandCenterAgentLogon','RemoteCommandCenterAgentKick','RemoteCommandCenterHttpReceiver','RemoteCommandCenterTrayLogon','RemoteCommandCenterPowerGuardLogon','RemoteCommandCenterPowerGuardStartup','RemoteCommandCenterStayAwakeStartup','RemoteCommandCenterStayAwakeLogon','RemoteCommandCenterStayAwakeResume','RemoteCommandCenterStayAwakePeriodic') {
    $deleteOutput = & "$env:SystemRoot\System32\cmd.exe" /d /c "`"$schtasks`" /Delete /F /TN `"$name`" 2>&1"
    if ($LASTEXITCODE -ne 0 -and ($deleteOutput -join "`n") -notmatch 'cannot find|does not exist|file specified') {
        throw "Failed to delete scheduled task ${name}: $($deleteOutput -join ' ')"
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
Register-RccTask -Name 'RemoteCommandCenterPowerGuardLogon' -Arguments "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$powerGuard`" -ConfigPath `"$config`" -IntervalSeconds 5" -Trigger (New-ScheduledTaskTrigger -AtLogOn)
& $schtasks /Create /F /TN 'RemoteCommandCenterPowerGuardStartup' /SC ONSTART /DELAY 0000:25 /TR "`"$powerGuardCmd`"" /RU SYSTEM /RL HIGHEST | Out-Null
& $schtasks /Create /F /TN 'RemoteCommandCenterStayAwakeLogon' /SC ONLOGON /TR "`"$stayAwakeCmd`"" /RU SYSTEM /RL HIGHEST | Out-Null
& $schtasks /Create /F /TN 'RemoteCommandCenterStayAwakeStartup' /SC ONSTART /DELAY 0000:20 /TR "`"$stayAwakeCmd`"" /RU SYSTEM /RL HIGHEST | Out-Null
& $schtasks /Create /F /TN 'RemoteCommandCenterStayAwakePeriodic' /SC MINUTE /MO 1 /TR "`"$stayAwakeCmd`"" /RU SYSTEM /RL HIGHEST | Out-Null
Enable-RccPowerWake
& $psExe -NoProfile -ExecutionPolicy Bypass -File $stayAwake -ConfigPath $config | Out-Null

& $schtasks /Create /F /TN 'RemoteCommandCenterStayAwakeResume' /SC ONEVENT /EC System /MO "*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]" /TR "`"$stayAwakeCmd`"" /RU SYSTEM /RL HIGHEST | Out-Null
Set-RccTaskAlwaysAllowed -Name 'RemoteCommandCenterStayAwakeStartup'
Set-RccTaskAlwaysAllowed -Name 'RemoteCommandCenterStayAwakeLogon'
Set-RccTaskAlwaysAllowed -Name 'RemoteCommandCenterStayAwakeResume'
Set-RccTaskAlwaysAllowed -Name 'RemoteCommandCenterStayAwakePeriodic'
Set-RccTaskAlwaysAllowed -Name 'RemoteCommandCenterPowerGuardLogon'
Set-RccTaskAlwaysAllowed -Name 'RemoteCommandCenterPowerGuardStartup'

& $netsh advfirewall firewall delete rule name='RemoteCommandCenter Local Receiver' | Out-Null
& $netsh advfirewall firewall add rule name='RemoteCommandCenter Local Receiver' dir=in action=allow protocol=TCP localport=8777 profile=any | Out-Null
& $schtasks /Run /TN 'RemoteCommandCenterTrayLogon' | Out-Null
Write-Output 'Installed and started RemoteCommandCenter tray task.'
