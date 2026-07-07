param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot),
    [string]$PcIp,
    [string]$PcMac,
    [string]$RelayBase = 'https://ntfy.sh',
    [int]$LocalPort = 8777,
    [string[]]$WakePorts = @('7','9','40000','40009'),
    [string]$SdkRoot = 'C:\Users\micha\bubblewrap-tools\android_sdk',
    [string]$JdkRoot = 'C:\Users\micha\android-build-tools\jdk',
    [switch]$BuildApk = $true,
    [switch]$InstallAndroid,
    [switch]$SkipPcAgent,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

function New-Base64UrlToken {
    param([int]$Bytes = 24)
    $buffer = New-Object byte[] $Bytes
    [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($buffer)
    return ([Convert]::ToBase64String($buffer).TrimEnd('=') -replace '\+','-' -replace '/','_')
}

function Get-PrimaryIPv4 {
    $cfg = Get-NetIPConfiguration |
        Where-Object { $_.IPv4Address -and $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway } |
        Select-Object -First 1
    if (-not $cfg) { throw 'Could not auto-detect primary IPv4. Re-run with -PcIp 192.168.x.x and -PcMac AA:BB:CC:DD:EE:FF.' }
    return $cfg.IPv4Address.IPAddress
}

function Get-PrimaryMac {
    $cfg = Get-NetIPConfiguration |
        Where-Object { $_.IPv4Address -and $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway } |
        Select-Object -First 1
    if ($cfg -and $cfg.NetAdapter.MacAddress) {
        return ($cfg.NetAdapter.MacAddress -replace '-', ':')
    }
    $adapter = Get-NetAdapter |
        Where-Object { $_.Status -eq 'Up' -and $_.MacAddress } |
        Sort-Object Name |
        Select-Object -First 1
    if (-not $adapter) { throw 'Could not auto-detect MAC. Re-run with -PcMac AA:BB:CC:DD:EE:FF.' }
    return ($adapter.MacAddress -replace '-', ':')
}

function Get-Broadcast {
    param([string]$Ip)
    $parts = $Ip.Split('.')
    if ($parts.Count -ne 4) { return '255.255.255.255' }
    return "$($parts[0]).$($parts[1]).$($parts[2]).255"
}

if (-not $PcIp) { $PcIp = Get-PrimaryIPv4 }
if (-not $PcMac) { $PcMac = Get-PrimaryMac }

$scripts = Join-Path $Root 'scripts'
$raw = Join-Path $Root 'app\src\main\res\raw'
$runtime = Join-Path $Root 'runtime'
$logDir = Join-Path $runtime 'logs'
$dist = Join-Path $Root 'dist'

if ($ValidateOnly) {
    $checks = [ordered]@{
        Root = (Test-Path -LiteralPath $Root)
        PowerShell51 = (Test-Path -LiteralPath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe")
        DotNetCsc = ((Test-Path -LiteralPath "$env:SystemRoot\Microsoft.NET\Framework64\v4.0.30319\csc.exe") -or (Test-Path -LiteralPath "$env:SystemRoot\Microsoft.NET\Framework\v4.0.30319\csc.exe"))
        AndroidSdkRoot = (Test-Path -LiteralPath $SdkRoot)
        JdkRoot = (Test-Path -LiteralPath $JdkRoot)
        Adb = (Test-Path -LiteralPath (Join-Path $env:LOCALAPPDATA 'Android\platform-tools\adb.exe'))
        DetectedPcIp = $PcIp
        DetectedPcMac = $PcMac
    }
    $checks.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }
    Write-Output 'REMOTE_COMMAND_CENTER_VALIDATE_ONLY_OK'
    exit 0
}

New-Item -ItemType Directory -Force -Path $scripts, $raw, $runtime, $logDir, $dist | Out-Null

$commandTopic = 'rcc-command-' + (New-Base64UrlToken -Bytes 18).ToLowerInvariant()
$statusTopic = 'rcc-status-' + (New-Base64UrlToken -Bytes 18).ToLowerInvariant()
$sharedKey = New-Base64UrlToken -Bytes 32
$broadcast = Get-Broadcast -Ip $PcIp
$wakePortInts = @($WakePorts | ForEach-Object { [int]$_ })

$pcConfig = [ordered]@{
    RelayBases = @($RelayBase)
    LocalPort = $LocalPort
    LocalPath = '/rcc/action'
    CommandTopic = $commandTopic
    StatusTopic = $statusTopic
    SharedKey = $sharedKey
    AllowedSkewSeconds = 300
    StateDir = $runtime
    LogDir = $logDir
}
$androidConfig = [ordered]@{
    relayBases = @($RelayBase)
    localBases = @("http://${PcIp}:${LocalPort}/rcc")
    wakeMacs = @($PcMac)
    wakeBroadcasts = @('255.255.255.255', $broadcast)
    wakeHosts = @($PcIp)
    wakePorts = $wakePortInts
    commandTopic = $commandTopic
    statusTopic = $statusTopic
    sharedKey = $sharedKey
}

$pcConfigPath = Join-Path $scripts 'rcc-config.json'
$androidConfigPath = Join-Path $raw 'rescue_config.json'
$pcConfig | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $pcConfigPath -Encoding UTF8
$androidConfig | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $androidConfigPath -Encoding UTF8

$trayExe = & (Join-Path $scripts 'Build-RemoteCommandCenterTrayExe.ps1') -Root $Root

if (-not $SkipPcAgent) {
    & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts 'Install-RemoteCommandCenterAgent.ps1') -InstallDir $Root
}

$apk = Join-Path $Root 'artifacts\build-output\RemoteCommandCenter-debug.apk'
if ($BuildApk) {
    if ((Test-Path -LiteralPath $SdkRoot) -and (Test-Path -LiteralPath $JdkRoot)) {
        $apk = & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Root 'build-android.ps1') -SdkRoot $SdkRoot -JdkRoot $JdkRoot | Select-Object -Last 1
    } else {
        Write-Warning "Android SDK or JDK was not found. APK was not rebuilt. Pass -SdkRoot and -JdkRoot, or install Android build-tools and JDK."
    }
}

if ($InstallAndroid) {
    $adb = Join-Path $env:LOCALAPPDATA 'Android\platform-tools\adb.exe'
    if (-not (Test-Path -LiteralPath $adb)) { throw "ADB not found: $adb" }
    if (-not (Test-Path -LiteralPath $apk)) { throw "APK not found: $apk" }
    $serial = (& $adb devices | Select-String "`tdevice$" | Select-Object -First 1).ToString().Split("`t")[0]
    if (-not $serial) { throw 'No connected Android device. Enable wireless debugging or connect USB, then re-run with -InstallAndroid.' }
    & $adb -s $serial install --no-incremental -r -d $apk
    & $adb -s $serial shell pm grant com.mich.remotecommandcenter android.permission.WRITE_SECURE_SETTINGS
    & $adb -s $serial shell monkey -p com.mich.remotecommandcenter -c android.intent.category.LAUNCHER 1 | Out-Null
}

Write-Output "REMOTE_COMMAND_CENTER_SETUP_OK"
Write-Output "TrayExe=$trayExe"
Write-Output "SetupCmd=$(Join-Path $Root 'Install-RemoteCommandCenter.cmd')"
Write-Output "PcConfig=$pcConfigPath"
Write-Output "AndroidConfig=$androidConfigPath"
Write-Output "Apk=$apk"
