param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AadbArgs
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

trap {
    $line = if ($null -ne $_ -and $null -ne $_.InvocationInfo) { $_.InvocationInfo.ScriptLineNumber } else { 'unknown' }
    $message = if ($null -ne $_ -and $null -ne $_.Exception) { $_.Exception.Message } else { 'unknown error' }
    Write-Host "AADB ERROR line ${line}: $message" -ForegroundColor Red
    if ($null -ne $_ -and $_.ScriptStackTrace) {
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    }
    throw $_
}

$DefaultApk = 'F:\study\repos\fullstack\todoist-enhanced\c\todoist-enhanced-private-android-output\app\build\outputs\apk\debug\app-debug.apk'
$ConfigDir = Join-Path $env:APPDATA 'CodexAdb'
$ConfigPath = Join-Path $ConfigDir 'wireless-adb.json'
$InstalledScriptPath = Join-Path $ConfigDir 'Invoke-AndroidAdbBridge.ps1'
$UserBinDir = Join-Path $HOME 'bin'
$ShimPath = Join-Path $UserBinDir 'aadb.ps1'
$ShortShimPath = Join-Path $UserBinDir 'aad.ps1'
$PlatformRoot = Join-Path $env:LOCALAPPDATA 'Android'
$PlatformTools = Join-Path $PlatformRoot 'platform-tools'
$Adb = Join-Path $PlatformTools 'adb.exe'

function Write-AadbHelp {
    Write-Host 'aadb commands:' -ForegroundColor Cyan
    Write-Host '  aadb setup                         Print Android steps, pair once, save endpoint.'
    Write-Host '  aadb repair                        Force pairing repair now.'
    Write-Host '  aadb connect                       Auto-connect; if unreachable, start pairing repair.'
    Write-Host '  aadb apk                           Install default APK and copy it to /sdcard/Download.'
    Write-Host '  aadb push                          Copy current PC folder to /sdcard/Download.'
    Write-Host '  aadb push <pcPath> [androidPath]   Copy PC file/folder to Android.'
    Write-Host '  aadb pull                          Browse Android from /home, then pull selection here.'
    Write-Host '  aadb pull DCIM                     Copy /sdcard/DCIM to current PC folder.'
    Write-Host '  aadb pull <pcFolder>               Copy /sdcard/DCIM to that PC folder.'
    Write-Host '  aadb pull <androidPath> [pcPath]   Copy Android file/folder to PC.'
    Write-Host '  aadb persist                       Reinstall PATH and logon auto-connect persistence.'
    Write-Host '  aadb shell <command...>            Auto-connect, then run adb shell.'
    Write-Host '  aadb devices                       Show adb devices.'
    Write-Host '  aadb steps                         Print Android setup steps only.'
    Write-Host '  aadb path                          Show script, config, and adb paths.'
    Write-Host '  aadb <any adb args...>             Auto-connect, then pass arguments to adb.'
    Write-Host '  aad <same args>                    Short alias for aadb.'
}

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

function Ensure-Adb {
    if (Test-Path -LiteralPath $Adb) {
        return
    }

    Ensure-Directory $PlatformRoot
    $zip = Join-Path $env:TEMP 'platform-tools-latest-windows.zip'
    Write-Host 'Downloading official Google Android platform-tools...' -ForegroundColor Cyan
    Invoke-WebRequest -UseBasicParsing 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $zip
    Expand-Archive -Force $zip $PlatformRoot

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($userPath -split ';' | Where-Object { $_ })
    if ($parts -notcontains $PlatformTools) {
        [Environment]::SetEnvironmentVariable('Path', (($parts + $PlatformTools | Select-Object -Unique) -join ';'), 'User')
    }
}

function Load-Config {
    Ensure-Directory $ConfigDir
    $empty = [ordered]@{
        connectEndpoints = @()
        lastSerial = $null
        lastPair = $null
        saved = $null
    }
    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        return [pscustomobject]$empty
    }

    try {
        $raw = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        $endpoints = @()
        if ($null -ne $raw.connectEndpoints) {
            $endpoints += @($raw.connectEndpoints | Where-Object { $_ })
        }
        if ($null -ne $raw.connect) {
            $endpoints += @($raw.connect | Where-Object { $_ })
        }
        if ($null -ne $raw.lastSerial -and $raw.lastSerial -match '^\d{1,3}(\.\d{1,3}){3}:\d+$') {
            $endpoints += $raw.lastSerial
        }
        return [pscustomobject]@{
            connectEndpoints = @($endpoints | Select-Object -Unique)
            lastSerial = if ($null -ne $raw.lastSerial) { $raw.lastSerial } else { $null }
            lastPair = if ($null -ne $raw.lastPair) { $raw.lastPair } else { $null }
            saved = if ($null -ne $raw.saved) { $raw.saved } else { $null }
        }
    }
    catch {
        return [pscustomobject]$empty
    }
}

