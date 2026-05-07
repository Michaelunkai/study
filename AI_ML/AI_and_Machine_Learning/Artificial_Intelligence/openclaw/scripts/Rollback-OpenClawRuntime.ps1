param(
    [string]$CommandRoot,
    [switch]$PersistUser,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'

$paths = Get-OpenClawPaths
$history = if (Test-Path -LiteralPath $paths.RuntimeHistoryPath) {
    Get-Content -Raw -LiteralPath $paths.RuntimeHistoryPath | ConvertFrom-Json
} else {
    $null
}

if (-not $CommandRoot) {
    $lastEntry = @($history.entries | Select-Object -Last 1)[0]
    if (-not $lastEntry) {
        throw "No runtime history exists to roll back."
    }
    $CommandRoot = [string]$lastEntry.previousCommandRoot
}

$result = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Set-OpenClawActiveRuntime.ps1') -CommandRoot $CommandRoot -PersistUser:$PersistUser -Json | ConvertFrom-Json

if ($Json) {
    $result | ConvertTo-Json -Depth 6
} else {
    $result
}
