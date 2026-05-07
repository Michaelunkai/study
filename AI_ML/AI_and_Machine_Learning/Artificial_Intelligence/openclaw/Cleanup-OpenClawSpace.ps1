[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Force,
    [switch]$KeepRunnable
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path -LiteralPath $PSScriptRoot).ProviderPath

function Get-FileBytes {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    $item = Get-Item -LiteralPath $Path -Force
    if (-not $item.PSIsContainer) { return [int64]$item.Length }
    $measurement = Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
    if ($null -eq $measurement -or $null -eq $measurement.Sum) { return 0 }
    return [int64]$measurement.Sum
}

function Assert-InProject {
    param([Parameter(Mandatory=$true)][string]$Path)

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $resolved) { return $null }
    $full = $resolved.ProviderPath
    if (-not $full.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove path outside project: $full"
    }
    return $full
}

$targets = New-Object System.Collections.Generic.List[string]

foreach ($relative in @(
    'Setup\payload',
    'versions',
    'reports\migration-rollback-20260423-172305',
    'reports\c-legacy-artifacts-20260423-185126',
    'npm-global\node_modules',
    'npm-global\package-lock.json',
    'npm-global\openclaw.cmd',
    'npm-global\openclaw.ps1',
    'npm-global\clawdbot.cmd',
    'npm-global\clawdbot.ps1',
    'npm-global\%SystemDrive%',
    'tmp',
    'tmp-dotnet-sdk-10.0.203',
    'tmp-dotnet-sdk-10.0.203-win-x64.zip',
    '%SystemDrive%',
    '.playwright-mcp',
    '.openclaw-cache',
    'openclaw-home\tmp',
    'openclaw-home\logs',
    'openclaw-home\media',
    'openclaw-home\browser',
    'openclaw-home\chrome-cdp',
    'openclaw-home\%SystemDrive%',
    'ClawdBot\src\ClawdBotManagerApp\bin',
    'ClawdBot\src\ClawdBotManagerApp\obj',
    'ClawdBot\publish'
)) {
    $path = Join-Path $root $relative
    if (Test-Path -LiteralPath $path) { $targets.Add($path) }
}

if (-not $KeepRunnable) {
    foreach ($pattern in @(
        'ClawdBotManager.exe',
        'ClawdBotManager.exe.*',
        '*.patched.exe',
        '*.build*.exe',
        '*.test*.exe',
        '*_ClawdBotManager.exe'
    )) {
        Get-ChildItem -LiteralPath (Join-Path $root 'ClawdBot') -Force -File -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object { $targets.Add($_.FullName) }
    }
}

Get-ChildItem -LiteralPath $root -Recurse -Force -Directory -Filter '__pycache__' -ErrorAction SilentlyContinue |
    ForEach-Object { $targets.Add($_.FullName) }

$agentsRoot = Join-Path $root 'openclaw-home\agents'
if (Test-Path -LiteralPath $agentsRoot) {
    Get-ChildItem -LiteralPath $agentsRoot -Recurse -Force -File -Filter '*.deleted.*' -ErrorAction SilentlyContinue |
        ForEach-Object { $targets.Add($_.FullName) }
    foreach ($name in @('.tmp', 'tmp')) {
        Get-ChildItem -LiteralPath $agentsRoot -Recurse -Force -Directory -Filter $name -ErrorAction SilentlyContinue |
            ForEach-Object { $targets.Add($_.FullName) }
    }
}

$projectRoot = Join-Path $root 'projects'
if (Test-Path -LiteralPath $projectRoot) {
    foreach ($name in @('node_modules', '.next', '.netlify', 'dist', 'build')) {
        Get-ChildItem -LiteralPath $projectRoot -Recurse -Force -Directory -Filter $name -ErrorAction SilentlyContinue |
            ForEach-Object { $targets.Add($_.FullName) }
    }
}

$uniqueTargets = $targets | Sort-Object -Unique
$before = 0
foreach ($target in $uniqueTargets) { $before += Get-FileBytes -Path $target }

foreach ($target in $uniqueTargets) {
    $full = Assert-InProject -Path $target
    if (-not $full) { continue }
    if ($PSCmdlet.ShouldProcess($full, 'Remove generated OpenClaw artifact')) {
        try {
            Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop
        } catch {
            if ($Force) {
                attrib -R -S -H $full /S /D 2>$null
                Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction Stop
            } else {
                throw
            }
        }
    }
}

$after = 0
foreach ($target in $uniqueTargets) {
    if (Test-Path -LiteralPath $target) { $after += Get-FileBytes -Path $target }
}

[pscustomobject]@{
    Root = $root
    RemovedBytes = [int64]($before - $after)
    RemovedMB = [math]::Round(($before - $after) / 1MB, 2)
    KeptRunnable = [bool]$KeepRunnable
    RemovedTargetCount = ($uniqueTargets | Measure-Object).Count
}
