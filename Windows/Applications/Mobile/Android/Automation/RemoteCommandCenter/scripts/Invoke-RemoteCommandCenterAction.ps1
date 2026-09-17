param(
    [Parameter(Mandatory=$true)][string]$Action,
    [string]$Nonce = '',
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [switch]$ProofOnly
)

$ErrorActionPreference = 'Continue'
if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
} else {
    $scriptRoot = $PSScriptRoot
}
if ([string]::IsNullOrWhiteSpace($ConfigPath) -or $ConfigPath -eq '\rcc-config.json') {
    $ConfigPath = Join-Path $scriptRoot 'rcc-config.json'
}
. (Join-Path $scriptRoot 'RemoteCommandCenter.Protocol.ps1')
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$ps = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
New-Item -ItemType Directory -Force -Path $config.LogDir | Out-Null
$log = Join-Path $config.LogDir ("action-{0}-{1}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'), $PID)
$stateDir = [string]$config.StateDir
New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
$proofFlag = Join-Path $stateDir 'proof-only.flag'

function Write-ActionLog {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message
    Add-Content -LiteralPath $log -Encoding UTF8 -Value $line
    Write-Output $line
}

function Test-ProofOnly {
    return [bool]($ProofOnly -or (Test-Path -LiteralPath $proofFlag))
}

function Invoke-Executable {
    param([string]$FilePath, [string[]]$Arguments = @())
    Write-ActionLog "EXEC_READY file=`"$FilePath`" args=$($Arguments -join ' ')"
    if (Test-ProofOnly) {
        Write-ActionLog "PROOF_ONLY active; command was not executed."
        return
    }
    & $FilePath @Arguments
    Write-ActionLog "EXEC_EXIT code=$LASTEXITCODE"
}

function Start-ControlledSleep {
    $controlledSleep = Join-Path (Split-Path -Parent $scriptRoot) 'controlled-sleep\Start-ControlledSleep.ps1'
    $controlledSleepExe = Join-Path (Split-Path -Parent $scriptRoot) 'controlled-sleep\dist\RccControlledSleep.exe'
    if (Test-Path -LiteralPath $controlledSleepExe) {
        $controlledSleepArgs = @('--config', $ConfigPath)
        if (-not [string]::IsNullOrWhiteSpace($Nonce)) {
            $controlledSleepArgs += @('--nonce', $Nonce)
        }
        $controlledSleepArgs += '--actual-sleep'
        Write-ActionLog "CONTROLLED_SLEEP_EXE_READY file=`"$controlledSleepExe`" exists=True"
        if (Test-ProofOnly) {
            & $controlledSleepExe @($controlledSleepArgs + '--proof') | ForEach-Object {
                Write-ActionLog "CONTROLLED_SLEEP_EXE_PROOF $_"
            }
            return
        }
        Prepare-WakeableSuspend
        Start-Process -FilePath $controlledSleepExe -ArgumentList $controlledSleepArgs -WindowStyle Hidden | Out-Null
        Write-ActionLog 'CONTROLLED_SLEEP_EXE_STARTED mode=actual-windows-suspend api=powrprof.SetSuspendState hibernate=False forceCritical=True disableWakeEvent=False'
        return
    }
    Write-ActionLog "CONTROLLED_SLEEP_READY script=`"$controlledSleep`" exists=$(Test-Path -LiteralPath $controlledSleep)"
    if (Test-ProofOnly) {
        & $ps -NoProfile -Sta -ExecutionPolicy Bypass -File $controlledSleep -ConfigPath $ConfigPath -Nonce $Nonce -ProofOnly | ForEach-Object {
            Write-ActionLog "CONTROLLED_SLEEP_PROOF $_"
        }
        return
    }
    Start-Process -FilePath $ps -Verb RunAs -ArgumentList @(
        '-NoProfile',
        '-Sta',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        $controlledSleep,
        '-ConfigPath',
        $ConfigPath,
        '-Nonce',
        $Nonce
    ) -WindowStyle Hidden | Out-Null
    Write-ActionLog 'CONTROLLED_SLEEP_STARTED mode=fullscreen-black-overlay exit=space-or-double-click-or-android-wake-signal trueWindowsSleep=False'
}

function Stop-ControlledSleep {
    $signalPath = Join-Path $stateDir 'controlled-sleep-wake.signal'
    if (Test-ProofOnly) {
        Write-ActionLog "PROOF_ONLY active; controlled-sleep wake signal was not written. path=`"$signalPath`""
        return
    }
    Set-Content -LiteralPath $signalPath -Encoding ASCII -Value ([DateTimeOffset]::UtcNow.ToString('o'))
    Write-ActionLog "CONTROLLED_SLEEP_WAKE_SIGNAL_SET path=`"$signalPath`""
}

function Invoke-SleepNow {
    Write-ActionLog 'SLEEP_API_READY api=powrprof.SetSuspendState hibernate=False forceCritical=True disableWakeEvent=False'
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; sleep API was not called.'
        return
    }
    Add-Type -Namespace RccPower -Name NativePower -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("powrprof.dll", SetLastError=true)]
public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);
'@ -ErrorAction SilentlyContinue
    $ok = [RccPower.NativePower]::SetSuspendState($false, $true, $false)
    Write-ActionLog "SLEEP_API_EXIT ok=$ok lastError=$([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
}

function Get-RccWakeablePowerScheme {
    $powercfg = Join-Path $env:SystemRoot 'System32\powercfg.exe'
    $planName = 'RemoteCommandCenter_Wakeable'
    $list = (& $powercfg /list | Out-String)
    $existing = [regex]::Match($list, 'Power Scheme GUID:\s+([0-9a-fA-F-]{36})\s+\(' + [regex]::Escape($planName) + '\)')
    if ($existing.Success) {
        return $existing.Groups[1].Value
    }

    $createdText = (& $powercfg /duplicatescheme SCHEME_CURRENT | Out-String)
    $created = [regex]::Match($createdText, '([0-9a-fA-F-]{36})')
    if (-not $created.Success) {
        Write-ActionLog "POWER_POLICY_CREATE_FAILED output=""$($createdText -replace '\r?\n', ' | ')"""
        return 'SCHEME_CURRENT'
    }

    $guid = $created.Groups[1].Value
    & $powercfg /changename $guid $planName "RemoteCommandCenter wakeable sleep and Wake-on-LAN profile" | Out-Null
    Write-ActionLog "POWER_POLICY_CREATED guid=$guid name=$planName exit=$LASTEXITCODE"
    return $guid
}

function Enable-WakeablePowerPolicy {
    $powercfg = Join-Path $env:SystemRoot 'System32\powercfg.exe'
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
        & $powercfg /setacvalueindex $scheme $subSleep $setting 1 | Out-Null
        Write-ActionLog "POWER_POLICY_SET scheme=$scheme ac setting=$setting exit=$LASTEXITCODE"
        & $powercfg /setdcvalueindex $scheme $subSleep $setting 1 | Out-Null
        Write-ActionLog "POWER_POLICY_SET scheme=$scheme dc setting=$setting exit=$LASTEXITCODE"
    }
    foreach ($setting in @($standbyIdle, $unattendedSleepTimeout)) {
        & $powercfg /setacvalueindex $scheme $subSleep $setting 86400 | Out-Null
        Write-ActionLog "POWER_POLICY_SET scheme=$scheme ac setting=$setting value=86400 exit=$LASTEXITCODE"
        & $powercfg /setdcvalueindex $scheme $subSleep $setting 86400 | Out-Null
        Write-ActionLog "POWER_POLICY_SET scheme=$scheme dc setting=$setting value=86400 exit=$LASTEXITCODE"
    }
    & $powercfg /setacvalueindex $scheme $subPciExpress $linkStatePowerManagement 0 | Out-Null
    Write-ActionLog "POWER_POLICY_SET scheme=$scheme ac setting=$linkStatePowerManagement value=0 exit=$LASTEXITCODE"
    & $powercfg /setdcvalueindex $scheme $subPciExpress $linkStatePowerManagement 0 | Out-Null
    Write-ActionLog "POWER_POLICY_SET scheme=$scheme dc setting=$linkStatePowerManagement value=0 exit=$LASTEXITCODE"
    & $powercfg /hibernate on | Out-Null
    Write-ActionLog "HIBERNATE_ON exit=$LASTEXITCODE"
    & $powercfg /hibernate /type full | Out-Null
    Write-ActionLog "HIBERNATE_FULL exit=$LASTEXITCODE"
    & $powercfg /setactive $scheme | Out-Null
    Write-ActionLog "POWER_POLICY_ACTIVE scheme=$scheme exit=$LASTEXITCODE"
}

function Enable-WakeOnLanNow {
    $powercfg = Join-Path $env:SystemRoot 'System32\powercfg.exe'
    if (Get-Command Set-NetAdapterAdvancedProperty -ErrorAction SilentlyContinue) {
        foreach ($adapter in @(Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {
            $_.Status -ne 'Not Present' -and ($_.InterfaceDescription -match 'Realtek|Ethernet|GbE|2\.5GbE' -or $_.Name -match 'Ethernet')
        })) {
            if (Get-Command Set-NetAdapterPowerManagement -ErrorAction SilentlyContinue) {
                try {
                    Get-NetAdapterPowerManagement -Name $adapter.Name -ErrorAction Stop |
                        Set-NetAdapterPowerManagement -WakeOnMagicPacket Enabled -WakeOnPattern Enabled -ArpOffload Enabled -NSOffload Enabled -ErrorAction Stop
                    Write-ActionLog "NETADAPTER_POWER_SET adapter=""$($adapter.Name)"" wakeMagic=Enabled wakePattern=Enabled arp=Enabled ns=Enabled"
                } catch {
                    Write-ActionLog "NETADAPTER_POWER_PARTIAL_FAILED adapter=""$($adapter.Name)"" error=""$($_.Exception.Message)"""
                    try {
                        Get-NetAdapterPowerManagement -Name $adapter.Name -ErrorAction Stop |
                            Set-NetAdapterPowerManagement -WakeOnMagicPacket Enabled -WakeOnPattern Enabled -ErrorAction Stop
                        Write-ActionLog "NETADAPTER_POWER_SET adapter=""$($adapter.Name)"" wakeMagic=Enabled wakePattern=Enabled"
                    } catch {
                        Write-ActionLog "NETADAPTER_POWER_FAILED adapter=""$($adapter.Name)"" error=""$($_.Exception.Message)"""
                    }
                }
            }

            try {
                $classPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}'
                $classKey = Get-ChildItem -LiteralPath $classPath -ErrorAction Stop | Where-Object {
                    $props = Get-ItemProperty -LiteralPath $_.PsPath -ErrorAction SilentlyContinue
                    $props.NetCfgInstanceId -eq $adapter.InterfaceGuid.Guid -or $props.DriverDesc -eq $adapter.InterfaceDescription
                } | Select-Object -First 1
                if ($classKey) {
                    $before = (Get-ItemProperty -LiteralPath $classKey.PsPath -ErrorAction SilentlyContinue).PnPCapabilities
                    New-ItemProperty -LiteralPath $classKey.PsPath -Name 'PnPCapabilities' -PropertyType DWord -Value 0 -Force -ErrorAction Stop | Out-Null
                    Write-ActionLog "NETADAPTER_PNPCAPABILITIES_SET adapter=""$($adapter.Name)"" key=""$($classKey.PSChildName)"" before=$before value=0"
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
                        Write-ActionLog "NETADAPTER_REGISTRY_SET adapter=""$($adapter.Name)"" key=""$($classKey.PSChildName)"" name=""$($registrySetting.Name)"" before=""$settingBefore"" value=""$($registrySetting.Value)"""
                    }
                    if ($before -ne $null -and [int]$before -ne 0) {
                        try {
                            Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                            Start-Sleep -Seconds 2
                            Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
                            Write-ActionLog "NETADAPTER_RESTARTED_FOR_PNPCAPABILITIES adapter=""$($adapter.Name)"""
                        } catch {
                            Write-ActionLog "NETADAPTER_RESTART_FOR_PNPCAPABILITIES_FAILED adapter=""$($adapter.Name)"" error=""$($_.Exception.Message)"""
                        }
                    }
                } else {
                    Write-ActionLog "NETADAPTER_PNPCAPABILITIES_KEY_NOT_FOUND adapter=""$($adapter.Name)"" guid=""$($adapter.InterfaceGuid)"""
                }
            } catch {
                Write-ActionLog "NETADAPTER_PNPCAPABILITIES_FAILED adapter=""$($adapter.Name)"" error=""$($_.Exception.Message)"""
            }

            try {
                if ($adapter.ifIndex) {
                    $netshOutput = & (Join-Path $env:SystemRoot 'System32\netsh.exe') interface ipv4 set interface $adapter.ifIndex forcearpndwolpattern=enabled 2>&1
                    Write-ActionLog "NETSH_ARP_NS_WOL_SET adapter=""$($adapter.Name)"" ifIndex=$($adapter.ifIndex) exit=$LASTEXITCODE output=""$((($netshOutput | Out-String) -replace '\r?\n',' | ').Trim())"""
                }
            } catch {
                Write-ActionLog "NETSH_ARP_NS_WOL_FAILED adapter=""$($adapter.Name)"" error=""$($_.Exception.Message)"""
            }

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
                    Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $setting.DisplayName -DisplayValue $setting.DisplayValue -NoRestart -ErrorAction Stop
                    Write-ActionLog "WOL_PROPERTY_SET adapter=""$($adapter.Name)"" name=""$($setting.DisplayName)"" value=""$($setting.DisplayValue)"""
                } catch {
                    Write-ActionLog "WOL_PROPERTY_SKIPPED adapter=""$($adapter.Name)"" name=""$($setting.DisplayName)"" error=""$($_.Exception.Message)"""
                }
            }
            try {
                Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword 'WolShutdownLinkSpeed' -RegistryValue 2 -NoRestart -ErrorAction Stop
                Write-ActionLog "WOL_PROPERTY_SET adapter=""$($adapter.Name)"" keyword=""WolShutdownLinkSpeed"" value=""2"""
            } catch {
                Write-ActionLog "WOL_PROPERTY_SKIPPED adapter=""$($adapter.Name)"" keyword=""WolShutdownLinkSpeed"" error=""$($_.Exception.Message)"""
            }
            & $powercfg /deviceenablewake $adapter.InterfaceDescription | Out-Null
            Write-ActionLog "WAKE_DEVICE_ENABLE device=""$($adapter.InterfaceDescription)"" exit=$LASTEXITCODE"
        }
    }
}

function Prepare-WakeableSuspend {
    Enable-WakeablePowerPolicy
    Enable-WakeOnLanNow
    Enable-WakeablePowerPolicy
    $available = (& (Join-Path $env:SystemRoot 'System32\powercfg.exe') /a | Out-String) -replace '\r?\n', ' | '
    $armed = (& (Join-Path $env:SystemRoot 'System32\powercfg.exe') /devicequery wake_armed | Out-String) -replace '\r?\n', ' | '
    Write-ActionLog "WAKEABLE_SUSPEND_PREPARED powercfgA=""$available"" wakeArmed=""$armed"""
}

function Test-StandbyAvailable {
    $powerStateText = (& (Join-Path $env:SystemRoot 'System32\powercfg.exe') /a | Out-String)
    $availableBlock = ($powerStateText -split 'The following sleep states are not available on this system:')[0]
    return ($availableBlock -match 'Standby \(S[0-3]\)' -or $availableBlock -match 'Standby \(S0 Low Power Idle\)')
}

function Restart-ServiceByName {
    param([string[]]$Names)
    foreach ($name in $Names) {
        Write-ActionLog "SERVICE_RESTART_READY name=$name"
        if (-not (Test-ProofOnly)) {
            Restart-Service -Name $name -Force -ErrorAction SilentlyContinue
        }
    }
}

function Start-FirstExisting {
    param([string[]]$Paths, [string]$FallbackName)
    foreach ($path in $Paths) {
        $expanded = [Environment]::ExpandEnvironmentVariables($path)
        if (Test-Path -LiteralPath $expanded) {
            Write-ActionLog "START_READY file=`"$expanded`""
            if (-not (Test-ProofOnly)) { Start-Process -FilePath $expanded | Out-Null }
            return
        }
    }
    Write-ActionLog "START_FALLBACK_READY name=$FallbackName"
    if (-not (Test-ProofOnly)) { Start-Process -FilePath $FallbackName -ErrorAction SilentlyContinue | Out-Null }
}

