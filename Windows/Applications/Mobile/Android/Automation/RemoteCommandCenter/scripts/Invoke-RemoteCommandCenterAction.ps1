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
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
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
    $allowStandby = 'abfc2519-3608-4c2a-94ea-171b0ed546ab'
    $wakeTimers = 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d'
    $remoteFileSleep = 'd4c1d4c8-d5cc-43d3-b83e-fc51215cb04d'
    $unattendedSleepTimeout = '7bc4a2f9-d8fc-4469-b07b-33eb785aaca0'

    foreach ($setting in @($allowStandby, $wakeTimers, $remoteFileSleep)) {
        & $powercfg /setacvalueindex $scheme $subSleep $setting 1 | Out-Null
        Write-ActionLog "POWER_POLICY_SET scheme=$scheme ac setting=$setting exit=$LASTEXITCODE"
        & $powercfg /setdcvalueindex $scheme $subSleep $setting 1 | Out-Null
        Write-ActionLog "POWER_POLICY_SET scheme=$scheme dc setting=$setting exit=$LASTEXITCODE"
    }
    & $powercfg /setacvalueindex $scheme $subSleep $unattendedSleepTimeout 0 | Out-Null
    Write-ActionLog "POWER_POLICY_SET scheme=$scheme ac setting=$unattendedSleepTimeout value=0 exit=$LASTEXITCODE"
    & $powercfg /setdcvalueindex $scheme $subSleep $unattendedSleepTimeout 0 | Out-Null
    Write-ActionLog "POWER_POLICY_SET scheme=$scheme dc setting=$unattendedSleepTimeout value=0 exit=$LASTEXITCODE"
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
                @{ DisplayName = 'WOL & Shutdown Link Speed'; DisplayValue = '10 Mbps First' },
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
    $masterChief = 'F:\study\Windows\Applications\Mobile\Android\Automation\MasterChiefRescue\scripts\Invoke-MasterChiefRescue.ps1'
    Write-ActionLog "UNFREEZE_READY method=MasterChiefRescuePlusFastPulse script=`"$masterChief`" exists=$(Test-Path -LiteralPath $masterChief)"
    if (Test-ProofOnly) {
        Write-ActionLog 'PROOF_ONLY active; unfreeze rescue was not executed.'
        return
    }
    if (-not (Test-Path -LiteralPath $masterChief)) {
        Write-ActionLog 'UNFREEZE_SCRIPT_MISSING'
        exit 7
    }
    Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$masterChief,'-NoReboot','-Reason',"RemoteCommandCenter unfreeze nonce=$Nonce") -WindowStyle Hidden | Out-Null
    Write-ActionLog 'UNFREEZE_STARTED'
}

function Invoke-OpenSpeedyToggle {
    Invoke-AppWindowToggle -Name 'OpenSpeedy' -ProcessName 'Speedy' -ExePath 'F:\backup\windowsapps\installed\OpenSpeedy\Speedy.exe' -MarkerName 'openspeedy-visible.txt' -PreferTitle @('Speedy') -RejectTitle @('QTrayIconMessageWindow','Default IME','MSCTFIME UI') -RejectClass @('QTrayIconMessageWindow','IME','MSCTF')
}

function Invoke-WandToggle {
    Invoke-AppWindowToggle -Name 'Wand' -ProcessName 'Wand' -ExePath 'C:\Users\micha\AppData\Local\Wand\Wand.exe' -MarkerName 'wand-visible.txt' -PreferTitle @('Wand') -RejectTitle @('QTrayIconMessageWindow') -RejectClass @('QTrayIconMessageWindow')
}

function Invoke-QBittorrentToggle {
    Invoke-AppWindowToggle -Name 'qBittorrent' -ProcessName 'qbittorrent' -ExePath 'C:\Program Files\qBittorrent\qbittorrent.exe' -MarkerName 'qbittorrent-visible.txt' -PreferTitle @('qBittorrent') -RejectTitle @('QTrayIconMessageWindow') -RejectClass @('QTrayIconMessageWindow')
    $fitGirlAutoInstall = 'F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\dist\FitGirlAutoInstall.exe'
    $fitGirlInstallScript = 'F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\install.ps1'
    $fitGirlProjectRoot = Split-Path -Parent $fitGirlInstallScript
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
        [string[]]$RejectClass = @()
    )
    $marker = Join-Path $stateDir $MarkerName
    Write-ActionLog "$($Name.ToUpperInvariant())_TOGGLE_READY exe=`"$ExePath`" exists=$(Test-Path -LiteralPath $ExePath)"
    if (Test-ProofOnly) {
        Write-ActionLog "PROOF_ONLY active; $Name window was not toggled."
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
    [DllImport("user32.dll")] public static extern int GetClassName(IntPtr hWnd, StringBuilder className, int count);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
}
'@ -ErrorAction SilentlyContinue
    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Sort-Object MainWindowHandle -Descending | Select-Object -First 1
    if (-not $proc -and (Test-Path -LiteralPath $ExePath)) {
        Start-Process -FilePath $ExePath | Out-Null
        Start-Sleep -Milliseconds 900
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
    if ($selected.Count -eq 0) {
        Write-ActionLog "$($Name.ToUpperInvariant())_REAL_WINDOW_NOT_FOUND processCount=$($processes.Count)"
        exit 6
    }
    $hwndTopMost = [IntPtr](-1)
    $swpNoMoveNoSizeShow = [uint32]0x0043
    if (Test-Path -LiteralPath $marker) {
        foreach ($w in $selected) { [void][RccWindowOps]::ShowWindow($w.Handle, 0) }
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
        Write-ActionLog "$($Name.ToUpperInvariant())_HIDDEN windows=$($selected.Count) titles=`"$((@($selected | Select-Object -ExpandProperty Title) -join '|'))`""
    } else {
        foreach ($w in $selected) {
            [void][RccWindowOps]::ShowWindow($w.Handle, 9)
            [void][RccWindowOps]::SetWindowPos($w.Handle, $hwndTopMost, 0, 0, 0, 0, $swpNoMoveNoSizeShow)
            [void][RccWindowOps]::SetForegroundWindow($w.Handle)
        }
        Set-Content -LiteralPath $marker -Value ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()) -Encoding ASCII
        Write-ActionLog "$($Name.ToUpperInvariant())_SHOWN_TOPMOST windows=$($selected.Count) titles=`"$((@($selected | Select-Object -ExpandProperty Title) -join '|'))`""
    }
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

$system32 = Join-Path $env:SystemRoot 'System32'
$shutdown = Join-Path $system32 'shutdown.exe'
$rundll32 = Join-Path $system32 'rundll32.exe'
$tsdiscon = Join-Path $system32 'tsdiscon.exe'
$ps = Join-Path $system32 'WindowsPowerShell\v1.0\powershell.exe'

Write-ActionLog "RCC_ACTION_START action=$Action nonce=$Nonce proofOnly=$(Test-ProofOnly)"

switch ($Action) {
    'force_reboot_now' {
        Invoke-Executable -FilePath $shutdown -Arguments @('/r','/f','/t','0','/c',"RemoteCommandCenter force reboot nonce=$Nonce")
    }
    { $_ -in @('sleep_pc','sleep_toggle') } {
        Remove-Item -LiteralPath (Join-Path $stateDir 'sleep-toggle-state.txt') -Force -ErrorAction SilentlyContinue
        $standbyReady = $false
        for ($attempt = 1; $attempt -le 4; $attempt++) {
            Prepare-WakeableSuspend
            $standbyReady = Test-StandbyAvailable
            Write-ActionLog "SLEEP_STANDBY_CHECK attempt=$attempt ready=$standbyReady"
            if ($standbyReady) { break }
            Start-Sleep -Milliseconds 350
        }
        if ($standbyReady) {
            Invoke-SleepNow
        } else {
            Write-ActionLog 'SLEEP_UNAVAILABLE_FALLBACK_HIBERNATE reason=no Windows standby state is available on this PC'
            if (-not (Test-ProofOnly)) {
                & (Join-Path $system32 'powercfg.exe') /hibernate on | Out-Null
                & (Join-Path $system32 'powercfg.exe') /hibernate /type full | Out-Null
            }
            Invoke-Executable -FilePath $shutdown -Arguments @('/h')
        }
    }
    { $_ -in @('hibernate_pc','hibernate_toggle') } {
        Remove-Item -LiteralPath (Join-Path $stateDir 'hibernate-toggle-state.txt') -Force -ErrorAction SilentlyContinue
        Prepare-WakeableSuspend
        if (-not (Test-ProofOnly)) {
            & (Join-Path $system32 'powercfg.exe') /hibernate on | Out-Null
            & (Join-Path $system32 'powercfg.exe') /hibernate /type full | Out-Null
        }
        Invoke-Executable -FilePath $shutdown -Arguments @('/h')
    }
    'wake_pc' {
        Write-ActionLog 'WAKE_PC_NOOP_READY note=Android Wake button sends Wake-on-LAN directly and intentionally does not send a PC sleep/hibernate command.'
    }
    'shutdown_pc' {
        Invoke-Executable -FilePath $shutdown -Arguments @('/s','/f','/t','0','/c',"RemoteCommandCenter shutdown nonce=$Nonce")
    }
    'restart_explorer' {
        Write-ActionLog 'RESTART_EXPLORER_READY'
        if (-not (Test-ProofOnly)) {
            Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Process explorer.exe | Out-Null
        }
    }
    'restart_codex' {
        Write-ActionLog 'RESTART_CODEX_READY'
        if (-not (Test-ProofOnly)) {
            Get-Process -Name 'codex','Codex' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath 'codex' -ErrorAction SilentlyContinue | Out-Null
        }
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

Write-ActionLog "RCC_ACTION_DONE action=$Action"
exit 0
