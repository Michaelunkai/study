Set-StrictMode -Version 2.0

function New-HarnessDirectory {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-HarnessStatus {
    param(
        [Parameter(Mandatory=$true)][string]$StatusPath,
        [Parameter(Mandatory=$true)][hashtable]$Data
    )

    $Data.generated_at = (Get-Date).ToString('o')
    $json = $Data | ConvertTo-Json -Depth 8
    Set-Content -LiteralPath $StatusPath -Value $json -Encoding UTF8
}

function Add-HarnessLog {
    param(
        [Parameter(Mandatory=$true)][string]$LogPath,
        [Parameter(Mandatory=$true)][string]$Message
    )

    $line = '{0} {1}' -f (Get-Date).ToString('o'), $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    Write-Host $Message
}

function Import-HarnessHyperV {
    if ([string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
        $hostName = [System.Net.Dns]::GetHostName()
        if ([string]::IsNullOrWhiteSpace($hostName)) {
            $hostName = (& hostname.exe)
        }
        $env:COMPUTERNAME = $hostName
    }

    $moduleRoot = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\Modules'
    if ($env:PSModulePath -notlike "*$moduleRoot*") {
        $env:PSModulePath = $moduleRoot + ';' + $env:PSModulePath
    }

    Import-Module Hyper-V -ErrorAction Stop
}

function Get-HarnessVmConnectPath {
    $candidate = Join-Path $env:WINDIR 'System32\vmconnect.exe'
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    $command = Get-Command vmconnect.exe -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    throw 'vmconnect.exe was not found. Hyper-V console cannot be opened automatically.'
}

function Invoke-HarnessVmConnectDialog {
    param([Parameter(Mandatory=$true)][string]$Name)

    try {
        Add-Type -AssemblyName UIAutomationClient
        $root = [System.Windows.Automation.AutomationElement]::RootElement
        $windowCondition = New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::NameProperty,
            "$Name on localhost - Virtual Machine Connection"
        )
        $window = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $windowCondition)
        if (-not $window) { return }

        $connectCondition = New-Object System.Windows.Automation.PropertyCondition(
            [System.Windows.Automation.AutomationElement]::NameProperty,
            'Connect'
        )
        $connect = $window.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $connectCondition)
        if (-not $connect) { return }

        $pattern = $null
        if ($connect.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$pattern)) {
            $pattern.Invoke()
        }
    } catch {
        # VMConnect may already be connected or UIAutomation may not expose the dialog; keep the launcher non-fatal here.
    }
}

function Assert-HarnessHostReady {
    param(
        [Parameter(Mandatory=$true)][string]$ParentVhd,
        [Parameter(Mandatory=$true)][string]$LogPath
    )

    if (-not (Test-Path -LiteralPath $ParentVhd)) {
        throw "Parent VHDX was not found: $ParentVhd"
    }

    $services = Get-Service -Name vmms,vmcompute,hvhost -ErrorAction Stop
    foreach ($service in $services) {
        if ($service.Status -ne 'Running') {
            Add-HarnessLog -LogPath $LogPath -Message "Starting Hyper-V service $($service.Name)."
            Start-Service -Name $service.Name -ErrorAction Stop
        }
    }

    $computer = Get-CimInstance Win32_ComputerSystem
    if (-not $computer.HypervisorPresent) {
        throw 'HypervisorPresent is false. Hyper-V cannot start a VM until host virtualization is active.'
    }
}