function Start-ExactExecutable {
    param([string]$FilePath)
    Write-ActionLog "START_EXACT_READY file=`"$FilePath`" exists=$(Test-Path -LiteralPath $FilePath)"
    if (-not (Test-Path -LiteralPath $FilePath)) {
        Write-ActionLog "START_EXACT_MISSING file=`"$FilePath`""
        exit 3
    }
    if (-not (Test-ProofOnly)) {
        Start-Process -FilePath $FilePath | Out-Null
    }
}

function Invoke-UnfreezePc {
    $masterChief = $env:RCC_MASTERCHIEF_RESCUE_SCRIPT
    if ([string]::IsNullOrWhiteSpace($masterChief)) {
        $masterChief = Join-Path (Split-Path -Parent $PSScriptRoot) 'MasterChiefRescue\scripts\Invoke-MasterChiefRescue.ps1'
    }
    $masterChiefExists = (-not [string]::IsNullOrWhiteSpace($masterChief)) -and (Test-Path -LiteralPath $masterChief -PathType Leaf)
    Write-ActionLog "UNFREEZE_READY method=MasterChiefRescuePlusFastPulse script=`"$masterChief`" exists=$masterChiefExists"
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; unfreeze rescue was not executed.'
        return
    }
    if (-not $masterChiefExists) {
        Write-ActionLog 'UNFREEZE_SCRIPT_MISSING'
        exit 7
    }
    Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$masterChief,'-NoReboot','-Reason',"RemoteCommandCenter unfreeze nonce=$Nonce") -WindowStyle Hidden | Out-Null
    Write-ActionLog 'UNFREEZE_STARTED'
}

function Invoke-OpenSpeedyToggle {
    Invoke-AppWindowToggle -Name 'OpenSpeedy' -ProcessName 'OpenSpeedy' -ExePath 'F:\backup\windowsapps\installed\OpenSpeedy\OpenSpeedy.exe' -MarkerName 'openspeedy-visible.txt' -PreferTitle @('OpenSpeedy','Speedy') -RejectTitle @('QTrayIconMessageWindow','Default IME','MSCTFIME UI') -RejectClass @('QTrayIconMessageWindow','IME','MSCTF') -LaunchWaitMilliseconds 2200
}

function Invoke-WandToggle {
    $wandExe = Join-Path $env:LOCALAPPDATA 'Wand\Wand.exe'
    Invoke-AppWindowToggle -Name 'Wand' -ProcessName 'Wand' -ExePath $wandExe -MarkerName 'wand-visible.txt' -PreferTitle @('Wand') -RejectTitle @('QTrayIconMessageWindow') -RejectClass @('QTrayIconMessageWindow')
}

function Invoke-QBittorrentToggle {
    Invoke-AppWindowToggle -Name 'qBittorrent' -ProcessName 'qbittorrent' -ExePath 'C:\Program Files\qBittorrent\qbittorrent.exe' -MarkerName 'qbittorrent-visible.txt' -PreferTitle @('qBittorrent') -RejectTitle @('QTrayIconMessageWindow') -RejectClass @('QTrayIconMessageWindow')
    $fitGirlRoots = @(
        $env:RCC_FITGIRL_HELPER_ROOT,
        'F:\study\projects\SystemMonitor\PSProcLasso\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601',
        'F:\study\Software_Engineering\Mobile\Android\Automation\Codex\Launchers\michNvidiaApp\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601'
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
    $fitGirlProjectRoot = $fitGirlRoots | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'install.ps1') -PathType Leaf } | Select-Object -First 1
    if (-not $fitGirlProjectRoot) { $fitGirlProjectRoot = $fitGirlRoots | Select-Object -First 1 }
    $fitGirlAutoInstall = Join-Path $fitGirlProjectRoot 'dist\FitGirlAutoInstall.exe'
    $fitGirlInstallScript = Join-Path $fitGirlProjectRoot 'install.ps1'
    $ps5 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    Write-ActionLog "FITGIRL_AUTOINSTALL_READY exe=`"$fitGirlAutoInstall`" exists=$(Test-Path -LiteralPath $fitGirlAutoInstall) canonical=`"$fitGirlInstallScript`" canonicalExists=$(Test-Path -LiteralPath $fitGirlInstallScript)"
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; FitGirl canonical install/tray startup was not launched.'
        return
    }
    if (-not (Test-Path -LiteralPath $fitGirlInstallScript)) {
        Write-ActionLog 'FITGIRL_CANONICAL_INSTALL_NOT_FOUND'
        exit 7
    }
    $fitGirlStopMarker = Join-Path $fitGirlProjectRoot 'runtime\state\qbit-force-stop-requested.txt'
    if (Test-Path -LiteralPath $fitGirlStopMarker) {
        Remove-Item -LiteralPath $fitGirlStopMarker -Force -ErrorAction SilentlyContinue
        Write-ActionLog "FITGIRL_STALE_TRAY_STOP_MARKER_REMOVED marker=`"$fitGirlStopMarker`""
    }
    Start-Process -FilePath $ps5 -WorkingDirectory $fitGirlProjectRoot -ArgumentList @('-WindowStyle','Hidden','-NoProfile','-ExecutionPolicy','Bypass','-File',$fitGirlInstallScript) | Out-Null
    Write-ActionLog 'FITGIRL_CANONICAL_INSTALL_LAUNCHED args=-Install -RunOnceAfterInstall via install.ps1 default; tray/clicker/daemon startup requested'
}

function Invoke-AppWindowToggle {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$ProcessName,
        [Parameter(Mandatory=$true)][string]$ExePath,
        [Parameter(Mandatory=$true)][string]$MarkerName,
        [string[]]$PreferTitle = @(),
        [string[]]$RejectTitle = @(),
        [string[]]$RejectClass = @(),
        [int]$LaunchWaitMilliseconds = 1500
    )
    $marker = Join-Path $stateDir $MarkerName
    $workingDirectory = if (Test-Path -LiteralPath $ExePath) { Split-Path -Parent $ExePath } else { '' }
    Write-ActionLog "$($Name.ToUpperInvariant())_TOGGLE_READY exe=`"$ExePath`" exists=$(Test-Path -LiteralPath $ExePath) workingDirectory=`"$workingDirectory`" mode=show-topmost-or-minimize-to-tray"
    if (Test-ProofOnly) {
        Write-ActionLog "PROOF_ONLY active; $Name window was not toggled. Launch uses app working directory to avoid blank resource windows."
        return
    }
    Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public static class RccWindowOps {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr SetActiveWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder className, int count);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
'@ -ErrorAction SilentlyContinue
    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Sort-Object MainWindowHandle -Descending | Select-Object -First 1
    if (-not $proc -and (Test-Path -LiteralPath $ExePath)) {
        Start-Process -FilePath $ExePath -WorkingDirectory $workingDirectory | Out-Null
        Start-Sleep -Milliseconds $LaunchWaitMilliseconds
        $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Sort-Object MainWindowHandle -Descending | Select-Object -First 1
    }
    if (-not $proc) {
        Write-ActionLog "$($Name.ToUpperInvariant())_PROCESS_NOT_FOUND"
        exit 5
    }
    $processes = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
    $targetPids = @{}
    foreach ($p in $processes) { $targetPids[[uint32]$p.Id] = $true }
    $windows = New-Object System.Collections.ArrayList
    [RccWindowOps]::EnumWindows({
        param([IntPtr]$hWnd, [IntPtr]$lParam)
        $windowPid = [uint32]0
        [void][RccWindowOps]::GetWindowThreadProcessId($hWnd, [ref]$windowPid)
        if ($targetPids.ContainsKey($windowPid)) {
            $titleBuilder = New-Object System.Text.StringBuilder 512
            $classBuilder = New-Object System.Text.StringBuilder 256
            [void][RccWindowOps]::GetWindowText($hWnd, $titleBuilder, $titleBuilder.Capacity)
            [void][RccWindowOps]::GetClassName($hWnd, $classBuilder, $classBuilder.Capacity)
            $title = $titleBuilder.ToString()
            $className = $classBuilder.ToString()
            $reject = $false
            foreach ($bad in $RejectTitle) { if ($title -like "*$bad*") { $reject = $true } }
            foreach ($bad in $RejectClass) { if ($className -like "*$bad*") { $reject = $true } }
            if (-not $reject -and -not [string]::IsNullOrWhiteSpace($title)) {
                [void]$windows.Add([pscustomobject]@{ Handle = $hWnd; Pid = $windowPid; Title = $title; ClassName = $className; Visible = [RccWindowOps]::IsWindowVisible($hWnd) })
            }
        }
        return $true
    }, [IntPtr]::Zero) | Out-Null
    $selected = @($windows)
    foreach ($preferred in $PreferTitle) {
        $preferredMatches = @($windows | Where-Object { $_.Title -like "*$preferred*" })
        if ($preferredMatches.Count -gt 0) {
            $selected = $preferredMatches
            break
        }
    }
    if ($selected.Count -eq 0 -and (Test-Path -LiteralPath $ExePath)) {
        Write-ActionLog "$($Name.ToUpperInvariant())_REAL_WINDOW_REOPEN_REQUESTED processCount=$($processes.Count) reason=no-selectable-window"
        Start-Process -FilePath $ExePath -WorkingDirectory $workingDirectory | Out-Null
        Start-Sleep -Milliseconds $LaunchWaitMilliseconds
        $processes = @(Get-Process -Name $ProcessName -ErrorAction SilentlyContinue)
        $targetPids = @{}
        foreach ($p in $processes) { $targetPids[[uint32]$p.Id] = $true }
        $windows = New-Object System.Collections.ArrayList
        [RccWindowOps]::EnumWindows({
            param([IntPtr]$hWnd, [IntPtr]$lParam)
            $windowPid = [uint32]0
            [void][RccWindowOps]::GetWindowThreadProcessId($hWnd, [ref]$windowPid)
            if ($targetPids.ContainsKey($windowPid)) {
                $titleBuilder = New-Object System.Text.StringBuilder 512
                $classBuilder = New-Object System.Text.StringBuilder 256
                [void][RccWindowOps]::GetWindowText($hWnd, $titleBuilder, $titleBuilder.Capacity)
                [void][RccWindowOps]::GetClassName($hWnd, $classBuilder, $classBuilder.Capacity)
                $title = $titleBuilder.ToString()
                $className = $classBuilder.ToString()
                $reject = $false
                foreach ($bad in $RejectTitle) { if ($title -like "*$bad*") { $reject = $true } }
                foreach ($bad in $RejectClass) { if ($className -like "*$bad*") { $reject = $true } }
                if (-not $reject -and -not [string]::IsNullOrWhiteSpace($title)) {
                    [void]$windows.Add([pscustomobject]@{ Handle = $hWnd; Pid = $windowPid; Title = $title; ClassName = $className; Visible = [RccWindowOps]::IsWindowVisible($hWnd) })
                }
            }
            return $true
        }, [IntPtr]::Zero) | Out-Null
        $selected = @($windows)
        foreach ($preferred in $PreferTitle) {
            $preferredMatches = @($windows | Where-Object { $_.Title -like "*$preferred*" })
            if ($preferredMatches.Count -gt 0) {
                $selected = $preferredMatches
                break
            }
        }
    }
    if ($selected.Count -eq 0) {
        Write-ActionLog "$($Name.ToUpperInvariant())_REAL_WINDOW_NOT_FOUND processCount=$($processes.Count)"
        exit 6
    }
    $hwndTopMost = [IntPtr](-1)
    $swpNoMoveNoSizeShow = [uint32]0x0043
    if (Test-Path -LiteralPath $marker) {
        foreach ($w in $selected) { [void][RccWindowOps]::ShowWindow($w.Handle, 6) }
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
        Write-ActionLog "$($Name.ToUpperInvariant())_MINIMIZED_TO_TRAY_REQUESTED windows=$($selected.Count) titles=`"$((@($selected | Select-Object -ExpandProperty Title) -join '|'))`""
    } else {
        foreach ($w in $selected) {
            [void][RccWindowOps]::ShowWindow($w.Handle, 6)
            Start-Sleep -Milliseconds 120
            for ($i = 0; $i -lt 3; $i++) {
                [void][RccWindowOps]::ShowWindow($w.Handle, 9)
                [void][RccWindowOps]::SetWindowPos($w.Handle, $hwndTopMost, 0, 0, 0, 0, $swpNoMoveNoSizeShow)
                [void][RccWindowOps]::BringWindowToTop($w.Handle)
                [void][RccWindowOps]::SetActiveWindow($w.Handle)
                [void][RccWindowOps]::SetForegroundWindow($w.Handle)
                Start-Sleep -Milliseconds 120
            }
        }
        Set-Content -LiteralPath $marker -Value ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) -Encoding ASCII
        Write-ActionLog "$($Name.ToUpperInvariant())_SHOWN_TOPMOST windows=$($selected.Count) titles=`"$((@($selected | Select-Object -ExpandProperty Title) -join '|'))`""
    }
}

