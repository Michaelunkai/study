param(
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$src = Join-Path $root 'src\RccControlledSleep.cs'
$dist = Join-Path $root 'dist'
$out = Join-Path $dist 'RccControlledSleep.exe'
New-Item -ItemType Directory -Force -Path $dist | Out-Null

$cscCandidates = @(
    (Join-Path $env:SystemRoot 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'),
    (Join-Path $env:SystemRoot 'Microsoft.NET\Framework\v4.0.30319\csc.exe')
)
$csc = $cscCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $csc) {
    throw 'Unable to find the built-in .NET Framework C# compiler.'
}

& $csc /nologo /target:winexe /optimize+ /platform:anycpu /out:$out /reference:System.dll /reference:System.Drawing.dll /reference:System.Windows.Forms.dll $src
if ($LASTEXITCODE -ne 0) {
    throw "csc failed with exit code $LASTEXITCODE"
}

Get-Item -LiteralPath $out