function Resolve-HarnessParentVhd {
    param([string]$RequestedParentVhd)

    if (-not [string]::IsNullOrWhiteSpace($RequestedParentVhd) -and (Test-Path -LiteralPath $RequestedParentVhd)) {
        $resolvedRequested = (Resolve-Path -LiteralPath $RequestedParentVhd).ProviderPath
        if ([System.IO.Path]::GetExtension($resolvedRequested) -notmatch '^\.(vhdx|vhd)$') {
            throw "Parent disk must be a .vhdx or .vhd file, not: $resolvedRequested"
        }
        return $resolvedRequested
    }

    $candidatePaths = @(
        'F:\Downloads\VMREplica\VHDX\VMReplica-CurrentWindows.VHDX',
        'F:\Downloads\VMREplica\VHDX\VMReplica-CurrentWindows.vhdx',
        'F:\Downloads\VMReplica-CurrentWindows.VHDX',
        'F:\Downloads\VMReplica-CurrentWindows.vhdx',
        'E:\VMReplica-CurrentWindows.VHDX',
        'E:\VMReplica-CurrentWindows.vhdx',
        'C:\Users\micha\Downloads\VMReplica-CurrentWindows.VHDX',
        'C:\Users\micha\Downloads\VMReplica-CurrentWindows.vhdx'
    )

    foreach ($path in $candidatePaths) {
        if (Test-Path -LiteralPath $path) {
            return (Resolve-Path -LiteralPath $path).ProviderPath
        }
    }

    $searchRoots = @('F:\Downloads', 'C:\Users\micha\Downloads', 'E:\')
    foreach ($root in $searchRoots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        $candidate = Get-ChildItem -LiteralPath $root -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Extension -match '^\.(vhdx|vhd)$' -and
                $_.Length -gt 20GB -and
                $_.Name -match '(?i)win|windows|replica|current'
            } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    $message = @(
        'No parent Windows VHD/VHDX was found.',
        'Put the parent disk back at:',
        '  F:\Downloads\VMREplica\VHDX\VMReplica-CurrentWindows.VHDX',
        'or run Start-Win11VM.ps1 -ParentVhd <full-path-to-windows-vhdx>.',
        'Cleanup never removes that parent path; it only removes this project''s generated vm/log/state folders.'
    ) -join [Environment]::NewLine
    throw $message
}

function Ensure-HarnessNetworkSwitch {
    param(
        [Parameter(Mandatory=$true)][string]$SwitchName,
        [Parameter(Mandatory=$true)][string]$LogPath
    )

    $switch = Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue
    if ($switch) {
        return $switch
    }

    if ($SwitchName -eq 'Codex External Ethernet') {
        $adapter = Get-NetAdapter -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq 'Ethernet' -and $_.Status -eq 'Up' } |
            Select-Object -First 1
        if ($adapter) {
            Add-HarnessLog -LogPath $LogPath -Message "Creating external Hyper-V switch '$SwitchName' on adapter '$($adapter.Name)'."
            New-VMSwitch -Name $SwitchName -NetAdapterName $adapter.Name -AllowManagementOS $true | Out-Null
            Start-Sleep -Seconds 8
            return Get-VMSwitch -Name $SwitchName
        }
    }

    $fallback = Get-VMSwitch -Name 'Default Switch' -ErrorAction SilentlyContinue
    if ($fallback) {
        Add-HarnessLog -LogPath $LogPath -Message "Requested switch '$SwitchName' was not available; using Default Switch."
        return $fallback
    }

    $fallback = Get-VMSwitch | Select-Object -First 1
    if ($fallback) {
        Add-HarnessLog -LogPath $LogPath -Message "Requested switch '$SwitchName' was not available; using '$($fallback.Name)'."
        return $fallback
    }

    throw 'No Hyper-V virtual switch was found.'
}

function Ensure-HarnessDifferencingDisk {
    param(
        [Parameter(Mandatory=$true)][string]$ParentVhd,
        [Parameter(Mandatory=$true)][string]$ChildVhd,
        [Parameter(Mandatory=$true)][string]$LogPath
    )

    if (Test-Path -LiteralPath $ChildVhd) {
        Add-HarnessLog -LogPath $LogPath -Message "Using existing differencing disk: $ChildVhd"
        return
    }

    Add-HarnessLog -LogPath $LogPath -Message "Creating differencing disk from parent replica: $ChildVhd"
    New-VHD -Path $ChildVhd -ParentPath $ParentVhd -Differencing | Out-Null
}