function Invoke-RestartExplorer {
    Write-ActionLog 'RESTART_EXPLORER_READY'
    if (-not (Test-ProofOnly)) {
        Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Process explorer.exe | Out-Null
    }
}

function Invoke-ExplorerRefreshGpu {
    Write-ActionLog 'EXPLORER_REFRESH_GPU_READY actions=restart_explorer,refresh_gpu'
    Invoke-RestartExplorer
    Invoke-RefreshGpuDriver
}

function Invoke-RebootToFirmware {
    Write-ActionLog "REBOOT_TO_BIOS_READY method=shutdown.exe args=/r /fw /f /t 0 uefiRequired=True"
    Invoke-Executable -FilePath $shutdown -Arguments @('/r','/fw','/f','/t','0','/c',"RemoteCommandCenter reboot to BIOS nonce=$Nonce")
}

function Invoke-NightModeUiToggle {
    Write-ActionLog "NIGHT_MODE_UI_TOGGLE_READY target=auto method=UIAutomationInvoke ms-settings:nightlight"
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; Night Light UI was not opened or clicked.'
        return
    }
    Start-Process -FilePath 'ms-settings:nightlight' -ErrorAction SilentlyContinue | Out-Null
    Start-Sleep -Milliseconds 900
    Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes
    $automation = [System.Windows.Automation.AutomationElement]::RootElement
    $deadline = (Get-Date).AddSeconds(8)
    $automationIds = @(
        'SystemSettings_Display_BlueLight_ManualToggleOff_Button',
        'SystemSettings_Display_BlueLight_ManualToggleOn_Button'
    )
    $wanted = @('Turn off now','Turn on now','Turn off','Turn on')
    do {
        foreach ($automationId in $automationIds) {
            $idCondition = New-Object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::AutomationIdProperty), $automationId
            $button = $automation.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $idCondition)
            if ($button) {
                $pattern = $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                $pattern.Invoke()
                Write-ActionLog "NIGHT_MODE_UI_CLICKED automationId=`"$automationId`" name=`"$($button.Current.Name)`""
                return
            }
        }
        foreach ($name in $wanted) {
            $condition = New-Object System.Windows.Automation.PropertyCondition ([System.Windows.Automation.AutomationElement]::NameProperty), $name
            $button = $automation.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
            if ($button) {
                $pattern = $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                $pattern.Invoke()
                Write-ActionLog "NIGHT_MODE_UI_CLICKED button=`"$name`""
                return
            }
        }
        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $deadline)
    Write-ActionLog 'NIGHT_MODE_UI_BUTTON_NOT_FOUND target=auto'
    exit 4
}

function Invoke-RefreshGpuDriver {
    Write-ActionLog 'REFRESH_GPU_READY hotkey=Win+Ctrl+Shift+B'
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; GPU refresh hotkey was not sent.'
        return
    }
    Add-Type -Namespace RccInput -Name Keyboard -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll")]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, System.UIntPtr dwExtraInfo);
'@ -ErrorAction SilentlyContinue
    $keyUp = [uint32]2
    $keys = @([byte]0x5B, [byte]0x11, [byte]0x10, [byte]0x42)
    foreach ($key in $keys) {
        [RccInput.Keyboard]::keybd_event($key, [byte]0, [uint32]0, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 25
    }
    foreach ($key in @($keys[3], $keys[2], $keys[1], $keys[0])) {
        [RccInput.Keyboard]::keybd_event($key, [byte]0, $keyUp, [UIntPtr]::Zero)
        Start-Sleep -Milliseconds 25
    }
    Write-ActionLog 'REFRESH_GPU_HOTKEY_SENT hotkey=Win+Ctrl+Shift+B'
}

function Get-MoonlightEncoderSessionCount {
    $candidates = @(
        'nvidia-smi.exe',
        (Join-Path $env:SystemRoot 'System32\nvidia-smi.exe'),
        'C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe'
    )
    foreach ($candidate in $candidates) {
        $resolved = $null
        if ($candidate -eq 'nvidia-smi.exe') {
            $command = Get-Command $candidate -ErrorAction SilentlyContinue
            if ($command) { $resolved = $command.Source }
        } elseif (Test-Path -LiteralPath $candidate) {
            $resolved = $candidate
        }
        if (-not $resolved) { continue }

        $output = & $resolved '--query-gpu=encoder.stats.sessionCount' '--format=csv,noheader,nounits' 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $output) { continue }
        $total = 0
        foreach ($line in @($output)) {
            $value = 0
            if ([int]::TryParse(([string]$line).Trim(), [ref]$value)) {
                $total += $value
            }
        }
        $null = Write-ActionLog "MOONLIGHT_ENCODER_SESSIONS count=$total source=`"$resolved`""
        return $total
    }
    $null = Write-ActionLog 'MOONLIGHT_ENCODER_SESSION_COUNT_UNAVAILABLE fallback=start'
    return 0
}

