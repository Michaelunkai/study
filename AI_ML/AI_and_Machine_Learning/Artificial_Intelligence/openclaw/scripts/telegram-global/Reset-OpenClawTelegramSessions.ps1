param(
    [Parameter(Mandatory = $true)]
    [string]$UserId
)

$ErrorActionPreference = "Stop"
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths

$agentMaps = @(
    @{ agentId = "main"; accountId = "bot1" },
    @{ agentId = "session2"; accountId = "bot2" },
    @{ agentId = "openclaw"; accountId = "openclaw" },
    @{ agentId = "openclaw4"; accountId = "openclaw4" }
)

function Save-Json {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $json = $Object | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.Encoding]::UTF8)
}

function Set-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter()]$Value
    )

    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
        return
    }

    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
}

$nowMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$results = @()

foreach ($map in $agentMaps) {
    $storePath = Join-Path $paths.AgentsRoot "$($map.agentId)\sessions\sessions.json"
    $sessionsDir = Split-Path -Parent $storePath
    if (-not (Test-Path $storePath)) {
        $results += [pscustomobject]@{
            agentId = $map.agentId
            storePath = $storePath
            updated = $false
            reason = "store-missing"
        }
        continue
    }

    $store = Get-Content -Raw $storePath | ConvertFrom-Json
    $directKey = "agent:$($map.agentId):telegram:$($map.accountId):direct:$UserId"
    $slashKey = "agent:$($map.agentId):telegram:slash:$UserId"
    $updated = $false

    foreach ($key in @($directKey, $slashKey)) {
        if ($store.PSObject.Properties.Name -contains $key) {
            $entry = $store.$key
            $nextSessionId = [guid]::NewGuid().ToString()
            Set-ObjectProperty -Object $entry -Name "sessionId" -Value $nextSessionId
            Set-ObjectProperty -Object $entry -Name "sessionFile" -Value (Join-Path $sessionsDir "$nextSessionId.jsonl")
            Set-ObjectProperty -Object $entry -Name "updatedAt" -Value $nowMs

            foreach ($field in @(
                "status", "startedAt", "endedAt", "runtimeMs",
                "inputTokens", "outputTokens", "cacheRead", "cacheWrite",
                "totalTokens", "estimatedCostUsd", "systemPromptReport",
                "authProfileOverride", "authProfileOverrideSource",
                "authProfileOverrideCompactionCount", "contextTokens",
                "totalTokensFresh", "remainingTokens", "percentUsed",
                "skillsSnapshot", "systemSent", "abortedLastRun"
            )) {
                if ($entry.PSObject.Properties.Name -contains $field) {
                    $entry.PSObject.Properties.Remove($field)
                }
            }

            $updated = $true
        }
    }

    if ($updated) {
        Save-Json -Object $store -Path $storePath
    }

    $results += [pscustomobject]@{
        agentId = $map.agentId
        accountId = $map.accountId
        directKey = $directKey
        slashKey = $slashKey
        updated = $updated
        storePath = $storePath
        directSessionId = if ($store.PSObject.Properties.Name -contains $directKey) { $store.$directKey.sessionId } else { $null }
        slashSessionId = if ($store.PSObject.Properties.Name -contains $slashKey) { $store.$slashKey.sessionId } else { $null }
    }
}

$results | ConvertTo-Json -Depth 10