function Ensure-HarnessVm {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$VhdPath,
        [Parameter(Mandatory=$true)][string]$VmRoot,
        [Parameter(Mandatory=$true)][string]$SwitchName,
        [Parameter(Mandatory=$true)][int64]$MemoryStartupBytes,
        [Parameter(Mandatory=$true)][int]$ProcessorCount,
        [Parameter(Mandatory=$true)][string]$LogPath
    )

    $vm = Get-VM -Name $Name -ErrorAction SilentlyContinue
    if (-not $vm) {
        Add-HarnessLog -LogPath $LogPath -Message "Creating VM '$Name' from $VhdPath."
        $switch = Ensure-HarnessNetworkSwitch -SwitchName $SwitchName -LogPath $LogPath
        $vm = New-VM -Name $Name -Generation 2 -MemoryStartupBytes $MemoryStartupBytes -VHDPath $VhdPath -Path $VmRoot -SwitchName $switch.Name
    } else {
        Add-HarnessLog -LogPath $LogPath -Message "Using existing VM '$Name'."
        $switch = Ensure-HarnessNetworkSwitch -SwitchName $SwitchName -LogPath $LogPath
        $adapter = Get-VMNetworkAdapter -VMName $Name | Select-Object -First 1
        if ($adapter -and $adapter.SwitchName -ne $switch.Name) {
            Add-HarnessLog -LogPath $LogPath -Message "Connecting VM network adapter to '$($switch.Name)'."
            Connect-VMNetworkAdapter -VMName $Name -SwitchName $switch.Name
        }
    }

    Set-VM -Name $Name -AutomaticCheckpointsEnabled $false
    Set-VMProcessor -VMName $Name -Count $ProcessorCount
    Set-VMMemory -VMName $Name -StartupBytes $MemoryStartupBytes -DynamicMemoryEnabled $true -MinimumBytes 2GB -MaximumBytes 16GB

    $currentVm = Get-VM -Name $Name
    if ($currentVm.State -eq 'Off') {
        try {
            Set-VMFirmware -VMName $Name -EnableSecureBoot On -SecureBootTemplate 'MicrosoftWindows'
        } catch {
            Add-HarnessLog -LogPath $LogPath -Message "Secure Boot configuration warning: $($_.Exception.Message)"
        }

        try {
            Set-VMKeyProtector -VMName $Name -NewLocalKeyProtector
            Enable-VMTPM -VMName $Name
        } catch {
            Add-HarnessLog -LogPath $LogPath -Message "TPM configuration warning: $($_.Exception.Message)"
        }
    } else {
        Add-HarnessLog -LogPath $LogPath -Message "Skipping firmware/TPM changes because VM '$Name' is already $($currentVm.State)."
    }

    return Get-VM -Name $Name
}