function Get-MoonlightScriptPair {
    $roots = @(
        'F:\backup\windowsapps\installed\tv\tizen\moonlight-setup-guardian\bin',
        'F:\backup\windowsapps\installed\tv\tizen\fresh-windows-moonlight-bootstrap\payload\MoonlightSetupGuardian\bin',
        'F:\backup\windowsapps\install\SamsungTvMoonlightRecovery\Recovery',
        'F:\backup\windowsapps\install\SamsungTvMoonlightRecovery'
    )
    foreach ($root in $roots) {
        $start = Join-Path $root 'Start-MoonlightTvAutoConnect.ps1'
        $stop = Join-Path $root 'Stop-MoonlightTvStream.ps1'
        if ((Test-Path -LiteralPath $start) -and (Test-Path -LiteralPath $stop)) {
            return [pscustomobject]@{
                Root = $root
                Start = $start
                Stop = $stop
            }
        }
    }
    $dynamicRoots = @()
    foreach ($searchRoot in @('F:\backup\windowsapps\installed\tv\tizen', 'F:\backup\windowsapps\install')) {
        if (Test-Path -LiteralPath $searchRoot) {
            $dynamicRoots += Get-ChildItem -LiteralPath $searchRoot -Recurse -Filter 'Start-MoonlightTvAutoConnect.ps1' -File -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 8 |
                ForEach-Object { $_.DirectoryName }
        }
    }
    foreach ($root in ($dynamicRoots | Select-Object -Unique)) {
        $start = Join-Path $root 'Start-MoonlightTvAutoConnect.ps1'
        $stop = Join-Path $root 'Stop-MoonlightTvStream.ps1'
        if ((Test-Path -LiteralPath $start) -and (Test-Path -LiteralPath $stop)) {
            return [pscustomobject]@{
                Root = $root
                Start = $start
                Stop = $stop
            }
        }
    }
    return [pscustomobject]@{
        Root = ($roots -join ';')
        Start = (Join-Path $roots[0] 'Start-MoonlightTvAutoConnect.ps1')
        Stop = (Join-Path $roots[0] 'Stop-MoonlightTvStream.ps1')
    }
}

