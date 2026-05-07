param(
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'

$paths = Get-OpenClawPaths
$authority = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
$truth = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawCurrentTruth.ps1') -ConfigPath $paths.ConfigPath | ConvertFrom-Json
$telegram = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawTelegramIntegrity.ps1') -Json | ConvertFrom-Json

$report = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('o')
    authority = $authority
    truth = $truth
    telegram = $telegram
    canonicalPaths = [pscustomobject]@{
        repoRoot = $paths.RepoRoot
        stateRoot = $paths.StateRoot
        configPath = $paths.ConfigPath
        runtimeCommandRoot = $paths.RuntimeCommandRoot
        manifestPath = $paths.ManifestPath
    }
}

Save-OpenClawManagedJsonFile -Object $report -Path $paths.RecoveryReportPath -Kind 'recovery-report' -Source 'New-OpenClawRecoveryReport.ps1'

if ($Json) {
    $report | ConvertTo-Json -Depth 10
} else {
    $report
}
