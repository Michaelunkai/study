param(
    [string]$ConfigPath,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
if (-not $ConfigPath) { $ConfigPath = $paths.ConfigPath }

$truth = powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawCurrentTruth.ps1') -ConfigPath $ConfigPath | ConvertFrom-Json
$smoke = powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Invoke-OpenClawSmoke.ps1') -ConfigPath $ConfigPath -SkipTelegramNetwork -Json | ConvertFrom-Json
$evidencePath = Join-Path $paths.TempRoot ("openclaw-evidence-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
$evidence = powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Get-OpenClawLatestEvidence.ps1') -OutputPath $evidencePath -RecentFiles 6 -TailBytes 8192 | ConvertFrom-Json

$report = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('o')
    configPath = $truth.configPath
    runtime = [pscustomobject]@{
        tcpLiveness = $truth.tcpLiveness
        managerPids = $truth.managerPids
        gatewayPids = $truth.gatewayPids
        listenerPids = $truth.listenerPids
        trayOwnedGateway = $truth.trayOwnedGateway
        scheduledGatewayTaskEnabled = $truth.scheduledGatewayTaskEnabled
    }
    authority = [pscustomobject]@{
        generationId = $truth.authorityGenerationId
        runtimeGenerationId = $truth.runtimeGenerationId
        passed = $truth.authorityPassed
        failedChecks = @($truth.authorityFailedChecks)
    }
    agents = $truth.configAgents
    smokePassed = $smoke.passed
    failedChecks = @($smoke.checks | Where-Object { -not $_.passed })
    evidencePath = $evidencePath
    evidenceCounts = [pscustomobject]@{
        sessions = @($evidence.sessions).Count
        gatewayLogs = @($evidence.gatewayLogs).Count
        taskFiles = @($evidence.taskFiles).Count
    }
}

if ($Json) {
    $report | ConvertTo-Json -Depth 8
} else {
    $report
}
