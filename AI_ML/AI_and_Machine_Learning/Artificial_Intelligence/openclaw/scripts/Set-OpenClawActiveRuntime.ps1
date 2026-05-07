param(
    [Parameter(Mandatory = $true)][string]$CommandRoot,
    [switch]$PersistUser,
    [switch]$SkipSmoke,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'

function Assert-RealtimeProgressHardening {
    param([Parameter(Mandatory = $true)][string]$CommandRootPath)

    $heartbeatRunnerPath = Join-Path $CommandRootPath 'node_modules\clawdbot\dist\infra\heartbeat-runner.js'
    $commandQueuePath = Join-Path $CommandRootPath 'node_modules\clawdbot\dist\process\command-queue.js'
    foreach ($path in @($heartbeatRunnerPath, $commandQueuePath)) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Realtime progress hardening file missing from runtime candidate: $path"
        }
    }

    $heartbeatRunnerText = Get-Content -Raw -LiteralPath $heartbeatRunnerPath
    $commandQueueText = Get-Content -Raw -LiteralPath $commandQueuePath
    $heartbeatMarkers = @(
        'IN_FLIGHT_PROGRESS_MIN_INTERVAL_MS',
        'buildInFlightProgressText',
        'resolveBusyHeartbeatOwner'
    )
    $queueMarkers = @(
        'getCommandLaneActivity',
        'reason: "work-start"',
        'activeSinceMs'
    )
    foreach ($marker in $heartbeatMarkers) {
        if ($heartbeatRunnerText -notmatch [regex]::Escape($marker)) {
            throw "Runtime candidate is missing realtime progress hardening marker '$marker' in $heartbeatRunnerPath"
        }
    }
    foreach ($marker in $queueMarkers) {
        if ($commandQueueText -notmatch [regex]::Escape($marker)) {
            throw "Runtime candidate is missing realtime progress hardening marker '$marker' in $commandQueuePath"
        }
    }
}

$paths = Get-OpenClawPaths
$candidate = [System.IO.Path]::GetFullPath($CommandRoot)
$packagePath = Join-Path $candidate 'node_modules\openclaw\package.json'
if (-not (Test-Path -LiteralPath $packagePath)) {
    throw "Runtime candidate does not contain node_modules\\openclaw\\package.json: $candidate"
}
Assert-RealtimeProgressHardening -CommandRootPath $candidate

$previousPointer = if (Test-Path -LiteralPath $paths.RuntimePointerPath) {
    Get-Content -Raw -LiteralPath $paths.RuntimePointerPath | ConvertFrom-Json
} else {
    [pscustomobject]@{ commandRoot = $paths.RuntimeCommandRoot }
}

$history = if (Test-Path -LiteralPath $paths.RuntimeHistoryPath) {
    try { Get-Content -Raw -LiteralPath $paths.RuntimeHistoryPath | ConvertFrom-Json } catch { [pscustomobject]@{ entries = @() } }
} else {
    [pscustomobject]@{ entries = @() }
}

$history.entries = @($history.entries) + [pscustomobject]@{
    changedAt = (Get-Date).ToString('o')
    previousCommandRoot = [string]$previousPointer.commandRoot
    nextCommandRoot = $candidate
}
Save-OpenClawManagedJsonFile -Object $history -Path $paths.RuntimeHistoryPath -Kind 'runtime-history' -Source 'Set-OpenClawActiveRuntime.ps1'
Save-OpenClawJsonFile -Object ([pscustomobject]@{
    commandRoot = $candidate
    updatedAt = (Get-Date).ToString('o')
}) -Path $paths.RuntimePointerPath

if ($PersistUser) {
    & (Join-Path $paths.RepoRoot 'scripts\Ensure-OpenClawCommandSurface.ps1') -PersistUser | Out-Null
} else {
    & (Join-Path $paths.RepoRoot 'scripts\Ensure-OpenClawCommandSurface.ps1') | Out-Null
}

$authorityOk = $true
$smokeOk = $true
if (-not $SkipSmoke) {
    $authority = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
    $authorityOk = [bool]$authority.passed
    $smoke = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Invoke-OpenClawSmoke.ps1') -ConfigPath $paths.ConfigPath -SkipTelegramNetwork -Json | ConvertFrom-Json
    $smokeOk = [bool]$smoke.passed
    if (-not $authorityOk -or -not $smokeOk) {
        Save-OpenClawJsonFile -Object $previousPointer -Path $paths.RuntimePointerPath
        if ($PersistUser) {
            & (Join-Path $paths.RepoRoot 'scripts\Ensure-OpenClawCommandSurface.ps1') -PersistUser | Out-Null
        } else {
            & (Join-Path $paths.RepoRoot 'scripts\Ensure-OpenClawCommandSurface.ps1') | Out-Null
        }
        throw "Runtime activation failed verification and was rolled back."
    }
}

$result = [pscustomobject]@{
    changedAt = (Get-Date).ToString('o')
    commandRoot = $candidate
    previousCommandRoot = [string]$previousPointer.commandRoot
    authorityVerified = $authorityOk
    smokeVerified = $smokeOk
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
} else {
    $result
}
