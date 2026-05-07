param(
    [int]$Seconds = 75,
    [int]$ProgressEverySeconds = 30,
    [string]$StateDir = "F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\openclaw-home",
    [switch]$Quick
)

$ErrorActionPreference = 'Stop'
if ($Quick) {
    $Seconds = 3
    $ProgressEverySeconds = 1
}
$runId = "smoke-$([guid]::NewGuid().ToString('N'))"
$checkpointRoot = Join-Path $StateDir 'tasks\durable-jobs'
New-Item -ItemType Directory -Force -Path $checkpointRoot | Out-Null
$checkpointPath = Join-Path $checkpointRoot "$runId.jsonl"
function Write-Checkpoint {
    param([string]$CheckpointStatus, [string]$CheckpointMessage)
    $record = [pscustomobject]@{
        timestamp = (Get-Date).ToString('o')
        runId = $runId
        correlationId = $runId
        status = $CheckpointStatus
        message = $CheckpointMessage
        processId = $PID
        idempotencyKey = "$runId/$CheckpointStatus/$((Get-Date).ToUniversalTime().Ticks)"
    }
    Add-Content -LiteralPath $checkpointPath -Value ($record | ConvertTo-Json -Depth 6 -Compress) -Encoding UTF8
}

Write-Checkpoint -CheckpointStatus started -CheckpointMessage 'durable job smoke started'
$started = Get-Date
$nextProgress = $started.AddSeconds($ProgressEverySeconds)
$progressCount = 0
while (((Get-Date) - $started).TotalSeconds -lt $Seconds) {
    Start-Sleep -Milliseconds 250
    if ((Get-Date) -ge $nextProgress) {
        $progressCount++
        Write-Checkpoint -CheckpointStatus progress -CheckpointMessage "progress $progressCount"
        $nextProgress = (Get-Date).AddSeconds($ProgressEverySeconds)
    }
}
Write-Checkpoint -CheckpointStatus completed -CheckpointMessage 'durable job smoke completed'
$records = @(Get-Content -LiteralPath $checkpointPath | ForEach-Object { $_ | ConvertFrom-Json })
$runsSqlitePath = Join-Path $StateDir 'tasks\runs.sqlite'
$productionRegistryCoverage = 'not-covered'
$productionRegistryDetail = 'This smoke verifies durable JSONL checkpoint append/read only; it does not create or update production task_runs rows.'
if (Test-Path -LiteralPath $runsSqlitePath) {
    $productionRegistryDetail = "Production registry exists at $runsSqlitePath, but this smoke intentionally does not mutate it."
}
[pscustomobject]@{
    runId = $runId
    checkpointPath = $checkpointPath
    runsSqlitePath = $runsSqlitePath
    productionRegistryCoverage = $productionRegistryCoverage
    productionRegistryDetail = $productionRegistryDetail
    elapsedSeconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 2)
    progressCount = $progressCount
    recordCount = $records.Count
    passed = ($records.Count -ge 3 -and $records[-1].status -eq 'completed' -and ($Quick -or $progressCount -ge 2))
} | ConvertTo-Json -Depth 6
