param(
    [string]$SourcePath = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ClawdBot\src\ClawdBotManagerApp\Program.cs',
    [string]$OutputPath = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ClawdBot\ClawdBotManager.exe',
    [string]$IconPath = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ClawdBot\ClawdBotManager.ico'
)

$ErrorActionPreference = 'Stop'

function New-ManagerIcon {
    param([Parameter(Mandatory = $true)][string]$Path)

    Add-Type -AssemblyName System.Drawing

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $bitmap = New-Object System.Drawing.Bitmap 32, 32
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.Clear([System.Drawing.Color]::Transparent)

    $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(64, 0, 0, 0))
    $fill = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(34, 197, 94))
    $ring = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(230, 255, 255, 255)), 2
    $dot = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(245, 245, 245))

    $graphics.FillEllipse($shadow, 5, 7, 22, 22)
    $graphics.FillEllipse($fill, 4, 4, 22, 22)
    $graphics.DrawEllipse($ring, 4, 4, 22, 22)
    $graphics.FillEllipse($dot, 12, 12, 6, 6)

    $iconHandle = $bitmap.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($iconHandle)
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Create)
    try {
        $icon.Save($stream)
    } finally {
        $stream.Dispose()
        $icon.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $SourcePath)) {
    throw "Missing source file: $SourcePath"
}

if (-not (Test-Path -LiteralPath $IconPath)) {
    New-ManagerIcon -Path $IconPath
}

$cscPath = 'C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\Roslyn\csc.exe'
if (-not (Test-Path -LiteralPath $cscPath)) {
    throw "Missing csc compiler: $cscPath"
}

$frameworkRoot = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319'
$references = @(
    (Join-Path $frameworkRoot 'System.Windows.Forms.dll'),
    (Join-Path $frameworkRoot 'System.Drawing.dll'),
    (Join-Path $frameworkRoot 'System.Management.dll'),
    (Join-Path $frameworkRoot 'System.Net.Http.dll')
)

foreach ($reference in $references) {
    if (-not (Test-Path -LiteralPath $reference)) {
        throw "Missing reference assembly: $reference"
    }
}

$parent = Split-Path -Parent $OutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
}

$arguments = @(
    '/nologo',
    '/target:winexe',
    '/optimize+',
    '/langversion:latest',
    "/win32icon:$IconPath",
    "/out:$OutputPath"
)

foreach ($reference in $references) {
    $arguments += "/reference:$reference"
}
$arguments += $SourcePath

& $cscPath @arguments
if ($LASTEXITCODE -ne 0) {
    throw "ClawdBotManager build failed with exit code $LASTEXITCODE"
}

Get-Item -LiteralPath $OutputPath | Select-Object FullName, Length, LastWriteTime
