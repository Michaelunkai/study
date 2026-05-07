param(
    [Parameter(Mandatory = $true)][string]$RunId,
    [Parameter(Mandatory = $true)][ValidateSet('started','progress','completed','failed','blocked','dead-letter')][string]$Status,
    [string]$Message,
    [string]$AgentId,
    [string]$SessionKey,
    [string]$OutputPath,
    [string]$CorrelationId,
    [string]$StateDir = "F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\openclaw-home"
)

$ErrorActionPreference = 'Stop'
$checkpointRoot = Join-Path $StateDir 'tasks\durable-jobs'
New-Item -ItemType Directory -Force -Path $checkpointRoot | Out-Null
$safeRunId = ($RunId -replace '[^a-zA-Z0-9_.-]', '_').Trim('_')
if ([string]::IsNullOrWhiteSpace($safeRunId)) { throw 'RunId produced an empty safe filename.' }
$path = Join-Path $checkpointRoot "$safeRunId.jsonl"
$record = [pscustomobject]@{
    timestamp = (Get-Date).ToString('o')
    runId = $RunId
    correlationId = if ($CorrelationId) { $CorrelationId } else { $RunId }
    status = $Status
    message = $Message
    agentId = $AgentId
    sessionKey = $SessionKey
    processId = $PID
    outputPath = $OutputPath
    idempotencyKey = "$RunId/$Status/$((Get-Date).ToUniversalTime().Ticks)"
}
$json = $record | ConvertTo-Json -Depth 6 -Compress
Add-Content -LiteralPath $path -Value $json -Encoding UTF8
[pscustomobject]@{
    checkpointPath = $path
    record = $record
} | ConvertTo-Json -Depth 8
