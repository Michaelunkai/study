[CmdletBinding()]
param(
    [string]$VmName = 'Codex-Win11-Ready',
    [string]$RdpFile = ''
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($RdpFile)) {
    $RdpFile = Join-Path $PSScriptRoot 'Connect-Win11VM-AllDrives.rdp'
}

if ($PSVersionTable.PSVersion.Major -ge 6) {
    $argsList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-VmName', $VmName)
    if (-not [string]::IsNullOrWhiteSpace($RdpFile)) {
        $argsList += @('-RdpFile', $RdpFile)
    }
    & powershell.exe @argsList
    exit $LASTEXITCODE
}

if ([string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) {
    $env:COMPUTERNAME = [System.Net.Dns]::GetHostName()
}

$moduleRoot = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\Modules'
if ($env:PSModulePath -notlike "*$moduleRoot*") {
    $env:PSModulePath = $moduleRoot + ';' + $env:PSModulePath
}

Import-Module Hyper-V -ErrorAction Stop
$vm = Get-VM -Name $VmName -ErrorAction SilentlyContinue
if (-not $vm) {
    throw "VM '$VmName' was not found. Run .\Start-Win11VM.ps1 first."
}

$hostName = if ([string]::IsNullOrWhiteSpace($env:COMPUTERNAME)) { [System.Net.Dns]::GetHostName() } else { $env:COMPUTERNAME }
$rdp = @(
    'screen mode id:i:2',
    'use multimon:i:0',
    'desktopwidth:i:1920',
    'desktopheight:i:1080',
    'session bpp:i:32',
    'redirectclipboard:i:1',
    'redirectprinters:i:0',
    'redirectcomports:i:0',
    'redirectsmartcards:i:0',
    'devicestoredirect:s:*',
    'drivestoredirect:s:*',
    'redirectdrives:i:1',
    'redirectposdevices:i:0',
    'audiomode:i:0',
    'prompt for credentials:i:0',
    'authentication level:i:0',
    'negotiate security layer:i:1',
    'server port:i:2179',
    "full address:s:$hostName",
    "pcb:s:$($vm.Id);EnhancedMode=1"
)
Set-Content -LiteralPath $RdpFile -Value $rdp -Encoding ASCII
Start-Process -FilePath (Join-Path $env:WINDIR 'System32\mstsc.exe') -ArgumentList @($RdpFile) -WindowStyle Normal