function Start-HarnessVmAndConsole {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$LogPath
    )

    $vm = Get-VM -Name $Name -ErrorAction Stop
    if ($vm.State -ne 'Running') {
        Add-HarnessLog -LogPath $LogPath -Message "Starting VM '$Name'."
        Start-VM -Name $Name -ErrorAction Stop
    } else {
        Add-HarnessLog -LogPath $LogPath -Message "VM '$Name' is already running."
    }

    $deadline = (Get-Date).AddMinutes(5)
    do {
        Start-Sleep -Seconds 2
        $vm = Get-VM -Name $Name
        if ($vm.State -eq 'Running') {
            break
        }
    } while ((Get-Date) -lt $deadline)

    if ($vm.State -ne 'Running') {
        throw "VM '$Name' did not reach Running state. Current state: $($vm.State)"
    }

    $heartbeatReady = $false
    $heartbeatDeadline = (Get-Date).AddMinutes(5)
    do {
        $heartbeat = Get-VMIntegrationService -VMName $Name -Name 'Heartbeat' -ErrorAction SilentlyContinue
        if ($heartbeat -and $heartbeat.PrimaryStatusDescription -eq 'OK') {
            $heartbeatReady = $true
            break
        }
        Start-Sleep -Seconds 5
        $vm = Get-VM -Name $Name
        if ($vm.State -ne 'Running') {
            throw "VM '$Name' stopped before guest heartbeat became ready. Current state: $($vm.State)"
        }
    } while ((Get-Date) -lt $heartbeatDeadline)

    if (-not $heartbeatReady) {
        throw "VM '$Name' is running, but guest heartbeat did not become OK before timeout."
    }

    $vmConnect = Get-HarnessVmConnectPath
    $existingConsole = Get-Process -Name vmconnect -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -like "*$Name*" } |
        Select-Object -First 1
    if ($existingConsole) {
        Add-HarnessLog -LogPath $LogPath -Message "VM console is already open with process id $($existingConsole.Id)."
        return @{
            vm = $vm
            vmconnect_process_id = $existingConsole.Id
            vmconnect_path = $vmConnect
        }
    }

    Add-HarnessLog -LogPath $LogPath -Message "Opening VM console with vmconnect.exe."
    Start-Process -FilePath $vmConnect -ArgumentList @('localhost', $Name) -WindowStyle Normal | Out-Null
    Start-Sleep -Seconds 2
    Invoke-HarnessVmConnectDialog -Name $Name

    $consoleProcess = $null
    $consoleDeadline = (Get-Date).AddSeconds(25)
    do {
        $consoleProcess = Get-Process -Name vmconnect -ErrorAction SilentlyContinue |
            Where-Object { $_.MainWindowTitle -like "*$Name*" } |
            Select-Object -First 1
        if ($consoleProcess) { break }
        Start-Sleep -Seconds 1
        Invoke-HarnessVmConnectDialog -Name $Name
    } while ((Get-Date) -lt $consoleDeadline)
    if (-not $consoleProcess) {
        throw 'VMConnect did not remain running after launch.'
    }

    return @{
        vm = $vm
        vmconnect_process_id = $consoleProcess.Id
        vmconnect_path = $vmConnect
    }
}

function Get-HarnessGuestKvp {
    param([Parameter(Mandatory=$true)][string]$VmId)

    $items = @{}
    $component = Get-CimInstance -Namespace root\virtualization\v2 -ClassName Msvm_KvpExchangeComponent -ErrorAction SilentlyContinue |
        Where-Object { $_.SystemName -eq $VmId -or $_.SystemName -eq $VmId.ToUpper() } |
        Select-Object -First 1

    if (-not $component) {
        return $items
    }

    foreach ($item in $component.GuestIntrinsicExchangeItems) {
        [xml]$xml = $item
        $name = ($xml.INSTANCE.PROPERTY | Where-Object NAME -eq 'Name' | Select-Object -ExpandProperty VALUE)
        $data = ($xml.INSTANCE.PROPERTY | Where-Object NAME -eq 'Data' | Select-Object -ExpandProperty VALUE)
        if ($name) {
            $items[$name] = $data
        }
    }

    return $items
}

function Get-HarnessWindowsBuild {
    param([Parameter(Mandatory=$true)][hashtable]$GuestKvp)

    if ($GuestKvp.ContainsKey('OSVersion')) {
        $parts = ([string]$GuestKvp.OSVersion).Split('.')
        if ($parts.Count -ge 3) {
            $versionBuild = 0
            if ([int]::TryParse($parts[2], [ref]$versionBuild)) {
                return $versionBuild
            }
        }
    }

    if ($GuestKvp.ContainsKey('OSBuildNumber')) {
        $build = 0
        if ([int]::TryParse([string]$GuestKvp.OSBuildNumber, [ref]$build)) {
            return $build
        }
    }

    return 0
}

