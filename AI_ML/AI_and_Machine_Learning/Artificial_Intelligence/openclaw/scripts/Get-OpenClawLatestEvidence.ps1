param(
    [string]$StateDir = "F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\openclaw-home",
    [int]$RecentFiles = 12,
    [int]$TailBytes = 24000,
    [int]$MaxFilesPerRoot = 2000,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Read-FileTailText {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [int]$Bytes = 24000
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return ''
    }

    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    try {
        $length = $stream.Length
        $count = [Math]::Min([int64]$Bytes, $length)
        $buffer = New-Object byte[] $count
        $stream.Seek($length - $count, [System.IO.SeekOrigin]::Begin) | Out-Null
        $read = $stream.Read($buffer, 0, $count)
        return [System.Text.Encoding]::UTF8.GetString($buffer, 0, $read)
    }
    finally {
        $stream.Dispose()
    }
}

function Get-RelevantTailLines {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    $patterns = @(
        '"type"\s*:\s*"response_item"',
        '"type"\s*:\s*"tool_result"',
        '"shell_command"',
        '"stdout"\s*:',
        '"stderr"\s*:',
        'exit code\s*:\s*[1-9]',
        '"status"\s*:\s*"completed"',
        '"status"\s*:\s*"failed"',
        '"status"\s*:\s*"error"',
        '"error"\s*:\s*"(?!0|null|false)',
        '"runId"\s*:',
        '"task(Id|_id|Name|_name)?"\s*:'
    )

    $lines = $Text -split "`r?`n"
    $matched = foreach ($line in $lines) {
        foreach ($pattern in $patterns) {
            if ($line -match $pattern -and $line -notmatch '"errorCount"\s*:\s*0') {
                $line
                break
            }
        }
    }

    @($matched | Select-Object -Last 80)
}

$statePath = Resolve-Path -LiteralPath $StateDir
function Get-BoundedEvidenceFiles {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string[]]$AllowedNames,
        [Parameter(Mandatory = $true)][string[]]$AllowedExtensions
    )

    if (-not (Test-Path -LiteralPath $Root)) { return @() }

    $files = Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            ($AllowedNames -contains $_.Name) -or ($AllowedExtensions -contains $_.Extension.ToLowerInvariant())
        } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $MaxFilesPerRoot

    @($files)
}

$sessionRoots = @()
$agentsRoot = Join-Path $statePath 'agents'
if (Test-Path -LiteralPath $agentsRoot) {
    $sessionRoots = @(Get-ChildItem -LiteralPath $agentsRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Join-Path $_.FullName 'sessions'
    } | Where-Object { Test-Path -LiteralPath $_ })
}
$sessionFiles = @($sessionRoots | ForEach-Object {
    Get-ChildItem -LiteralPath $_ -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -eq 'sessions.json' -or $_.Extension.ToLowerInvariant() -eq '.jsonl' } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First $MaxFilesPerRoot
}) |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First $RecentFiles

$gatewayLogs = Get-ChildItem -LiteralPath (Join-Path $statePath 'tmp') -File -Filter 'openclaw-*.log' -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 3

$taskRoots = @(
    (Join-Path $statePath 'tasks\durable-jobs'),
    (Join-Path $statePath 'task-runs'),
    (Join-Path $statePath 'cron')
) | Where-Object { Test-Path -LiteralPath $_ }

$taskFiles = foreach ($root in $taskRoots) {
    Get-BoundedEvidenceFiles -Root $root -AllowedNames @('tasks.json','jobs.json') -AllowedExtensions @('.jsonl','.log')
}

$taskFiles = @($taskFiles) |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 8

$result = [pscustomobject]@{
    stateDir = $statePath.Path
    generatedAt = (Get-Date).ToString('o')
    sessions = @($sessionFiles | ForEach-Object {
        $tail = Read-FileTailText -Path $_.FullName -Bytes $TailBytes
        [pscustomobject]@{
            path = $_.FullName
            lastWriteTime = $_.LastWriteTime.ToString('o')
            length = $_.Length
            evidence = @(Get-RelevantTailLines -Text $tail)
        }
    })
    gatewayLogs = @($gatewayLogs | ForEach-Object {
        $tail = Read-FileTailText -Path $_.FullName -Bytes $TailBytes
        [pscustomobject]@{
            path = $_.FullName
            lastWriteTime = $_.LastWriteTime.ToString('o')
            evidence = @(Get-RelevantTailLines -Text $tail)
        }
    })
    taskFiles = @($taskFiles | ForEach-Object {
        [pscustomobject]@{
            path = $_.FullName
            lastWriteTime = $_.LastWriteTime.ToString('o')
            length = $_.Length
            tail = Read-FileTailText -Path $_.FullName -Bytes ([Math]::Min($TailBytes, 12000))
        }
    })
}

$json = $result | ConvertTo-Json -Depth 8
if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    [System.IO.File]::WriteAllText($OutputPath, $json, [System.Text.Encoding]::UTF8)
}
$json