function Save-Config($Config) {
    Ensure-Directory $ConfigDir
    $endpoints = @()
    if ($null -ne $Config.connectEndpoints) {
        $endpoints = @($Config.connectEndpoints | Where-Object { $_ } | Select-Object -Unique)
    }
    $lastSerial = if ($null -ne $Config.lastSerial) { [string]$Config.lastSerial } else { $null }
    if ($lastSerial -and $lastSerial -match '^\d{1,3}(\.\d{1,3}){3}:\d+$' -and @($endpoints) -notcontains $lastSerial) {
        $endpoints = @($lastSerial) + @($endpoints)
    }
    [pscustomobject]@{
        connectEndpoints = $endpoints
        lastSerial = $lastSerial
        lastPair = if ($null -ne $Config.lastPair) { $Config.lastPair } else { $null }
        saved = (Get-Date).ToString('s')
        note = 'ADB trust persists in adbkey; pairing code itself is temporary.'
    } | ConvertTo-Json -Depth 5 -Compress | Set-Content -LiteralPath $ConfigPath -Encoding ASCII
}

function Write-AndroidSteps {
    Write-Host ''
    Write-Host 'ANDROID STEPS FOR FIRST SETUP' -ForegroundColor Cyan
    Write-Host '1. Put the phone and this Windows PC on the same trusted Wi-Fi network.'
    Write-Host '2. Open Android Settings, then About phone, then tap Build number seven times.'
    Write-Host '3. Enter your lock screen PIN if Android asks to enable Developer options.'
    Write-Host '4. Open Settings, Developer options, then enable the main Developer options switch.'
    Write-Host '5. Enable Wireless debugging and approve the Android warning dialog.'
    Write-Host '6. Open Wireless debugging, then tap Pair device with pairing code.'
    Write-Host '7. Keep that pairing screen open; it shows IP:PORT and a six-digit code.'
    Write-Host '8. Type the IP with dots, for example 192.168.1.124:41539, never 192:168.'
    Write-Host '9. After pairing, leave Wireless debugging enabled for future aadb auto-connect.'
    Write-Host '10. Disable battery restrictions for Settings if your phone kills Wireless debugging.'
    Write-Host '11. If Android rotates ports after reboot, aadb tries saved endpoints and mDNS discovery.'
    Write-Host ''
}

function Invoke-Adb {
    param([string[]]$Arguments)
    & $Adb @Arguments
}

function ConvertTo-ProcessArgument([string]$Value) {
    if ($null -eq $Value) {
        return '""'
    }
    if ($Value -notmatch '[\s"]') {
        return $Value
    }
    return '"' + ($Value -replace '"', '\"') + '"'
}

function Invoke-AdbBounded {
    param(
        [string[]]$Arguments,
        [int]$TimeoutSeconds = 8
    )
    Ensure-Adb
    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Adb
    $psi.Arguments = (@($Arguments) | ForEach-Object { ConvertTo-ProcessArgument $_ }) -join ' '
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $process = [Diagnostics.Process]::Start($psi)
    if ($null -eq $process) {
        return @("ADB_PROCESS_START_RETURNED_NULL: adb $($psi.Arguments)")
    }
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try {
            $process.Kill()
        }
        catch {
        }
        return @("ADB_TIMEOUT after ${TimeoutSeconds}s: adb $($psi.Arguments)")
    }
    $stdout = if ($null -ne $process.StandardOutput) { $process.StandardOutput.ReadToEnd() } else { '' }
    $stderr = if ($null -ne $process.StandardError) { $process.StandardError.ReadToEnd() } else { '' }
    return @(($stdout + "`n" + $stderr) -split "`r?`n" | Where-Object { $_ })
}