function Start-Win11ReadyVm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$ParentVhd = '',
        [Parameter(Mandatory=$true)][string]$VmRoot,
        [Parameter(Mandatory=$true)][string]$SwitchName,
        [Parameter(Mandatory=$true)][int64]$MemoryStartupBytes,
        [Parameter(Mandatory=$true)][int]$ProcessorCount,
        [switch]$Preflight
    )

    $projectRoot = Split-Path -Parent $PSScriptRoot
    $logs = Join-Path $projectRoot 'logs'
    $state = Join-Path $projectRoot 'state'
    New-HarnessDirectory -Path $logs
    New-HarnessDirectory -Path $state
    New-HarnessDirectory -Path $VmRoot

    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $logPath = Join-Path $logs "win11vm-$stamp.log"
    $latestLogPath = Join-Path $logs 'latest.log'
    $statusPath = Join-Path $state 'latest-status.json'
    $childVhd = Join-Path $VmRoot "$Name-diff.vhdx"

    try {
        Add-HarnessLog -LogPath $logPath -Message "Starting Win11 VM harness for '$Name'."
        Import-HarnessHyperV
        $ParentVhd = Resolve-HarnessParentVhd -RequestedParentVhd $ParentVhd
        Assert-HarnessHostReady -ParentVhd $ParentVhd -LogPath $logPath

        if ($Preflight) {
            $switches = @(Get-VMSwitch | Select-Object -ExpandProperty Name)
            Write-HarnessStatus -StatusPath $statusPath -Data @{
                success = $true
                mode = 'preflight'
                vm_name = $Name
                parent_vhd = $ParentVhd
                planned_child_vhd = $childVhd
                switches = $switches
                vmconnect = (Get-HarnessVmConnectPath)
            }
            Copy-Item -LiteralPath $logPath -Destination $latestLogPath -Force
            Add-HarnessLog -LogPath $logPath -Message 'Preflight passed.'
            return @{ Success = $true; Mode = 'preflight'; LogPath = $logPath; StatusPath = $statusPath }
        }

        Ensure-HarnessDifferencingDisk -ParentVhd $ParentVhd -ChildVhd $childVhd -LogPath $logPath
        $vm = Ensure-HarnessVm -Name $Name -VhdPath $childVhd -VmRoot $VmRoot -SwitchName $SwitchName -MemoryStartupBytes $MemoryStartupBytes -ProcessorCount $ProcessorCount -LogPath $logPath
        $opened = Start-HarnessVmAndConsole -Name $Name -LogPath $logPath
        $vm = Get-VM -Name $Name
        $guestKvp = Get-HarnessGuestKvp -VmId $vm.Id.ToString()
        $guestBuild = Get-HarnessWindowsBuild -GuestKvp $guestKvp
        $isWindows11Build = $guestBuild -ge 22000

        $data = @{
            success = $true
            mode = 'start'
            vm_name = $Name
            vm_id = $vm.Id.ToString()
            vm_state = $vm.State.ToString()
            vm_generation = $vm.Generation
            vm_path = $vm.Path
            parent_vhd = $ParentVhd
            child_vhd = $childVhd
            memory_startup_bytes = $MemoryStartupBytes
            processor_count = $ProcessorCount
            vmconnect_process_id = $opened.vmconnect_process_id
            vmconnect_path = $opened.vmconnect_path
            guest_os_name = if ($guestKvp.ContainsKey('OSName')) { $guestKvp.OSName } else { $null }
            guest_os_version = if ($guestKvp.ContainsKey('OSVersion')) { $guestKvp.OSVersion } else { $null }
            guest_os_build_number = if ($guestKvp.ContainsKey('OSBuildNumber')) { $guestKvp.OSBuildNumber } else { $null }
            guest_os_version_build = $guestBuild
            guest_windows11_build = $isWindows11Build
            log_path = $logPath
        }
        Write-HarnessStatus -StatusPath $statusPath -Data $data
        Copy-Item -LiteralPath $logPath -Destination $latestLogPath -Force
        Add-HarnessLog -LogPath $logPath -Message "SUCCESS: VM '$Name' is Running and VMConnect opened."
        return @{ Success = $true; LogPath = $logPath; StatusPath = $statusPath; Data = $data }
    } catch {
        $message = $_.Exception.Message
        Add-HarnessLog -LogPath $logPath -Message "FAILED: $message"
        Write-HarnessStatus -StatusPath $statusPath -Data @{
            success = $false
            vm_name = $Name
            parent_vhd = $ParentVhd
            child_vhd = $childVhd
            error = $message
            log_path = $logPath
        }
        Copy-Item -LiteralPath $logPath -Destination $latestLogPath -Force
        Write-Error $message
        return @{ Success = $false; Error = $message; LogPath = $logPath; StatusPath = $statusPath }
    }
}

