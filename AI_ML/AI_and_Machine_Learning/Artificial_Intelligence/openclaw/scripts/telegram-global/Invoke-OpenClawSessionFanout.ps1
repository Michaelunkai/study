param(
    [Parameter(Mandatory = $true)]
    [string]$UserId,

    [Parameter(Mandatory = $true)]
    [string]$Message,

    [string[]]$TargetAgentIds,

    [string]$ExcludeAgentId,

    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths

$authorityCheck = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
if (-not $authorityCheck.passed) {
    $failed = @($authorityCheck.checks | Where-Object { -not $_.passed } | ForEach-Object { $_.name })
    throw "OpenClaw authority drift blocks session fanout: $($failed -join ', ')"
}

$agentMaps = @(
    @{ agentId = 'main'; accountId = 'bot1' },
    @{ agentId = 'session2'; accountId = 'bot2' },
    @{ agentId = 'openclaw'; accountId = 'openclaw' },
    @{ agentId = 'openclaw4'; accountId = 'openclaw4' }
)

function Get-AgentCommandRuntimePath {
    param(
        [Parameter(Mandatory = $true)][string]$RuntimeRoot
    )

    $distRoot = Join-Path $RuntimeRoot 'dist'
    $candidate = @(
        Get-ChildItem -LiteralPath $distRoot -File -Filter 'agent-command-*.js' -ErrorAction Stop |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
    )[0]
    if (-not $candidate) {
        throw "Could not locate agent-command runtime under $distRoot"
    }
    return $candidate.FullName
}

function Invoke-AgentCommandForSession {
    param(
        [Parameter(Mandatory = $true)][string]$RuntimeRoot,
        [Parameter(Mandatory = $true)][string]$SessionKey,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$AgentId,
        [int]$TimeoutSeconds = 45
    )

    $payload = @{
        modulePath = Get-AgentCommandRuntimePath -RuntimeRoot $RuntimeRoot
        sessionKey = $SessionKey
        message = $Message
        agentId = $AgentId
        timeoutSeconds = $TimeoutSeconds
    } | ConvertTo-Json -Depth 10 -Compress

    $nodeScript = @'
const fs = require("node:fs");
const { pathToFileURL } = require("node:url");

(async () => {
  const raw = process.env.OPENCLAW_FANOUT_PAYLOAD;
  if (!raw) throw new Error("OPENCLAW_FANOUT_PAYLOAD missing.");
  const payload = JSON.parse(raw);
  const source = fs.readFileSync(payload.modulePath, "utf8");
  const match = source.match(/export\s*\{\s*agentCommand\s+as\s+([A-Za-z_$][\w$]*)/);
  if (!match) {
    throw new Error(`Could not resolve agentCommand export alias from ${payload.modulePath}`);
  }
  const mod = await import(pathToFileURL(payload.modulePath).href);
  const agentCommand = mod[match[1]];
  if (typeof agentCommand !== "function") {
    throw new Error(`Resolved export ${match[1]} is not callable in ${payload.modulePath}`);
  }
  const result = await agentCommand({
    sessionKey: payload.sessionKey,
    message: payload.message,
    agentId: payload.agentId,
    deliver: false,
    senderIsOwner: true,
    allowModelOverride: true,
    thinking: "off",
    timeout: payload.timeoutSeconds
  });
  process.stdout.write(JSON.stringify(result));
  process.exit(0);
})().catch((err) => {
  const text = err && err.stack ? err.stack : String(err);
  process.stderr.write(text);
  process.exit(1);
});
'@

    $previousPayload = $env:OPENCLAW_FANOUT_PAYLOAD
    $hadPreviousPayload = Test-Path Env:OPENCLAW_FANOUT_PAYLOAD
    try {
        $env:OPENCLAW_FANOUT_PAYLOAD = $payload
        $rawResult = & node.exe -e $nodeScript 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        if ($hadPreviousPayload) {
            $env:OPENCLAW_FANOUT_PAYLOAD = $previousPayload
        } else {
            Remove-Item Env:OPENCLAW_FANOUT_PAYLOAD -ErrorAction SilentlyContinue
        }
    }

    $resultText = (($rawResult | ForEach-Object { "$_" }) -join "`n").Trim()
    if ($exitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($resultText)) {
            $resultText = "node exited with code $exitCode"
        }
        throw "Session fanout runtime call failed for ${SessionKey}: $resultText"
    }

    if ([string]::IsNullOrWhiteSpace($resultText)) {
        throw "Session fanout runtime call returned no JSON for $SessionKey"
    }

    $parsed = $resultText | ConvertFrom-Json
    $status = [string]$parsed.status
    if ($status -and $status -notin @('ok', 'accepted', 'timeout')) {
        $detail = if ($parsed.error) { [string]$parsed.error } else { $resultText }
        throw "Session fanout returned status '$status' for ${SessionKey}: $detail"
    }

    return $parsed
}

function Resolve-TargetMaps {
    param(
        [Parameter(Mandatory = $true)][array]$AllMaps,
        [string[]]$RequestedAgentIds,
        [string]$ExcludedAgentId
    )

    $normalizedRequested = @()
    foreach ($agentId in @($RequestedAgentIds)) {
        if ([string]::IsNullOrWhiteSpace($agentId)) { continue }
        $normalizedRequested += ([string]$agentId).Trim().ToLowerInvariant()
    }

    $normalizedExclude = if ([string]::IsNullOrWhiteSpace($ExcludedAgentId)) {
        $null
    } else {
        ([string]$ExcludedAgentId).Trim().ToLowerInvariant()
    }

    $targets = foreach ($map in $AllMaps) {
        $agentId = ([string]$map.agentId).Trim().ToLowerInvariant()
        if ($normalizedRequested.Count -gt 0 -and $agentId -notin $normalizedRequested) {
            continue
        }
        if ($normalizedExclude -and $agentId -eq $normalizedExclude) {
            continue
        }
        $map
    }

    if (@($targets).Count -eq 0) {
        throw 'No target agents matched the requested fanout set.'
    }

    return @($targets)
}

$targets = Resolve-TargetMaps -AllMaps $agentMaps -RequestedAgentIds $TargetAgentIds -ExcludedAgentId $ExcludeAgentId
$results = @()

foreach ($map in $targets) {
    $sessionKey = "agent:$($map.agentId):telegram:$($map.accountId):direct:$UserId"
    $storePath = Join-Path $paths.AgentsRoot "$($map.agentId)\sessions\sessions.json"
    if (-not (Test-Path -LiteralPath $storePath)) {
        $results += [pscustomobject]@{
            agentId = $map.agentId
            accountId = $map.accountId
            sessionKey = $sessionKey
            ok = $false
            status = 'missing-store'
        }
        continue
    }

    $store = Get-Content -Raw -LiteralPath $storePath | ConvertFrom-Json
    if ($store.PSObject.Properties.Name -notcontains $sessionKey) {
        $results += [pscustomobject]@{
            agentId = $map.agentId
            accountId = $map.accountId
            sessionKey = $sessionKey
            ok = $false
            status = 'missing-session'
        }
        continue
    }

    if ($DryRun) {
        $results += [pscustomobject]@{
            agentId = $map.agentId
            accountId = $map.accountId
            sessionKey = $sessionKey
            ok = $true
            status = 'dry-run'
        }
        continue
    }

    $runtimeResult = Invoke-AgentCommandForSession -RuntimeRoot $paths.RuntimeRoot -SessionKey $sessionKey -Message $Message -AgentId $map.agentId

    $results += [pscustomobject]@{
        agentId = $map.agentId
        accountId = $map.accountId
        sessionKey = $sessionKey
        ok = $true
        status = if ([string]::IsNullOrWhiteSpace([string]$runtimeResult.status)) { 'accepted' } else { [string]$runtimeResult.status }
        runId = [string]$runtimeResult.runId
    }
}

$results | ConvertTo-Json -Depth 10