function Start-AdbServer {
    Ensure-Adb
    $env:Path = "$UserBinDir;$PlatformTools;$env:Path"
    Invoke-Adb @('start-server') | Out-Host
}

function Get-AuthorizedSerial {
    $lines = Invoke-Adb @('devices') 2>$null
    $serials = @()
    foreach ($line in $lines) {
        if ($line -match '^(\S+)\s+device$') {
            $serials += $Matches[1]
        }
    }
    $ipSerial = @($serials | Where-Object { $_ -match '^\d{1,3}(\.\d{1,3}){3}:\d+$' } | Select-Object -First 1)
    if ($ipSerial.Count -gt 0) {
        return $ipSerial[0]
    }
    if ($serials.Count -gt 0) {
        return $serials[0]
    }
    return $null
}

function Get-MdnsEndpoints {
    param(
        [int]$Attempts = 3,
        [int]$DelaySeconds = 1
    )
    $result = @()
    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        $lines = Invoke-AdbBounded -Arguments @('mdns', 'services') -TimeoutSeconds 5
        foreach ($line in $lines) {
            if ($line -match '_adb-tls-connect' -and $line -match '(\d{1,3}(\.\d{1,3}){3}:\d+)') {
                $result += $Matches[1]
            }
        }
        if ($result.Count -gt 0) {
            break
        }
        if ($attempt -lt $Attempts) {
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    return @($result | Select-Object -Unique)
}

function Try-ConnectEndpoint([string]$Endpoint) {
    if ([string]::IsNullOrWhiteSpace($Endpoint)) {
        return $null
    }
    Write-Host "Trying adb connect $Endpoint" -ForegroundColor DarkCyan
    Invoke-AdbBounded -Arguments @('connect', $Endpoint) -TimeoutSeconds 8 | Out-Host
    Start-Sleep -Seconds 1
    return Get-AuthorizedSerial
}

function Add-EndpointToConfig($Config, [string]$Endpoint, [string]$Serial) {
    $lastPair = if ($null -ne $Config.lastPair) { $Config.lastPair } else { $null }
    if (-not [string]::IsNullOrWhiteSpace($Endpoint)) {
        $existing = @($Config.connectEndpoints | Where-Object { $_ })
        $endpoints = @($Endpoint) + @($existing | Where-Object { $_ -ne $Endpoint })
    }
    else {
        $endpoints = @($Config.connectEndpoints | Where-Object { $_ })
    }
    $lastSerial = if ($null -ne $Config.lastSerial) { $Config.lastSerial } else { $null }
    if (-not [string]::IsNullOrWhiteSpace($Serial)) {
        $lastSerial = $Serial
        if ($Serial -match '^\d{1,3}(\.\d{1,3}){3}:\d+$' -and @($endpoints) -notcontains $Serial) {
            $endpoints = @($Serial) + @($endpoints)
        }
    }
    Save-Config ([pscustomobject]@{
        connectEndpoints = @($endpoints | Select-Object -Unique)
        lastSerial = $lastSerial
        lastPair = $lastPair
        saved = $Config.saved
    })
}

function Ensure-LocalPersistence {
    Ensure-Directory $UserBinDir
    Ensure-Directory $ConfigDir

    if ($PSCommandPath -and ($PSCommandPath -ne $InstalledScriptPath)) {
        Copy-Item -LiteralPath $PSCommandPath -Destination $InstalledScriptPath -Force
    }
    elseif (-not (Test-Path -LiteralPath $InstalledScriptPath)) {
        Copy-Item -LiteralPath $PSCommandPath -Destination $InstalledScriptPath -Force
    }

    $shimBody = "& '$InstalledScriptPath' @args`r`n"
    Set-Content -LiteralPath $ShimPath -Value $shimBody -Encoding ASCII
    Set-Content -LiteralPath $ShortShimPath -Value $shimBody -Encoding ASCII

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $parts = @($userPath -split ';' | Where-Object { $_ })
    $wanted = @($UserBinDir, $PlatformTools)
    foreach ($path in $wanted) {
        if ($parts -notcontains $path) {
            $parts += $path
        }
    }
    [Environment]::SetEnvironmentVariable('Path', (($parts | Select-Object -Unique) -join ';'), 'User')
    $env:Path = "$UserBinDir;$PlatformTools;$env:Path"

    $taskName = 'CodexAadbAutoConnect'
    $taskCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$ShimPath`" connect"
    schtasks.exe /Create /TN $taskName /SC ONLOGON /RL LIMITED /F /TR $taskCommand | Out-Host
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
        $task.Settings.DisallowStartIfOnBatteries = $false
        $task.Settings.StopIfGoingOnBatteries = $false
        $task.Settings.ExecutionTimeLimit = 'PT5M'
        Set-ScheduledTask -InputObject $task -ErrorAction Stop | Out-Null
    }
    catch {
        Write-Host 'Scheduled task created; advanced battery settings were not changed.' -ForegroundColor Yellow
    }
    Write-Host "PERSISTENCE READY: PATH shim and logon auto-connect task installed." -ForegroundColor Green
}

function Ensure-ProfileWrapper {
    $profiles = @(
        (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
        (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1')
    )
    $block = @"

# >>> aadb Android ADB bridge >>>
function aadb {
    & '$ShimPath' @args
}
function aad {
    & '$ShortShimPath' @args
}
# <<< aadb Android ADB bridge <<<
"@
    foreach ($profilePath in $profiles) {
        $profileDir = Split-Path -Parent $profilePath
        Ensure-Directory $profileDir
        if (-not (Test-Path -LiteralPath $profilePath)) {
            New-Item -ItemType File -Force -Path $profilePath | Out-Null
        }
        $raw = [IO.File]::ReadAllText($profilePath)
        $pattern = '(?s)\r?\n?# >>> aadb Android ADB bridge >>>.*?# <<< aadb Android ADB bridge <<<\r?\n?'
        $raw = [regex]::Replace($raw, $pattern, '')
        [IO.File]::WriteAllText($profilePath, $raw.TrimEnd() + $block, [Text.UTF8Encoding]::new($false))
    }
    Write-Host 'PROFILE READY: aadb wrapper installed into WindowsPowerShell and PowerShell profiles.' -ForegroundColor Green
}

function Invoke-AutoSetup {
    Ensure-Adb
    Ensure-LocalPersistence
    Ensure-ProfileWrapper
    try {
        $serial = Ensure-Connected
        Write-Host "READY: aadb is installed and connected to $serial." -ForegroundColor Green
        return
    }
    catch {
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Write-Host 'Pairing is required now because no trusted/reachable device was found.' -ForegroundColor Yellow
        Setup-Wireless | Out-Null
    }
}

function Ensure-Connected {
    Start-AdbServer
    $cfg = Load-Config
    $attemptedEndpoints = @{}

    $serial = Get-AuthorizedSerial
    if ($serial -and $serial -notmatch '^\d{1,3}(\.\d{1,3}){3}:\d+$') {
        Write-Host "USB ADB is authorized as $serial; still searching for wireless endpoint." -ForegroundColor DarkCyan
        $serial = $null
    }
    if ($serial) {
        Add-EndpointToConfig $cfg $null $serial
        return $serial
    }

    foreach ($endpoint in @($cfg.connectEndpoints | Where-Object { $_ } | Select-Object -Unique)) {
        $attemptedEndpoints[$endpoint] = $true
        $serial = Try-ConnectEndpoint $endpoint
        if ($serial) {
            Add-EndpointToConfig $cfg $endpoint $serial
            return $serial
        }
    }

    foreach ($endpoint in Get-MdnsEndpoints -Attempts 2 -DelaySeconds 1) {
        if ($null -ne $attemptedEndpoints -and $attemptedEndpoints.ContainsKey($endpoint)) {
            continue
        }
        if ($null -ne $attemptedEndpoints) {
            $attemptedEndpoints[$endpoint] = $true
        }
        $serial = Try-ConnectEndpoint $endpoint
        if ($serial) {
            Add-EndpointToConfig $cfg $endpoint $serial
            return $serial
        }
    }

    Write-Host 'No device reachable through saved endpoint or mDNS. Restarting ADB server and trying once more...' -ForegroundColor Yellow
    Invoke-Adb @('kill-server') 2>$null | Out-Null
    Start-AdbServer

    foreach ($endpoint in @($cfg.connectEndpoints | Where-Object { $_ } | Select-Object -Unique)) {
        $serial = Try-ConnectEndpoint $endpoint
        if ($serial) {
            Add-EndpointToConfig $cfg $endpoint $serial
            return $serial
        }
    }

    foreach ($endpoint in Get-MdnsEndpoints -Attempts 2 -DelaySeconds 1) {
        $serial = Try-ConnectEndpoint $endpoint
        if ($serial) {
            Add-EndpointToConfig $cfg $endpoint $serial
            return $serial
        }
    }

    Write-Host 'No authorized Android device found. Starting wireless pairing repair now.' -ForegroundColor Yellow
    return (Setup-Wireless)
}

function Setup-Wireless {
    Start-AdbServer
    Ensure-LocalPersistence
    Write-AndroidSteps

    $rawPairEndpoint = Read-Host 'Enter pairing IP:PORT once'
    if ($null -eq $rawPairEndpoint) {
        throw 'Pairing repair requires the Android pairing IP:PORT. Run aadb repair in an interactive PowerShell window.'
    }
    $pairEndpoint = $rawPairEndpoint.Trim()
    if ($pairEndpoint -notmatch '^\d{1,3}(\.\d{1,3}){3}:\d+$') {
        throw 'Bad pairing address. Use dots, example 192.168.1.124:41539'
    }

    $rawPairCode = Read-Host 'Enter six-digit pairing code once'
    if ($null -eq $rawPairCode) {
        throw 'Pairing repair requires the Android six-digit pairing code. Run aadb repair in an interactive PowerShell window.'
    }
    $pairCode = $rawPairCode.Trim()
    if ($pairCode -notmatch '^\d{6}$') {
        throw 'Bad pairing code. It must be exactly six digits.'
    }

    Invoke-Adb @('pair', $pairEndpoint, $pairCode) 2>&1 | Out-Host
    Start-Sleep -Seconds 3

    $cfg = Load-Config
    $cfg = [pscustomobject]@{
        connectEndpoints = @($cfg.connectEndpoints)
        lastSerial = $cfg.lastSerial
        lastPair = $pairEndpoint
        saved = $cfg.saved
    }

    $serial = Get-AuthorizedSerial
    $connectedEndpoint = $null
    if (-not $serial) {
        foreach ($endpoint in Get-MdnsEndpoints) {
            $serial = Try-ConnectEndpoint $endpoint
            if ($serial) {
                $connectedEndpoint = $endpoint
                break
            }
        }
    }

    if (-not $serial) {
        Save-Config $cfg
        throw 'Paired, but could not discover the wireless connect port. Keep Wireless debugging enabled, disable VPN/firewall isolation, then run aadb setup again.'
    }

    Add-EndpointToConfig $cfg $connectedEndpoint $serial
    Write-Host "SETUP SAVED: aadb will reuse ADB trust and auto-discover/reconnect to $serial." -ForegroundColor Green
    return $serial
}

function ConvertTo-AndroidShellQuote([string]$Value) {
    return "'" + ($Value -replace "'", "'\''") + "'"
}

function Join-AndroidPath([string]$BasePath, [string]$Name) {
    if ($BasePath -eq '/') {
        return "/$Name"
    }
    return ($BasePath.TrimEnd('/') + '/' + $Name)
}

function Get-AndroidPathKind([string]$Serial, [string]$Path) {
    $quoted = ConvertTo-AndroidShellQuote $Path
    $script = "if [ -d $quoted ]; then echo DIR; elif [ -e $quoted ]; then echo FILE; else echo MISSING; fi"
    $result = Invoke-Adb @('-s', $Serial, 'shell', $script) 2>$null | Select-Object -First 1
    if ($null -eq $result) {
        return 'MISSING'
    }
    return $result.ToString().Trim()
}

function Resolve-InteractivePullRoot([string]$Serial, [string]$RequestedPath) {
    if ((Get-AndroidPathKind $Serial $RequestedPath) -eq 'DIR') {
        return $RequestedPath
    }

    if ($RequestedPath -eq '/home') {
        Write-Host '/home is not readable on this Android device; falling back to shared storage.' -ForegroundColor Yellow
        foreach ($candidate in @('/sdcard', '/storage/emulated/0', '/')) {
            if ((Get-AndroidPathKind $Serial $candidate) -eq 'DIR') {
                return $candidate
            }
        }
    }

    throw "Android directory not found or not readable: $RequestedPath"
}

function Get-AndroidDirectoryEntries([string]$Serial, [string]$Path) {
    $quoted = ConvertTo-AndroidShellQuote $Path
    $script = "cd $quoted 2>/dev/null && ls -1A"
    $lines = Invoke-Adb @('-s', $Serial, 'shell', $script) 2>$null
    $entries = @()
    foreach ($line in $lines) {
        $name = $line.ToString().TrimEnd("`r")
        if ([string]::IsNullOrWhiteSpace($name) -or $name -eq '.' -or $name -eq '..') {
            continue
        }
        $entryPath = Join-AndroidPath $Path $name
        $kind = if ((Get-AndroidPathKind $Serial $entryPath) -eq 'DIR') { 'D' } else { 'F' }
        $entries += [pscustomobject]@{
            Kind = $kind
            Name = $name
            Path = $entryPath
        }
    }
    return @($entries | Sort-Object Kind, Name)
}