function Test-Win11ReadyVm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$ProjectRoot
    )

    $logs = Join-Path $ProjectRoot 'logs'
    $state = Join-Path $ProjectRoot 'state'
    New-HarnessDirectory -Path $logs
    New-HarnessDirectory -Path $state
    $logPath = Join-Path $logs ('verify-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $statusPath = Join-Path $state 'verify-status.json'

    try {
        Import-HarnessHyperV
        $vm = Get-VM -Name $Name -ErrorAction Stop
        $consoleProcess = Get-Process -Name vmconnect -ErrorAction SilentlyContinue | Select-Object -First 1
        $heartbeat = Get-VMIntegrationService -VMName $Name -Name 'Heartbeat' -ErrorAction SilentlyContinue
        $guestKvp = Get-HarnessGuestKvp -VmId $vm.Id.ToString()
        $guestBuild = Get-HarnessWindowsBuild -GuestKvp $guestKvp
        $isWindows11Build = $guestBuild -ge 22000
        $success = ($vm.State -eq 'Running' -and $null -ne $consoleProcess -and $heartbeat -and $heartbeat.PrimaryStatusDescription -eq 'OK' -and $isWindows11Build)
        $data = @{
            success = $success
            vm_name = $Name
            vm_id = $vm.Id.ToString()
            vm_state = $vm.State.ToString()
            vm_generation = $vm.Generation
            vm_path = $vm.Path
            heartbeat = if ($heartbeat) { $heartbeat.PrimaryStatusDescription } else { $null }
            guest_os_name = if ($guestKvp.ContainsKey('OSName')) { $guestKvp.OSName } else { $null }
            guest_os_version = if ($guestKvp.ContainsKey('OSVersion')) { $guestKvp.OSVersion } else { $null }
            guest_os_build_number = if ($guestKvp.ContainsKey('OSBuildNumber')) { $guestKvp.OSBuildNumber } else { $null }
            guest_os_version_build = $guestBuild
            guest_windows11_build = $isWindows11Build
            vmconnect_process_id = if ($consoleProcess) { $consoleProcess.Id } else { $null }
        }
        Write-HarnessStatus -StatusPath $statusPath -Data $data
        Add-HarnessLog -LogPath $logPath -Message ("Verification success: {0}" -f $success)
        if (-not $success) {
            Write-Error "VM '$Name' is not Running with OK heartbeat, an open VMConnect console, and Windows 11 build proof."
        }
        return @{ Success = $success; Data = $data; LogPath = $logPath; StatusPath = $statusPath }
    } catch {
        Write-HarnessStatus -StatusPath $statusPath -Data @{
            success = $false
            vm_name = $Name
            error = $_.Exception.Message
        }
        Add-HarnessLog -LogPath $logPath -Message "Verification failed: $($_.Exception.Message)"
        Write-Error $_.Exception.Message
        return @{ Success = $false; Error = $_.Exception.Message; LogPath = $logPath; StatusPath = $statusPath }
    }
}