function Invoke-MoonlightToggle {
    $mutex = [Threading.Mutex]::new($false, 'Global\RemoteCommandCenterMoonlightToggle')
    $lockTaken = $false
    try {
        try { $lockTaken = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $lockTaken = $true }
        if (-not $lockTaken) {
            Write-ActionLog 'MOONLIGHT_TOGGLE_ALREADY_RUNNING skipped=True'
            return
        }
    $scripts = Get-MoonlightScriptPair
    $startExists = Test-Path -LiteralPath $scripts.Start
    $stopExists = Test-Path -LiteralPath $scripts.Stop
    $sessions = Get-MoonlightEncoderSessionCount
    $mode = if ($sessions -gt 0) { 'stop' } else { 'start' }
    $target = if ($mode -eq 'stop') { $scripts.Stop } else { $scripts.Start }
    $focusGuardian = Join-Path $PSScriptRoot 'Start-RemoteCommandCenterMoonlightFocusGuardian.ps1'
    Write-ActionLog "MOONLIGHT_TOGGLE_READY mode=$mode sessions=$sessions root=`"$($scripts.Root)`" startExists=$startExists stopExists=$stopExists target=`"$target`""
    if (Test-ProofOnly) {
        $targetExists = Test-Path -LiteralPath $target -PathType Leaf
        Write-ActionLog "PROOF_ONLY active; Moonlight toggle was not launched. mode=$mode startExists=$startExists stopExists=$stopExists targetExists=$targetExists focusGuardian=`"$focusGuardian`" focusGuardianExists=$(Test-Path -LiteralPath $focusGuardian -PathType Leaf)"
        return
    }
    if (-not (Test-Path -LiteralPath $target)) {
        Write-ActionLog "MOONLIGHT_TOGGLE_SCRIPT_MISSING target=`"$target`""
        exit 5
    }
    if ($mode -eq 'stop' -and (Test-Path -LiteralPath $focusGuardian -PathType Leaf)) {
        & $ps -NoProfile -ExecutionPolicy Bypass -File $focusGuardian -ConfigPath $ConfigPath -Stop 2>&1 |
            ForEach-Object { Write-ActionLog "MOONLIGHT_FOCUS_GUARDIAN_STOP $_" }
    }
    Write-ActionLog "MOONLIGHT_TOGGLE_EXECUTING mode=$mode target=`"$target`""
    $output = & $ps -NoProfile -ExecutionPolicy Bypass -File $target 2>&1
    $exitCode = $LASTEXITCODE
    foreach ($line in @($output)) {
        Write-ActionLog "MOONLIGHT_TOGGLE_OUTPUT $line"
    }
    if ($exitCode -ne 0) {
        Write-ActionLog "MOONLIGHT_TOGGLE_FAILED mode=$mode exit=$exitCode target=`"$target`""
        exit $exitCode
    }
    if ($mode -eq 'start' -and (Test-Path -LiteralPath $focusGuardian -PathType Leaf)) {
        $sessionReady = $false
        for ($attempt = 1; $attempt -le 30; $attempt++) {
            if ((Get-MoonlightEncoderSessionCount) -gt 0) {
                $sessionReady = $true
                break
            }
            Start-Sleep -Milliseconds 250
        }
        if ($sessionReady) {
            Start-Process -FilePath $ps -ArgumentList @(
                '-NoProfile','-ExecutionPolicy','Bypass','-File',$focusGuardian,'-ConfigPath',$ConfigPath
            ) -WindowStyle Hidden | Out-Null
            Write-ActionLog "MOONLIGHT_FOCUS_GUARDIAN_STARTED path=`"$focusGuardian`""
        } else {
            Write-ActionLog 'MOONLIGHT_FOCUS_GUARDIAN_NOT_STARTED reason=encoder-session-not-observed'
        }
    }
    Write-ActionLog "MOONLIGHT_TOGGLE_COMPLETED mode=$mode exit=0 target=`"$target`""
    } finally {
        if ($lockTaken) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Invoke-MoonlightPrepare {
    $appsPath = 'C:\Program Files\Sunshine\config\apps.json'
    $verifyScript = 'F:\backup\windowsapps\install\SamsungTvMoonlightRecovery\Ensure-SunshineTizenStable1080p60.ps1'
    $protectScript = 'F:\backup\windowsapps\install\SamsungTvMoonlightRecovery\Protect-MoonlightStreamRealtime.ps1'
    $apps = Get-Content -LiteralPath $appsPath -Raw | ConvertFrom-Json
    $changed = $false
    foreach ($app in @($apps.apps)) {
        foreach ($prepCommand in @($app.'prep-cmd')) {
            if ($prepCommand.do -match 'Ensure-SunshineTizenStable1080p60\.ps1"$') {
                $prepCommand.do += ' -VerifyOnly'
                $changed = $true
            }
        }
    }
    if ($changed) {
        $utf8NoBom = New-Object Text.UTF8Encoding($false)
        [IO.File]::WriteAllText($appsPath, ($apps | ConvertTo-Json -Depth 100), $utf8NoBom)
    }
    Restart-Service -Name SunshineService -Force -ErrorAction Stop
    $service = Get-Service -Name SunshineService
    $service.WaitForStatus([ServiceProcess.ServiceControllerStatus]::Running, [TimeSpan]::FromSeconds(15))
    & $ps -NoProfile -ExecutionPolicy Bypass -File $verifyScript -VerifyOnly 2>&1 | ForEach-Object { Write-ActionLog "MOONLIGHT_PREP_VERIFY $_" }
    if ($LASTEXITCODE -ne 0) { throw "Moonlight verify hook exited $LASTEXITCODE" }
    & $ps -NoProfile -ExecutionPolicy Bypass -File $protectScript -Once 2>&1 | ForEach-Object { Write-ActionLog "MOONLIGHT_PREP_PROTECT $_" }
    if ($LASTEXITCODE -ne 0) { throw "Moonlight protect hook exited $LASTEXITCODE" }
    $invalid = @((Get-Content -LiteralPath $appsPath -Raw | ConvertFrom-Json).apps.'prep-cmd' | Where-Object { $_.do -match 'Ensure-SunshineTizenStable1080p60\.ps1"$' })
    if ($invalid.Count -gt 0) { throw 'Sunshine apps.json still contains a mutating Moonlight prep hook' }
    Write-ActionLog "MOONLIGHT_PREPARED changed=$changed service=$($service.Status) hooksExit=0"
}

function Get-TizenTubeDialState {
    try {
        $dial = Invoke-WebRequest -UseBasicParsing -Uri 'http://192.168.1.173:8085/dial/apps/YouTube' -TimeoutSec 3
        if ($dial.Content -match '<state>([^<]+)</state>') { return $Matches[1] }
    } catch {
        Write-ActionLog "YOUTUBE_TIZEN_DIAL_CHECK_FAILED error=`"$($_.Exception.Message)`"" | Out-Null
    }
    return $null
}

function Invoke-TizenTubeDialStart {
    param(
        [Parameter(Mandatory)]
        [string]$Reason
    )

    try {
        $response = Invoke-WebRequest -UseBasicParsing -Method POST -Uri 'http://192.168.1.173:8085/dial/apps/YouTube' `
            -Body 'source=remotecommandcenter&autolaunch=1' -ContentType 'text/plain' -TimeoutSec 4
        Write-ActionLog "YOUTUBE_TIZEN_DIAL_START_SENT reason=$Reason statusCode=$($response.StatusCode)"
        return $true
    } catch {
        Write-ActionLog "YOUTUBE_TIZEN_DIAL_START_FAILED reason=$Reason error=`"$($_.Exception.Message)`""
        return $false
    }
}

function Get-TizenBrewVisibleState {
    try {
        $status = Invoke-RestMethod -UseBasicParsing -Uri 'http://192.168.1.173:8001/api/v2/applications/xvvl3S1bvH.TizenBrewStandalone' -TimeoutSec 3
        return [bool]($status.running -and $status.visible)
    } catch {
        Write-ActionLog "YOUTUBE_TIZEN_BREW_CHECK_FAILED error=`"$($_.Exception.Message)`"" | Out-Null
        return $false
    }
}

function Test-SamsungTvControlReady {
    param(
        [Parameter(Mandatory)]
        [string]$TvIp
    )

    $client = $null
    try {
        $api = Invoke-WebRequest -UseBasicParsing -Uri "http://${TvIp}:8001/api/v2/" -TimeoutSec 2
        if ($api.StatusCode -ne 200) {
            return $false
        }

        $client = New-Object System.Net.Sockets.TcpClient
        $connect = $client.BeginConnect($TvIp, 8002, $null, $null)
        if (-not $connect.AsyncWaitHandle.WaitOne(750)) {
            return $false
        }
        $client.EndConnect($connect)
        return $true
    } catch {
        return $false
    } finally {
        if ($null -ne $client) {
            $client.Dispose()
        }
    }
}

function Wait-SamsungTvControlReady {
    param(
        [Parameter(Mandatory)]
        [string]$TvIp,
        [int]$TimeoutSeconds = 60
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $waitingLogged = $false
    do {
        if (Test-SamsungTvControlReady -TvIp $TvIp) {
            Write-ActionLog 'YOUTUBE_TIZEN_TV_CONTROL_READY restPort=8001 remotePort=8002'
            return
        }
        if (-not $waitingLogged) {
            Write-ActionLog "YOUTUBE_TIZEN_TV_CONTROL_WAITING timeoutSeconds=$TimeoutSeconds restPort=8001 remotePort=8002"
            $waitingLogged = $true
        }
        Start-Sleep -Milliseconds 300
    } while ((Get-Date) -lt $deadline)

    throw "Samsung TV control service did not become ready within $TimeoutSeconds seconds."
}

function Invoke-TizenTubeViaPairedController {
    $tvIp = '192.168.1.173'
    $tizenBrewAppId = 'xvvl3S1bvH.TizenBrewStandalone'
    $tvController = Join-Path $PSScriptRoot 'samsung-tv-control.js'
    $node = Get-SamsungTvNodePath
    if ([string]::IsNullOrWhiteSpace($node)) { throw 'Node.js was not found for Samsung TV control.' }
    if (-not (Test-Path -LiteralPath $tvController -PathType Leaf)) {
        throw "Paired Samsung TV controller is missing: $tvController"
    }

    Wait-SamsungTvControlReady -TvIp $tvIp
    $dialState = Get-TizenTubeDialState
    $brewVisible = Get-TizenBrewVisibleState
    if ($dialState -eq 'running' -and -not $brewVisible) {
        Write-ActionLog "YOUTUBE_TIZEN_COMPLETED dialState=running brewVisible=False path=already-running"
        return
    }

    $initialDialState = $dialState
    $freshTizenBrewLaunch = -not $brewVisible
    if ($freshTizenBrewLaunch) {
        try {
            Invoke-RestMethod -UseBasicParsing -Method POST -Uri "http://${tvIp}:8001/api/v2/applications/$tizenBrewAppId" -Body '{}' -ContentType 'application/json' -TimeoutSec 4 | Out-Null
            Write-ActionLog 'YOUTUBE_TIZEN_BREW_REST_LAUNCH_SENT'
        } catch {
            Write-ActionLog "YOUTUBE_TIZEN_BREW_REST_LAUNCH_FAILED error=`"$($_.Exception.Message)`""
        }

        $brewDeadline = (Get-Date).AddSeconds(8)
        do {
            if (Get-TizenBrewVisibleState) { break }
            Start-Sleep -Milliseconds 180
        } while ((Get-Date) -lt $brewDeadline)

        if (-not (Get-TizenBrewVisibleState)) {
            $env:SAMSUNG_TV_HOST = $tvIp
            $launchProcess = Start-Process -FilePath $node -ArgumentList @($tvController, 'app', $tizenBrewAppId) -WindowStyle Hidden -PassThru
            Write-ActionLog "YOUTUBE_TIZEN_BREW_CONTROLLER_STARTED pid=$($launchProcess.Id)"

            $brewDeadline = (Get-Date).AddSeconds(20)
            do {
                if (Get-TizenBrewVisibleState) { break }
                if ($launchProcess.HasExited -and $launchProcess.ExitCode -ne 0) {
                    throw "Paired controller could not launch TizenBrew (exit $($launchProcess.ExitCode))."
                }
                Start-Sleep -Milliseconds 250
            } while ((Get-Date) -lt $brewDeadline)
        }
        if (-not (Get-TizenBrewVisibleState)) {
            throw 'TizenBrew did not become visible.'
        }

        # This TV reports TizenBrew visible before its cards can accept focus.
        # The installed known-good launcher uses this exact settle interval.
        Write-ActionLog 'YOUTUBE_TIZEN_CARD_SURFACE_WAIT milliseconds=4500'
        Start-Sleep -Milliseconds 4500
    }

    $keyDelay = if ($freshTizenBrewLaunch) { 900 } else { 180 }
    $env:SAMSUNG_TV_HOST = $tvIp
    $sequenceProcess = Start-Process -FilePath $node -ArgumentList @(
        $tvController, 'sequence', "--delay-ms=$keyDelay", 'KEY_DOWN', 'KEY_LEFT', 'KEY_ENTER'
    ) -WindowStyle Hidden -PassThru
    Write-ActionLog "YOUTUBE_TIZEN_CARD_KEY_SEQUENCE_SENT delayMs=$keyDelay keys=KEY_DOWN,KEY_LEFT,KEY_ENTER pid=$($sequenceProcess.Id)"

    $dialDeadline = (Get-Date).AddSeconds(60)
    $dialStartAttempted = $false
    $sequenceExitReported = $false
    $dialServiceWaitingLogged = $false
    $firstSequenceExitAt = $null
    $cardRecoverySequenceStarted = $false
    do {
        $dialState = Get-TizenTubeDialState
        $brewVisible = Get-TizenBrewVisibleState
        $dialTransitionedToRunning = $initialDialState -ne 'running'
        if ($dialState -eq 'running' -and (-not $brewVisible -or $dialTransitionedToRunning)) {
            Write-ActionLog "YOUTUBE_TIZEN_COMPLETED dialState=running brewVisible=$brewVisible path=paired-controller"
            return
        }
        if ($null -eq $dialState -and -not $dialServiceWaitingLogged) {
            Write-ActionLog 'YOUTUBE_TIZEN_DIAL_SERVICE_WAITING timeoutSeconds=60'
            $dialServiceWaitingLogged = $true
        }
        if ($sequenceProcess.HasExited) {
            if (-not $sequenceExitReported) {
                Write-ActionLog "YOUTUBE_TIZEN_CARD_SEQUENCE_EXIT exitCode=$($sequenceProcess.ExitCode)"
                $sequenceExitReported = $true
            }
            if ($sequenceProcess.ExitCode -ne 0) {
                throw "Paired controller TizenTube card sequence failed (exit $($sequenceProcess.ExitCode))."
            }
            if ($dialState -and -not $dialStartAttempted) {
                $dialStartAttempted = $true
                [void](Invoke-TizenTubeDialStart -Reason "card-sequence-state-$dialState")
            }
            if ($null -eq $dialState -and -not $cardRecoverySequenceStarted) {
                if ($null -eq $firstSequenceExitAt) {
                    $firstSequenceExitAt = Get-Date
                    Write-ActionLog 'YOUTUBE_TIZEN_CARD_FOCUS_PRIME_WAITING milliseconds=6000'
                } elseif ((Get-Date) -ge $firstSequenceExitAt.AddSeconds(6)) {
                    $cardRecoverySequenceStarted = $true
                    $sequenceExitReported = $false
                    $sequenceProcess = Start-Process -FilePath $node -ArgumentList @(
                        $tvController, 'sequence', '--delay-ms=900', 'KEY_DOWN', 'KEY_LEFT', 'KEY_ENTER'
                    ) -WindowStyle Hidden -PassThru
                    Write-ActionLog "YOUTUBE_TIZEN_CARD_RECOVERY_SEQUENCE_SENT delayMs=900 keys=KEY_DOWN,KEY_LEFT,KEY_ENTER pid=$($sequenceProcess.Id)"
                }
            }
        }
        Start-Sleep -Milliseconds 300
    } while ((Get-Date) -lt $dialDeadline)

    throw "TizenTube did not confirm DIAL running after paired-controller navigation (dial=$dialState brewVisible=$brewVisible)."
}

function Invoke-YoutubeTizen {
    $mutex = [Threading.Mutex]::new($false, 'Global\RemoteCommandCenterYoutubeTizen')
    $lockTaken = $false
    try {
        try { $lockTaken = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $lockTaken = $true }
        if (-not $lockTaken) {
            Write-ActionLog 'YOUTUBE_TIZEN_ALREADY_RUNNING skipped=True'
            return
        }
        if (Test-ProofOnly) {
            Write-ActionLog 'PROOF_ONLY active; paired-controller launch was not started.'
            return
        }
        Write-ActionLog 'YOUTUBE_TIZEN_EXECUTING path=paired-controller'
        Invoke-TizenTubeViaPairedController
    } finally {
        if ($lockTaken) { $mutex.ReleaseMutex() }
        $mutex.Dispose()
    }
}

function Invoke-StremioTv {
    $controller = Join-Path $PSScriptRoot 'samsung-tv-control.js'
    $appId = '3202306031311'
    $legacyPackageId = 'Stremio.IkWsFHtOY9'
    $tvHost = if ($env:SAMSUNG_TV_HOST) { $env:SAMSUNG_TV_HOST } else { '192.168.1.173' }
    $appUri = "http://$tvHost`:8001/api/v2/applications/$appId"
    Write-ActionLog "STREMIO_TV_READY appId=$appId legacyPackageId=$legacyPackageId controller=`"$controller`" controllerExists=$(Test-Path -LiteralPath $controller -PathType Leaf) tvHost=$tvHost launchMethod=SamsungDefaultAppRest"
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; Samsung TV Stremio app was not launched.'
        return
    }

    $restLaunchSent = $false
    try {
        $restResult = Invoke-RestMethod -Method Post -Uri $appUri -Body '{}' -ContentType 'application/json' -TimeoutSec 8
        Write-ActionLog "STREMIO_TV_REST_POST result=$restResult appId=$appId"
        $restLaunchSent = $true
    } catch {
        Write-ActionLog "STREMIO_TV_REST_POST_FAILED appId=$appId error=$($_.Exception.Message)"
    }

    for ($attempt = 1; $attempt -le 12; $attempt++) {
        try {
            $state = Invoke-RestMethod -Uri $appUri -TimeoutSec 8
            Write-ActionLog "STREMIO_TV_STATE attempt=$attempt appId=$($state.id) name=$($state.name) running=$($state.running) visible=$($state.visible) version=$($state.version)"
            if ($state.name -eq 'Stremio' -and $state.running -eq $true -and $state.visible -eq $true) {
                Write-ActionLog "STREMIO_TV_VISIBLE appId=$appId"
                return
            }
        } catch {
            Write-ActionLog "STREMIO_TV_STATE_FAILED attempt=$attempt appId=$appId error=$($_.Exception.Message)"
        }
        Start-Sleep -Milliseconds 750
    }

    try {
        $putResult = Invoke-RestMethod -Method Put -Uri $appUri -Body '{}' -ContentType 'application/json' -TimeoutSec 8
        Write-ActionLog "STREMIO_TV_REST_PUT result=$putResult appId=$appId"
    } catch {
        Write-ActionLog "STREMIO_TV_REST_PUT_FAILED appId=$appId error=$($_.Exception.Message)"
    }

    for ($attempt = 1; $attempt -le 8; $attempt++) {
        try {
            $state = Invoke-RestMethod -Uri $appUri -TimeoutSec 8
            Write-ActionLog "STREMIO_TV_STATE_AFTER_PUT attempt=$attempt appId=$($state.id) name=$($state.name) running=$($state.running) visible=$($state.visible) version=$($state.version)"
            if ($state.name -eq 'Stremio' -and $state.running -eq $true -and $state.visible -eq $true) {
                Write-ActionLog "STREMIO_TV_VISIBLE appId=$appId"
                return
            }
        } catch {
            Write-ActionLog "STREMIO_TV_STATE_AFTER_PUT_FAILED attempt=$attempt appId=$appId error=$($_.Exception.Message)"
        }
        Start-Sleep -Milliseconds 750
    }

    if (Test-Path -LiteralPath $controller -PathType Leaf) {
        $nodeCandidates = @(
            (Get-Command node.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
            (Join-Path $env:LOCALAPPDATA 'OpenAI\CodexPatchedMobileSlash\app\resources\node.exe'),
            (Join-Path $env:ProgramFiles 'nodejs\node.exe'),
            (Join-Path ${env:ProgramFiles(x86)} 'nodejs\node.exe')
        ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
        $nodePath = ''
        foreach ($candidate in $nodeCandidates) {
            if (Test-Path -LiteralPath $candidate -PathType Leaf) {
                $nodePath = $candidate
                break
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($nodePath)) {
            Write-ActionLog "STREMIO_TV_NODE_READY node=`"$nodePath`""
            $output = & $nodePath $controller app $appId NATIVE_LAUNCH 2>&1
            $exit = $LASTEXITCODE
            foreach ($line in @($output)) {
                Write-ActionLog "STREMIO_TV_CONTROLLER $line"
            }
            if ($exit -ne 0) {
                Write-ActionLog "STREMIO_TV_WEBSOCKET_FAILED exit=$exit appId=$appId"
            }
        } else {
            Write-ActionLog "STREMIO_TV_NODE_MISSING checked=$($nodeCandidates -join ';')"
        }
    } else {
        Write-ActionLog "STREMIO_TV_CONTROLLER_MISSING controller=`"$controller`""
    }

    for ($attempt = 1; $attempt -le 8; $attempt++) {
        try {
            $state = Invoke-RestMethod -Uri $appUri -TimeoutSec 8
            Write-ActionLog "STREMIO_TV_STATE_AFTER_WS attempt=$attempt appId=$($state.id) name=$($state.name) running=$($state.running) visible=$($state.visible) version=$($state.version)"
            if ($state.name -eq 'Stremio' -and $state.running -eq $true -and $state.visible -eq $true) {
                Write-ActionLog "STREMIO_TV_VISIBLE appId=$appId"
                return
            }
        } catch {
            Write-ActionLog "STREMIO_TV_STATE_AFTER_WS_FAILED attempt=$attempt appId=$appId error=$($_.Exception.Message)"
        }
        Start-Sleep -Milliseconds 750
    }

    Write-ActionLog "STREMIO_TV_NOT_VISIBLE appId=$appId restLaunchSent=$restLaunchSent"
    exit 5
}

function Get-SamsungTvNodePath {
    $nodeCandidates = @(
        (Get-Command node.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
        (Join-Path $env:LOCALAPPDATA 'OpenAI\CodexPatchedMobileSlash\app\resources\node.exe'),
        (Join-Path $env:ProgramFiles 'nodejs\node.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'nodejs\node.exe')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
    foreach ($candidate in $nodeCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }
    return ''
}

function Invoke-SamsungTvRemoteKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ActionName,
        [Parameter(Mandatory=$true)]
        [string]$Key,
        [int]$HoldMilliseconds = 0
    )

    $controller = Join-Path $PSScriptRoot 'samsung-tv-control.js'
    $tvHost = if ($env:SAMSUNG_TV_HOST) { $env:SAMSUNG_TV_HOST } else { '192.168.1.173' }
    $nodePath = Get-SamsungTvNodePath
    Write-ActionLog "SAMSUNG_TV_REMOTE_READY action=$ActionName key=$Key holdMs=$HoldMilliseconds controller=`"$controller`" controllerExists=$(Test-Path -LiteralPath $controller -PathType Leaf) node=`"$nodePath`" tvHost=$tvHost"
    if (Test-ProofOnly) {
        Write-ActionLog "PROOF_ONLY active; Samsung TV key was not sent. action=$ActionName key=$Key"
        return
    }
    if (-not (Test-Path -LiteralPath $controller -PathType Leaf)) {
        Write-ActionLog "SAMSUNG_TV_CONTROLLER_MISSING controller=`"$controller`""
        exit 5
    }

    $bridgeUri = 'http://127.0.0.1:8781/key'
    try {
        $payload = @{
            key = $Key
            cmd = 'Click'
            holdMs = $HoldMilliseconds
        } | ConvertTo-Json -Compress
        $started = Get-Date
        $bridgeTimeoutSeconds = [Math]::Max(5, [int][Math]::Ceiling(($HoldMilliseconds + 3000) / 1000))
        $bridgeResponse = Invoke-RestMethod -Method Post -Uri $bridgeUri -Body $payload -ContentType 'application/json' -TimeoutSec $bridgeTimeoutSeconds
        $elapsedMs = [int]((Get-Date) - $started).TotalMilliseconds
        Write-ActionLog "SAMSUNG_TV_BRIDGE_SENT action=$ActionName key=$Key holdMs=$HoldMilliseconds elapsedMs=$elapsedMs response=$($bridgeResponse | ConvertTo-Json -Compress)"
        return
    } catch {
        Write-ActionLog "SAMSUNG_TV_BRIDGE_FAILED action=$ActionName key=$Key holdMs=$HoldMilliseconds errorType=$($_.Exception.GetType().Name)"
        Write-ActionLog "SAMSUNG_TV_REMOTE_NOT_RETRIED action=$ActionName reason=bridgeOutcomeMayBeAmbiguous"
        exit 7
    }
}

function Invoke-SamsungTvSetVolume {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Volume
    )

    if ($Volume -lt 0 -or $Volume -gt 100) {
        Write-ActionLog "SAMSUNG_TV_SET_VOLUME_INVALID volume=$Volume"
        exit 2
    }

    $tvHost = if ($env:SAMSUNG_TV_HOST) { $env:SAMSUNG_TV_HOST } else { '192.168.1.173' }
    $uri = "http://$tvHost`:9197/upnp/control/RenderingControl1"
    $soapAction = '"urn:schemas-upnp-org:service:RenderingControl:1#SetVolume"'
    $body = @"
<?xml version="1.0"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:SetVolume xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1">
      <InstanceID>0</InstanceID>
      <Channel>Master</Channel>
      <DesiredVolume>$Volume</DesiredVolume>
    </u:SetVolume>
  </s:Body>
</s:Envelope>
"@

    Write-ActionLog "SAMSUNG_TV_SET_VOLUME_READY volume=$Volume uri=$uri"
    if (Test-ProofOnly) {
        Write-ActionLog "PROOF_ONLY active; Samsung TV volume was not changed. volume=$Volume"
        return
    }

    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
        $request = [System.Net.HttpWebRequest]::Create($uri)
        $request.Method = 'POST'
        $request.ContentType = 'text/xml; charset="utf-8"'
        $request.Headers.Add('SOAPACTION', $soapAction)
        $request.Timeout = 4000
        $request.ReadWriteTimeout = 4000
        $request.ContentLength = $bytes.Length
        $stream = $request.GetRequestStream()
        try {
            $stream.Write($bytes, 0, $bytes.Length)
        } finally {
            $stream.Close()
        }

        $response = $request.GetResponse()
        try {
            Write-ActionLog "SAMSUNG_TV_SET_VOLUME_SENT volume=$Volume status=$([int]$response.StatusCode)"
        } finally {
            $response.Close()
        }
    } catch {
        Write-ActionLog "SAMSUNG_TV_SET_VOLUME_FAILED volume=$Volume error=$($_.Exception.Message)"
        if ($_.Exception.Response) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                Write-ActionLog "SAMSUNG_TV_SET_VOLUME_ERROR_BODY $($reader.ReadToEnd())"
            } catch {
            }
        }
        exit 5
    }
}

function Convert-RccMacStringToBytes {
    param([Parameter(Mandatory=$true)][string]$Mac)
    $clean = ($Mac -replace '[^0-9A-Fa-f]', '').ToUpperInvariant()
    if ($clean.Length -ne 12) {
        throw "Invalid MAC address: $Mac"
    }
    $bytes = New-Object byte[] 6
    for ($i = 0; $i -lt 6; $i++) {
        $bytes[$i] = [Convert]::ToByte($clean.Substring($i * 2, 2), 16)
    }
    return $bytes
}

function Send-RccWakeOnLanPackets {
    param(
        [Parameter(Mandatory=$true)][string]$Mac,
        [string[]]$Broadcasts = @('255.255.255.255','192.168.1.255'),
        [int[]]$Ports = @(7,9,40000,40009),
        [int]$Rounds = 8,
        [int]$DelayMilliseconds = 180
    )

    $macBytes = Convert-RccMacStringToBytes -Mac $Mac
    $packet = New-Object byte[] 102
    for ($i = 0; $i -lt 6; $i++) { $packet[$i] = 0xFF }
    for ($repeat = 0; $repeat -lt 16; $repeat++) {
        [Array]::Copy($macBytes, 0, $packet, 6 + ($repeat * 6), 6)
    }

    $sent = 0
    $udp = [System.Net.Sockets.UdpClient]::new()
    try {
        $udp.EnableBroadcast = $true
        for ($round = 0; $round -lt $Rounds; $round++) {
            foreach ($broadcast in $Broadcasts) {
                foreach ($port in $Ports) {
                    try {
                        $endpoint = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Parse($broadcast), $port)
                        [void]$udp.Send($packet, $packet.Length, $endpoint)
                        $sent++
                    } catch {
                        Write-ActionLog "TV_WOL_SEND_FAILED mac=$Mac broadcast=$broadcast port=$port error=$($_.Exception.Message)"
                    }
                }
            }
            if ($DelayMilliseconds -gt 0) {
                Start-Sleep -Milliseconds $DelayMilliseconds
            }
        }
    } finally {
        $udp.Close()
    }
    Write-ActionLog "TV_WOL_SENT mac=$Mac packets=$sent broadcasts=$($Broadcasts -join ',') ports=$($Ports -join ',')"
    return $sent
}

function Get-SamsungTvInfo {
    param([string]$TvHost = '192.168.1.173')
    Invoke-RestMethod -Uri "http://$TvHost`:8001/api/v2/" -TimeoutSec 3
}

function Test-SamsungTvApiReady {
    param([string]$TvHost = '192.168.1.173')
    try {
        $info = Get-SamsungTvInfo -TvHost $TvHost
        return ($null -ne $info -and $null -ne $info.device)
    } catch {
        return $false
    }
}

function Get-SamsungTvPowerState {
    param([string]$TvHost = '192.168.1.173')
    try {
        $info = Get-SamsungTvInfo -TvHost $TvHost
        if ($info.device.PowerState) {
            return [string]$info.device.PowerState
        }
        return 'unknown'
    } catch {
        return 'unreachable'
    }
}

function Get-SamsungTvWakeMac {
    param([string]$TvHost = '192.168.1.173')
    try {
        $info = Get-SamsungTvInfo -TvHost $TvHost
        if ($info.device.wifiMac) {
            return [string]$info.device.wifiMac
        }
    } catch {
        Write-ActionLog "SAMSUNG_TV_MAC_API_FAILED host=$TvHost error=$($_.Exception.Message)"
    }

    try {
        $arpOutput = & (Join-Path $env:SystemRoot 'System32\arp.exe') -a $TvHost 2>&1
        $arpText = $arpOutput -join "`n"
        $match = [regex]::Match($arpText, '([0-9a-fA-F]{2}(?:-[0-9a-fA-F]{2}){5})')
        if ($match.Success) {
            return $match.Groups[1].Value.Replace('-', ':')
        }
    } catch {
        Write-ActionLog "SAMSUNG_TV_MAC_ARP_FAILED host=$TvHost error=$($_.Exception.Message)"
    }

    if ($TvHost -eq '192.168.1.173') {
        return 'b0:99:d7:01:9a:26'
    }
    return ''
}

function Invoke-SamsungTvPowerCycleReboot {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ActionName
    )

    $tvHost = if ($env:SAMSUNG_TV_HOST) { $env:SAMSUNG_TV_HOST } else { '192.168.1.173' }
    $mac = Get-SamsungTvWakeMac -TvHost $tvHost
    Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_REBOOT_READY action=$ActionName host=$tvHost mac=$mac apiReady=$(Test-SamsungTvApiReady -TvHost $tvHost)"
    if (Test-ProofOnly) {
        Write-ActionLog "PROOF_ONLY active; Samsung TV power-cycle reboot was not sent. action=$ActionName host=$tvHost mac=$mac"
        return
    }
    if ([string]::IsNullOrWhiteSpace($mac)) {
        Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_REBOOT_NO_MAC action=$ActionName host=$tvHost"
        exit 5
    }

    Invoke-SamsungTvRemoteKey -ActionName "$ActionName.power_off_phase" -Key 'KEY_POWER'

    $wentDown = $false
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Seconds 1
        if (-not (Test-SamsungTvApiReady -TvHost $tvHost)) {
            $wentDown = $true
            Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_OFF_CONFIRMED action=$ActionName afterSeconds=$($i + 1)"
            break
        }
    }
    if (-not $wentDown) {
        Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_OFF_NOT_OBSERVED action=$ActionName proceedingWithWake=True"
    }

    $ready = $false
    for ($attempt = 1; $attempt -le 18; $attempt++) {
        Send-RccWakeOnLanPackets -Mac $mac -Rounds 4 -DelayMilliseconds 90 | Out-Null
        Start-Sleep -Seconds 2
        $powerState = Get-SamsungTvPowerState -TvHost $tvHost
        Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_REBOOT_POLL action=$ActionName attempt=$attempt powerState=$powerState"
        if ($powerState -eq 'on') {
            $ready = $true
            Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_REBOOT_READY_AGAIN action=$ActionName attempt=$attempt powerState=$powerState"
            break
        }
        if ($powerState -eq 'standby') {
            Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_REBOOT_POWER_ON_PHASE action=$ActionName attempt=$attempt"
            Invoke-SamsungTvRemoteKey -ActionName "$ActionName.power_on_phase" -Key 'KEY_POWER'
            Start-Sleep -Seconds 5
            $powerState = Get-SamsungTvPowerState -TvHost $tvHost
            Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_REBOOT_AFTER_POWER_ON action=$ActionName attempt=$attempt powerState=$powerState"
            if ($powerState -eq 'on') {
                $ready = $true
                Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_REBOOT_READY_AGAIN action=$ActionName attempt=$attempt powerState=$powerState"
                break
            }
        }
    }

    if (-not $ready) {
        Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_REBOOT_WAKE_FAILED action=$ActionName host=$tvHost mac=$mac"
        exit 6
    }
    Write-ActionLog "SAMSUNG_TV_POWER_CYCLE_REBOOT_DONE action=$ActionName host=$tvHost mac=$mac"
}