function Invoke-InteractivePull([string]$StartPath) {
    $serial = Ensure-Connected
    $current = Resolve-InteractivePullRoot $serial $StartPath
    $destination = (Get-Location).Path

    while ($true) {
        Write-Host ''
        Write-Host "Android: $current" -ForegroundColor Cyan
        Write-Host "PC target: $destination" -ForegroundColor Cyan
        $entries = @(Get-AndroidDirectoryEntries $serial $current)
        if ($entries.Count -eq 0) {
            Write-Host '(empty or not readable)'
        }
        for ($i = 0; $i -lt $entries.Count; $i++) {
            $label = if ($entries[$i].Kind -eq 'D') { '[DIR] ' } else { '[FILE]' }
            '{0,3}. {1} {2}' -f ($i + 1), $label, $entries[$i].Name | Write-Host
        }

        Write-Host ''
        Write-Host 'Commands: name=pull item/folder, all=pull current folder, number=open folder/pull file, p number=pull item, open name=open folder, ..=up, q=quit'
        $rawChoice = Read-Host 'Choose'
        if ($null -eq $rawChoice) {
            return
        }
        $choice = $rawChoice.Trim()
        if ($choice -match '^(q|quit|exit)$') {
            return
        }
        if ($choice -eq '..') {
            if ($current -ne '/') {
                $current = ($current.TrimEnd('/') -replace '/[^/]+$', '')
                if ([string]::IsNullOrWhiteSpace($current)) {
                    $current = '/'
                }
            }
            continue
        }
        if ($choice -match '^(all|p|pull)$') {
            Copy-FromAndroid $current $destination
            continue
        }
        if ($choice -match '^p\s*(\d+)$') {
            $idx = [int]$Matches[1] - 1
            if ($idx -lt 0 -or $idx -ge $entries.Count) {
                Write-Host 'Invalid item number.' -ForegroundColor Yellow
                continue
            }
            Copy-FromAndroid $entries[$idx].Path $destination
            continue
        }
        if ($choice -match '^(open|cd)\s+(.+)$') {
            $nameChoice = $Matches[2].Trim()
            $matchesByName = @($entries | Where-Object { $_.Name -ieq $nameChoice })
            if ($matchesByName.Count -eq 1 -and $matchesByName[0].Kind -eq 'D') {
                $current = $matchesByName[0].Path
            }
            elseif ($matchesByName.Count -eq 1) {
                Write-Host 'That item is a file. Type its name without open/cd to pull it.' -ForegroundColor Yellow
            }
            else {
                Write-Host 'Folder name not found or ambiguous.' -ForegroundColor Yellow
            }
            continue
        }
        if ($choice -match '^\d+$') {
            $idx = [int]$choice - 1
            if ($idx -lt 0 -or $idx -ge $entries.Count) {
                Write-Host 'Invalid item number.' -ForegroundColor Yellow
                continue
            }
            if ($entries[$idx].Kind -eq 'D') {
                $current = $entries[$idx].Path
            }
            else {
                Copy-FromAndroid $entries[$idx].Path $destination
                continue
            }
            continue
        }
        $matchesByName = @($entries | Where-Object { $_.Name -ieq $choice })
        if ($matchesByName.Count -eq 1) {
            Copy-FromAndroid $matchesByName[0].Path $destination
            continue
        }
        elseif ($matchesByName.Count -gt 1) {
            Write-Host 'Name is ambiguous. Use the number or p number.' -ForegroundColor Yellow
            continue
        }
        Write-Host 'Unknown command.' -ForegroundColor Yellow
    }
}

