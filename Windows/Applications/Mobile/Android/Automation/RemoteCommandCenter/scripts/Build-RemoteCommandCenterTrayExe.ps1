param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$source = Join-Path $Root 'tools\RemoteCommandCenterTrayLauncher.cs'
$dist = Join-Path $Root 'dist'
$exe = Join-Path $dist 'RemoteCommandCenterTray.exe'
$csc = Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $csc)) {
    $csc = Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
if (-not (Test-Path -LiteralPath $csc)) {
    throw 'C# compiler not found. Install .NET Framework 4.x Developer Pack or run on a normal Windows developer machine.'
}
if (-not (Test-Path -LiteralPath $source)) {
    throw "Missing source: $source"
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
& $csc /nologo /target:winexe /platform:anycpu /optimize+ /out:$exe $source
if ($LASTEXITCODE -ne 0) { throw 'Tray launcher compile failed.' }
if (-not (Test-Path -LiteralPath $exe)) { throw "Tray launcher was not created: $exe" }
$item = Get-Item -LiteralPath $exe
if ($item.Length -le 0) { throw "Tray launcher is empty: $exe" }
Write-Output $exe