function Get-SamsungTvSdbPath {
    $sdbCandidates = @(
        $env:RCC_SDB_PATH,
        'F:\backup\windowsapps\installed\SamsungSDB\data\tools\sdb.exe',
        (Join-Path $env:USERPROFILE 'tizen-studio\tools\sdb.exe'),
        (Join-Path $env:LOCALAPPDATA 'TizenStudio\tools\sdb.exe')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
    foreach ($candidate in $sdbCandidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return $candidate
        }
    }
    return ''
}

function Invoke-SamsungTvSdbReboot {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ActionName
    )

    $tvHost = if ($env:SAMSUNG_TV_HOST) { $env:SAMSUNG_TV_HOST } else { '192.168.1.173' }
    $sdb = Get-SamsungTvSdbPath
    $target = "$tvHost`:26101"
    Write-ActionLog "SAMSUNG_TV_SDB_REBOOT_READY action=$ActionName sdb=`"$sdb`" sdbExists=$(-not [string]::IsNullOrWhiteSpace($sdb)) target=$target"
    if (Test-ProofOnly) {
        Write-ActionLog "PROOF_ONLY active; Samsung TV SDB reboot was not sent. action=$ActionName target=$target"
        return
    }
    if ([string]::IsNullOrWhiteSpace($sdb)) {
        Write-ActionLog 'SAMSUNG_TV_SDB_MISSING'
        exit 5
    }

    $connectOutput = & $sdb connect $target 2>&1
    $connectExit = $LASTEXITCODE
    foreach ($line in @($connectOutput)) {
        Write-ActionLog "SAMSUNG_TV_SDB_CONNECT $line"
    }
    if ($connectExit -ne 0) {
        Write-ActionLog "SAMSUNG_TV_SDB_CONNECT_FAILED action=$ActionName target=$target exit=$connectExit"
        exit $connectExit
    }

    $beforeUptime = $null
    try {
        $beforeText = (& $sdb -s $target shell cat /proc/uptime 2>$null | Select-Object -First 1)
        $parsedBefore = 0.0
        if ([double]::TryParse(([string]$beforeText -split '\s+')[0], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsedBefore)) {
            $beforeUptime = $parsedBefore
        }
    } catch {}
    Write-ActionLog "SAMSUNG_TV_SDB_UPTIME_BEFORE action=$ActionName seconds=$beforeUptime"

    $rebootOutput = & $sdb -s $target shell reboot 2>&1
    $rebootExit = $LASTEXITCODE
    foreach ($line in @($rebootOutput)) {
        Write-ActionLog "SAMSUNG_TV_SDB_REBOOT $line"
    }
    if ($rebootExit -ne 0) {
        Write-ActionLog "SAMSUNG_TV_SDB_REBOOT_FAILED action=$ActionName target=$target exit=$rebootExit"
        exit $rebootExit
    }
    Write-ActionLog "SAMSUNG_TV_SDB_REBOOT_SENT action=$ActionName target=$target"

    $restartObserved = $false
    for ($attempt = 1; $attempt -le 90; $attempt++) {
        Start-Sleep -Seconds 1
        try {
            & $sdb connect $target 2>&1 | ForEach-Object { Write-ActionLog "SAMSUNG_TV_SDB_RECONNECT $_" }
            $afterText = (& $sdb -s $target shell cat /proc/uptime 2>$null | Select-Object -First 1)
            $parsedAfter = 0.0
            if ([double]::TryParse(([string]$afterText -split '\s+')[0], [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsedAfter)) {
                Write-ActionLog "SAMSUNG_TV_SDB_UPTIME_AFTER action=$ActionName attempt=$attempt seconds=$parsedAfter"
                if ($parsedAfter -lt 180 -and ($null -eq $beforeUptime -or $parsedAfter -lt $beforeUptime)) {
                    $restartObserved = $true
                    break
                }
            }
        } catch {}
    }
    if (-not $restartObserved) {
        Write-ActionLog "SAMSUNG_TV_SDB_REBOOT_NOT_VERIFIED action=$ActionName target=$target"
        exit 6
    }
    Write-ActionLog "SAMSUNG_TV_SDB_REBOOT_VERIFIED action=$ActionName target=$target"
}

function Get-RccWindowsTerminalPath {
    $command = Get-Command wt.exe -ErrorAction SilentlyContinue
    if ($command -and -not [string]::IsNullOrWhiteSpace($command.Source) -and (Test-Path -LiteralPath $command.Source)) {
        return $command.Source
    }
    $aliasPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\wt.exe'
    if (Test-Path -LiteralPath $aliasPath) {
        return $aliasPath
    }
    $packaged = Get-ChildItem -Path (Join-Path $env:ProgramFiles 'WindowsApps\Microsoft.WindowsTerminal_*\wt.exe') -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($packaged) {
        return $packaged.FullName
    }
    return ''
}

function Get-RccWindowsTerminalRunnerArguments {
    param(
        [Parameter(Mandatory=$true)][string]$PowerShellPath,
        [Parameter(Mandatory=$true)][string[]]$RunnerArguments
    )
    if ([string]::IsNullOrWhiteSpace($PowerShellPath)) {
        throw 'The PowerShell executable path is required for Windows Terminal.'
    }
    return (@('new-tab', $PowerShellPath) + $RunnerArguments)
}

function Get-RccTerminalBootstrapLine {
    $definitionsCandidates = @(
        $env:RCC_PROFILE_DEFINITIONS_PATH,
        'F:\backup\windowsapps\profile\profile-backup\ps5-profile-portable\Microsoft.PowerShell_profile.full.definitions.ps1',
        'F:\backup\windowsapps\profile\profile-backup\WindowsPowerShell\ProfileSources\ps5-profile-portable\Microsoft.PowerShell_profile.full.definitions.ps1',
        'F:\backup\windowsapps\profile\backup-data\ps5-profile-portable\Microsoft.PowerShell_profile.full.definitions.ps1'
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique
    $definitionsPath = $definitionsCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $definitionsPath) { $definitionsPath = $definitionsCandidates | Select-Object -First 1 }
    $safeDefinitionsPath = $definitionsPath.Replace("'", "''")
    @(
        ('$__rccDefs = ''{0}''' -f $safeDefinitionsPath),
        'if ((Test-Path -LiteralPath $__rccDefs) -and (Get-Command Get-ProfileFunctionMap -CommandType Function -ErrorAction SilentlyContinue)) { $global:RccTerminalProfileFunctionMap = Get-ProfileFunctionMap -ProfilePath $__rccDefs; $ExecutionContext.InvokeCommand.CommandNotFoundAction = { param($CommandName, $CommandLookupEventArgs) $name = $CommandName -replace ''^(?i:global:)'', ''''; if ($global:RccTerminalProfileFunctionMap -and $global:RccTerminalProfileFunctionMap.ContainsKey($name)) { $ast = $global:RccTerminalProfileFunctionMap[$name]; $body = [string]$ast.Body.Extent.Text; $open = $body.IndexOf(''{''); $close = $body.LastIndexOf(''}''); if ($open -ge 0 -and $close -gt $open) { $body = $body.Substring($open + 1, $close - $open - 1) }; $CommandLookupEventArgs.CommandScriptBlock = [scriptblock]::Create($body); $CommandLookupEventArgs.StopSearch = $true } } }',
        'Remove-Variable __rccDefs -ErrorAction SilentlyContinue'
    ) -join '; '
}

function Invoke-RccRunInTerminal {
    param(
        [Parameter(Mandatory=$true)][string]$CommandLine,
        [string]$TerminalPath = '',
        [string]$CompletionNonce = ''
    )
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; terminal command was not persisted or executed.'
        return
    }
    if ($CompletionNonce -cnotmatch '^[A-Za-z0-9_-]{16,128}$') {
        throw 'Invalid terminal completion nonce.'
    }

    $runnerFile = Join-Path $scriptRoot 'Invoke-RemoteCommandCenterTerminalRunner.ps1'
    if (-not (Test-Path -LiteralPath $runnerFile -PathType Leaf)) {
        throw 'The checked-in terminal runner is missing.'
    }
    $runRoot = Join-Path $stateDir 'terminal-runs'
    New-Item -ItemType Directory -Force -Path $runRoot | Out-Null
    $runId = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmss-fff'), $PID
    $commandFile = Join-Path $runRoot "command-$runId.txt"
    $bootstrapFile = Join-Path $runRoot "bootstrap-$runId.ps1"
    $commandLog = Join-Path $runRoot "runner-$runId.log"
    $completionFile = Join-Path $runRoot "result-$CompletionNonce.json"
    if (Test-Path -LiteralPath $completionFile -PathType Leaf) {
        throw 'Terminal completion record already exists.'
    }

    $deadline = [DateTimeOffset]::UtcNow.AddSeconds(315)
    $bootstrap = Get-RccTerminalBootstrapLine
    try {
        Set-Content -LiteralPath $commandFile -Encoding UTF8 -NoNewline -Value $CommandLine
        Set-Content -LiteralPath $bootstrapFile -Encoding UTF8 -NoNewline -Value $bootstrap
        Write-ActionLog "TERMINAL_RUNNER_READY runner=checked-in commandLog=""$commandLog"" chars=$($CommandLine.Length) mode=no-paste-script-runner"

        $runnerArgs = @(
            '-NoExit','-ExecutionPolicy','Bypass','-File',$runnerFile,
            '-CommandFile',$commandFile,'-BootstrapFile',$bootstrapFile,'-LogFile',$commandLog,
            '-CompletionNonce',$CompletionNonce,'-ResultFile',$completionFile,
            '-ResultDeadlineUtc',$deadline.ToString('o')
        )
        try {
            if (-not [string]::IsNullOrWhiteSpace($TerminalPath)) {
                Start-Process -FilePath $TerminalPath -Verb RunAs -ArgumentList (Get-RccWindowsTerminalRunnerArguments -PowerShellPath $ps -RunnerArguments $runnerArgs) -ErrorAction Stop | Out-Null
            } else {
                Start-Process -FilePath $ps -Verb RunAs -ArgumentList $runnerArgs -ErrorAction Stop | Out-Null
            }
        } catch {
            Write-ActionLog 'TERMINAL_RUNNER_LAUNCH_FAILED elevation-or-terminal-start-failed=True'
            throw 'The elevated terminal runner did not start.'
        }

        while ([DateTimeOffset]::UtcNow -lt $deadline -and -not (Test-Path -LiteralPath $completionFile -PathType Leaf)) {
            Start-Sleep -Milliseconds 200
        }
        if (-not (Test-Path -LiteralPath $completionFile -PathType Leaf)) {
            Write-ActionLog "TERMINAL_RUNNER_COMPLETION_UNCONFIRMED nonce=$CompletionNonce timeoutSeconds=315"
            $timeoutError = New-Object System.InvalidOperationException('The terminal runner did not report a result before the bounded wait ended.')
            $timeoutError.Data['RccExitCode'] = 124
            throw $timeoutError
        }

        try {
            $result = Get-Content -LiteralPath $completionFile -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
            if ([string]$result.type -cne 'rcc-terminal-result' -or [string]$result.nonce -cne $CompletionNonce) {
                throw 'Terminal completion record did not match this request.'
            }
            if ([string]$result.state -cne 'completed' -or [int]$result.exitCode -ne 0) {
                throw 'The PowerShell line reported an error in the elevated terminal.'
            }
            Write-ActionLog "TERMINAL_RUNNER_RETURNED nonce=$CompletionNonce exitCode=0 realWorldEffectsVerified=False"
        } catch {
            throw 'The terminal runner returned a failed or invalid completion record.'
        }
    } catch {
        if ($_.Exception.Data['RccExitCode'] -eq 124) { throw }
        Write-ActionLog 'TERMINAL_RUNNER_FAILED result=failed-or-unconfirmed'
        throw 'The terminal runner did not confirm that the line returned.'
    } finally {
        Remove-Item -LiteralPath $commandFile, $bootstrapFile, $completionFile -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-AdminTerminal {
    param([string]$CommandLine = '', [string]$CompletionNonce = '')
    $terminalPath = Get-RccWindowsTerminalPath
    $hasCommand = -not [string]::IsNullOrWhiteSpace($CommandLine)
    Write-ActionLog ('ADMIN_TERMINAL_READY terminal="{0}" fallback="{1}" hasCommand={2} mode=default-terminal-no-paste-runner' -f $terminalPath, $ps, $hasCommand)
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; elevated terminal was not opened and terminal command was not persisted or executed.'
        return
    }
    if ($hasCommand) {
        Invoke-RccRunInTerminal -CommandLine $CommandLine -TerminalPath $terminalPath -CompletionNonce $CompletionNonce
    } elseif (-not [string]::IsNullOrWhiteSpace($terminalPath)) {
        Start-Process -FilePath $terminalPath -Verb RunAs | Out-Null
    } else {
        Start-Process -FilePath $ps -Verb RunAs -ArgumentList @('-NoExit') | Out-Null
    }
    Write-ActionLog "ADMIN_TERMINAL_LAUNCH_REQUESTED elevation=RunAs shell=DefaultTerminalOrPowerShell profile=default hasCommand=$hasCommand execution=no-paste-script-runner"
}

function Invoke-TerminalLine {
    param([string]$EncodedLine)
    $line = ConvertFrom-RccBase64Url -Text $EncodedLine
    Write-ActionLog "TERMINAL_LINE_READY chars=$($line.Length) mode=fresh-elevated-terminal-tab"
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; fresh elevated terminal tab was not opened and command was not persisted or executed.'
        return
    }
    try {
        Invoke-AdminTerminal -CommandLine $line -CompletionNonce $Nonce
    } catch {
        if ($_.Exception.Data['RccExitCode'] -eq 124) {
            exit 124
        }
        throw
    }
    Write-ActionLog 'TERMINAL_LINE_RETURNED launch=fresh-elevated-terminal-tab execution=no-paste-script-runner realWorldEffectsVerified=False'
}



function Invoke-Refresh2Logoff {
    Write-ActionLog 'REFRESH2_LOGOFF_READY method=shutdown.exe args=/l /f winlogonMutation=False'
    Invoke-Executable -FilePath $shutdown -Arguments @('/l','/f')
}

$system32 = Join-Path $env:SystemRoot 'System32'
$shutdown = Join-Path $system32 'shutdown.exe'
$rundll32 = Join-Path $system32 'rundll32.exe'
$tsdiscon = Join-Path $system32 'tsdiscon.exe'
$ps = Join-Path $system32 'WindowsPowerShell\v1.0\powershell.exe'

$actionLogLabel = if ($Action -like 'terminal_line:*') { 'terminal_line' } else { $Action }
Write-ActionLog "RCC_ACTION_START action=$actionLogLabel nonce=$Nonce proofOnly=$(Test-ProofOnly)"

switch ($Action) {
    'force_reboot_now' {
        Invoke-Executable -FilePath $shutdown -Arguments @('/r','/f','/t','0','/c',"RemoteCommandCenter force reboot nonce=$Nonce")
    }
    { $_ -in @('sleep_pc','sleep_toggle') } {
        Start-ControlledSleep
    }
    { $_ -in @('hibernate_pc','hibernate_toggle') } {
        Write-ActionLog 'HIBERNATE_REQUEST_REROUTED_TO_CONTROLLED_SLEEP reason=preserve guaranteed Android wake path'
        Start-ControlledSleep
    }
    { $_ -in @('wake_pc','wake_controlled_sleep') } {
        Stop-ControlledSleep
    }
    'wake_settings_repair' {
        $wakeSettings = Join-Path $PSScriptRoot 'Ensure-RemoteCommandCenterWakeSettings.ps1'
        if (-not (Test-Path -LiteralPath $wakeSettings -PathType Leaf)) { exit 5 }
        $wakeArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$wakeSettings,'-ConfigPath',$ConfigPath)
        if (Test-ProofOnly) { $wakeArgs += '-VerifyOnly' }
        $wakeProcess = Start-Process -FilePath $ps -ArgumentList $wakeArgs -WindowStyle Hidden -Wait -PassThru
        Write-ActionLog "WAKE_SETTINGS_REPAIR_RESULT exit=$($wakeProcess.ExitCode)"
        if ($wakeProcess.ExitCode -ne 0) { exit $wakeProcess.ExitCode }
    }
    'refresh_gpu' {
        Invoke-RefreshGpuDriver
    }
    'explorer_refresh_gpu' {
        Invoke-ExplorerRefreshGpu
    }
    'moonlight_toggle' {
        Invoke-MoonlightToggle
    }
    'moonlight_prepare' {
        Invoke-MoonlightPrepare
    }
    'youtube_tizen' {
        Invoke-YoutubeTizen
    }
    { $_ -in @('open_stremio_tv','open_stremio') } {
        Invoke-StremioTv
    }
    'tv_power_toggle' {
        Invoke-SamsungTvRemoteKey -ActionName $Action -Key 'KEY_POWER'
    }
    'tv_force_reboot' {
        Invoke-SamsungTvSdbReboot -ActionName $Action
    }
    'tv_mute' {
        Invoke-SamsungTvRemoteKey -ActionName $Action -Key 'KEY_MUTE'
    }
    'tv_volume_up' {
        Invoke-SamsungTvRemoteKey -ActionName $Action -Key 'KEY_VOLUP'
    }
    'tv_volume_down' {
        Invoke-SamsungTvRemoteKey -ActionName $Action -Key 'KEY_VOLDOWN'
    }
    { $_ -like 'tv_set_volume:*' } {
        $rawVolume = $Action.Substring('tv_set_volume:'.Length)
        $volume = 0
        if (-not [int]::TryParse($rawVolume, [ref]$volume)) {
            Write-ActionLog "SAMSUNG_TV_SET_VOLUME_PARSE_FAILED raw=$rawVolume"
            exit 2
        }
        Invoke-SamsungTvSetVolume -Volume $volume
    }
    'tv_home' {
        Invoke-SamsungTvRemoteKey -ActionName $Action -Key 'KEY_HOME'
    }
    'open_admin_terminal' {
        Invoke-AdminTerminal
    }
    { $_ -like 'terminal_line:*' } {
        Invoke-TerminalLine -EncodedLine ($Action.Substring('terminal_line:'.Length))
    }
    'refresh2_logoff' {
        Invoke-Refresh2Logoff
    }
    'shutdown_pc' {
        Invoke-Executable -FilePath $shutdown -Arguments @('/s','/f','/t','0','/c',"RemoteCommandCenter shutdown nonce=$Nonce")
    }
    'restart_explorer' {
        Invoke-RestartExplorer
    }
    'restart_codex' {
        $restartCodex = Join-Path $PSScriptRoot 'Restart-CodexDesktopApp.ps1'
        Write-ActionLog "RESTART_CODEX_READY helper=`"$restartCodex`" exists=$(Test-Path -LiteralPath $restartCodex -PathType Leaf)"
        if (-not (Test-Path -LiteralPath $restartCodex -PathType Leaf)) { exit 5 }
        $restartArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$restartCodex)
        if (Test-ProofOnly) { $restartArgs += '-ProbeOnly' }
        $restartProcess = Start-Process -FilePath $ps -ArgumentList $restartArgs -WindowStyle Hidden -Wait -PassThru
        Write-ActionLog "RESTART_CODEX_RESULT exit=$($restartProcess.ExitCode)"
        if ($restartProcess.ExitCode -ne 0) { exit $restartProcess.ExitCode }
    }
    'open_wand_wemod' {
        Invoke-WandToggle
    }
    'toggle_openspeedy' {
        Invoke-OpenSpeedyToggle
    }
    'toggle_qbittorrent' {
        Invoke-QBittorrentToggle
    }
    'reboot_to_bios' {
        Invoke-RebootToFirmware
    }
    'night_mode_toggle' {
        Write-ActionLog 'NIGHT_MODE_TOGGLE_READY mode=auto'
        Invoke-NightModeUiToggle
    }
    default {
        Write-ActionLog "UNKNOWN_ACTION action=$Action"
        exit 2
    }
}

Write-ActionLog "RCC_ACTION_DONE action=$actionLogLabel"
exit 0