function Resolve-AndroidDestination([string]$Source, [string]$Destination) {
    if (-not [string]::IsNullOrWhiteSpace($Destination)) {
        return $Destination
    }
    $item = Get-Item -LiteralPath $Source
    return "/sdcard/Download/$($item.Name)"
}

function Resolve-LocalSourcePath([string]$Source) {
    if ([string]::IsNullOrWhiteSpace($Source)) {
        return (Get-Location).Path
    }

    if (Test-Path -LiteralPath $Source) {
        return (Resolve-Path -LiteralPath $Source).Path
    }

    $trimmedSource = $Source.TrimEnd('\', '/')
    if ($trimmedSource -and (Test-Path -LiteralPath $trimmedSource)) {
        return (Resolve-Path -LiteralPath $trimmedSource).Path
    }

    $leaf = Split-Path -Leaf $trimmedSource
    if ([string]::IsNullOrWhiteSpace($leaf)) {
        return $null
    }

    $currentCandidate = Join-Path (Get-Location).Path $leaf
    if (Test-Path -LiteralPath $currentCandidate) {
        return (Resolve-Path -LiteralPath $currentCandidate).Path
    }

    $ancestor = Split-Path -Parent $trimmedSource
    while (-not [string]::IsNullOrWhiteSpace($ancestor) -and -not (Test-Path -LiteralPath $ancestor)) {
        $next = Split-Path -Parent $ancestor
        if ($next -eq $ancestor) {
            break
        }
        $ancestor = $next
    }

    if (-not [string]::IsNullOrWhiteSpace($ancestor) -and (Test-Path -LiteralPath $ancestor)) {
        $match = Get-ChildItem -LiteralPath $ancestor -Recurse -Force -Filter $leaf -ErrorAction SilentlyContinue |
            Sort-Object FullName |
            Select-Object -First 1
        if ($match) {
            return $match.FullName
        }
    }

    return $null
}

function Test-IsLocalPullDestination([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }
    if ($Value -match '^[A-Za-z]:[\\/]' -or $Value -match '^\\\\' -or $Value -match '^\.{1,2}([\\/]|$)') {
        return $true
    }
    if ($Value -match '[\\]') {
        return $true
    }
    return $false
}

function Resolve-PushArguments([string[]]$Values) {
    if ($null -eq $Values -or $Values.Count -eq 0) {
        return [pscustomobject]@{
            Source = $null
            Destination = $null
        }
    }

    $parts = @($Values | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($parts.Count -eq 0) {
        return [pscustomobject]@{
            Source = $null
            Destination = $null
        }
    }

    $destination = $null
    if ($parts.Count -gt 1 -and $parts[-1].StartsWith('/')) {
        $destination = $parts[-1]
        $parts = @($parts[0..($parts.Count - 2)])
    }

    $sourceCandidates = @()
    $sourceCandidates += ($parts -join ' ')
    $sourceCandidates += ($parts -join '')
    if ($parts.Count -gt 1) {
        $sourceCandidates += ($parts[0..($parts.Count - 2)] -join ' ')
        $sourceCandidates += ($parts[0..($parts.Count - 2)] -join '')
    }
    $sourceCandidates += $parts[0]

    foreach ($candidate in @($sourceCandidates | Where-Object { $_ } | Select-Object -Unique)) {
        if (Resolve-LocalSourcePath $candidate) {
            return [pscustomobject]@{
                Source = $candidate
                Destination = $destination
            }
        }
    }

    return [pscustomobject]@{
        Source = ($parts -join ' ')
        Destination = $destination
    }
}

function Copy-ToAndroid([string]$Source, [string]$Destination) {
    $resolvedSource = Resolve-LocalSourcePath $Source
    if ([string]::IsNullOrWhiteSpace($resolvedSource)) {
        throw "PC path not found: $Source"
    }
    $Source = $resolvedSource
    $serial = Ensure-Connected
    $dest = Resolve-AndroidDestination $Source $Destination
    Invoke-Adb @('-s', $serial, 'push', '-p', $Source, $dest)
    Write-Host "COPIED TO ANDROID: $Source -> $dest"
}

function Copy-FromAndroid([string]$Source, [string]$Destination) {
    if ([string]::IsNullOrWhiteSpace($Source)) {
        throw 'Missing Android source path.'
    }
    if (Test-IsLocalPullDestination $Source) {
        if ([string]::IsNullOrWhiteSpace($Destination)) {
            $Destination = $Source
            $Source = '/sdcard/DCIM'
        }
        else {
            throw 'For pull, use either: aadb pull <androidPath> <pcPath> OR aadb pull <pcPath>.'
        }
    }
    if (-not $Source.StartsWith('/')) {
        $Source = "/sdcard/$Source"
    }
    if ([string]::IsNullOrWhiteSpace($Destination)) {
        $Destination = (Get-Location).Path
    }
    $serial = Ensure-Connected
    Invoke-Adb @('-s', $serial, 'pull', '-a', $Source, $Destination)
    Write-Host "COPIED FROM ANDROID: $Source -> $Destination"
}

function Install-DefaultApk {
    if (-not (Test-Path -LiteralPath $DefaultApk)) {
        throw "Default APK not found: $DefaultApk"
    }
    $serial = Ensure-Connected
    Invoke-Adb @('-s', $serial, 'install', '-r', '-d', $DefaultApk)
    Invoke-Adb @('-s', $serial, 'push', '-p', $DefaultApk, '/sdcard/Download/app-debug.apk')
    Write-Host "APK INSTALLED AND COPIED: $DefaultApk -> /sdcard/Download/app-debug.apk"
}

function Show-Paths {
    Write-Host "Script: $PSCommandPath"
    Write-Host "Installed script: $InstalledScriptPath"
    Write-Host "Shim:   $ShimPath"
    Write-Host "Short shim: $ShortShimPath"
    Write-Host "Config: $ConfigPath"
    Write-Host "ADB:    $Adb"
}

if ($null -eq $AadbArgs -or $AadbArgs.Count -eq 0) {
    Write-AadbHelp
    return
}

$cmd = $AadbArgs[0].ToLowerInvariant()
$rest = @()
if ($AadbArgs.Count -gt 1) {
    $rest = @($AadbArgs[1..($AadbArgs.Count - 1)])
}

switch ($cmd) {
    'help' { Write-AadbHelp; return }
    '-h' { Write-AadbHelp; return }
    '--help' { Write-AadbHelp; return }
    'steps' { Write-AndroidSteps; return }
    'path' { Ensure-Adb; Show-Paths; return }
    'persist' { Ensure-Adb; Ensure-LocalPersistence; Ensure-ProfileWrapper; return }
    'bootstrap' { Invoke-AutoSetup; return }
    'autosetup' { Invoke-AutoSetup; return }
    'setup' { Setup-Wireless | Out-Null; return }
    'repair' { Setup-Wireless | Out-Null; return }
    'pair' { Setup-Wireless | Out-Null; return }
    'connect' { $serial = Ensure-Connected; Write-Host "CONNECTED: $serial"; return }
    'devices' { Start-AdbServer; Invoke-Adb @('devices', '-l'); return }
    'apk' { Install-DefaultApk; return }
    'install' {
        $apk = if ($rest.Count -gt 0) { $rest[0] } else { $DefaultApk }
        if (-not (Test-Path -LiteralPath $apk)) { throw "APK not found: $apk" }
        $serial = Ensure-Connected
        Invoke-Adb @('-s', $serial, 'install', '-r', '-d', $apk)
        return
    }
    'push' {
        $pushArgs = Resolve-PushArguments $rest
        Copy-ToAndroid $pushArgs.Source $pushArgs.Destination
        return
    }
    'pull' {
        $source = if ($rest.Count -gt 0) { $rest[0] } else { $null }
        $dest = if ($rest.Count -gt 1) { $rest[1] } else { $null }
        if ([string]::IsNullOrWhiteSpace($source)) {
            Invoke-InteractivePull '/home'
        }
        else {
            Copy-FromAndroid $source $dest
        }
        return
    }
    'shell' {
        $serial = Ensure-Connected
        Invoke-Adb (@('-s', $serial, 'shell') + $rest)
        return
    }
    default {
        $serial = Ensure-Connected
        Invoke-Adb (@('-s', $serial) + $AadbArgs)
        return
    }
}
