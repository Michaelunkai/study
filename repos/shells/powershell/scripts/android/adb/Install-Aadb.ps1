param(
    [switch]$NoSetup,
    [switch]$PersistOnly
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$ScriptDir = Split-Path -Parent $PSCommandPath
$BridgeScript = Join-Path $ScriptDir 'Invoke-AndroidAdbBridge.ps1'

if (-not (Test-Path -LiteralPath $BridgeScript)) {
    throw "Missing bridge script next to installer: $BridgeScript"
}

try {
    Unblock-File -LiteralPath $BridgeScript -ErrorAction SilentlyContinue
    Unblock-File -LiteralPath $PSCommandPath -ErrorAction SilentlyContinue
}
catch {
}

Write-Host 'Installing aadb for this Windows user...' -ForegroundColor Cyan

if ($PersistOnly -or $NoSetup) {
    & $BridgeScript persist
}
else {
    & $BridgeScript bootstrap
}

Write-Host ''
Write-Host 'aadb install complete.' -ForegroundColor Green
Write-Host 'Open a new PowerShell window if aadb is not recognized in the current one.'
Write-Host 'Run: aadb help'
