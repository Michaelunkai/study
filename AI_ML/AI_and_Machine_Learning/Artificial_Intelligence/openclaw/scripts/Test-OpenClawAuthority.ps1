param(
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'

function Add-AuthorityCheck {
    param(
        [System.Collections.Generic.List[object]]$Checks,
        [string]$Name,
        [bool]$Passed,
        [string]$Detail
    )

    [void]$Checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        detail = $Detail
    })
}

function Get-LinkTargetText {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    try {
        $item = Get-Item -LiteralPath $Path -Force
        if ($item.LinkType -and $item.Target) {
            if ($item.Target -is [System.Array]) {
                return [string]$item.Target[0]
            }
            return [string]$item.Target
        }
    } catch {
    }

    try {
        return (Resolve-Path -LiteralPath $Path).Path
    } catch {
        return $null
    }
}

function Get-TaskInfo {
    param([Parameter(Mandatory = $true)][string]$TaskName)

    try {
        $raw = schtasks.exe /Query /TN $TaskName /FO LIST /V 2>$null
    } catch {
        return $null
    }
    if ($LASTEXITCODE -ne 0 -or -not $raw) {
        return $null
    }

    $text = $raw -join "`n"
    $taskToRun = $null
    $state = $null
    if ($text -match '(?im)^\s*Task To Run:\s*(.+)$') {
        $taskToRun = $Matches[1].Trim()
    }
    if ($text -match '(?im)^\s*Scheduled Task State:\s*(.+)$') {
        $state = $Matches[1].Trim()
    } elseif ($text -match '(?im)^\s*Status:\s*(.+)$') {
        $state = $Matches[1].Trim()
    }

    [pscustomobject]@{
        raw = $text
        taskToRun = $taskToRun
        state = $state
    }
}

function Normalize-TaskCommandText {
    param([string]$Value)

    return ([string]$Value).Replace('"', '').Trim()
}

function Resolve-TaskCommandPath {
    param([string]$Value)

    $normalized = Normalize-TaskCommandText -Value $Value
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $null
    }

    try {
        if (Test-Path -LiteralPath $normalized) {
            return (Resolve-Path -LiteralPath $normalized).Path
        }
    } catch {
    }

    try {
        return [System.IO.Path]::GetFullPath($normalized)
    } catch {
        return $normalized
    }
}

function Test-TaskTargetMatches {
    param(
        [string]$TaskName,
        [string]$ActualTarget,
        [string]$ExpectedTarget,
        [object]$Defaults
    )

    if ([string]::IsNullOrWhiteSpace($ActualTarget)) {
        return $false
    }

    $normalizedActual = Normalize-TaskCommandText -Value $ActualTarget
    $normalizedExpected = Normalize-TaskCommandText -Value $ExpectedTarget
    if ($normalizedActual.IndexOf($normalizedExpected, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        return $true
    }

    $actualResolved = Resolve-TaskCommandPath -Value $ActualTarget
    $candidateTargets = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($ExpectedTarget)) {
        [void]$candidateTargets.Add($ExpectedTarget)
    }

    if ($TaskName -eq 'OpenClaw Gateway') {
        [void]$candidateTargets.Add((Join-Path $Defaults.StateRoot 'gateway.cmd'))
        [void]$candidateTargets.Add('C:\Users\micha\.openclaw\gateway.cmd')
    }

    foreach ($candidate in $candidateTargets) {
        $resolvedCandidate = Resolve-TaskCommandPath -Value $candidate
        if ($actualResolved -and $resolvedCandidate -and $actualResolved -eq $resolvedCandidate) {
            return $true
        }
    }

    return $false
}

$authority = Get-OpenClawAuthority
$defaults = Get-OpenClawCanonicalDefaults
$paths = Get-OpenClawPaths
$checks = [System.Collections.Generic.List[object]]::new()

Add-AuthorityCheck $checks 'manifest-exists' (Test-Path -LiteralPath $paths.ManifestPath) $paths.ManifestPath
Add-AuthorityCheck $checks 'manifest-canonical-repo' ([string]$authority.repo.root -eq $defaults.RepoRoot) ([string]$authority.repo.root)
Add-AuthorityCheck $checks 'manifest-canonical-state' ([string]$authority.state.root -eq $defaults.StateRoot) ([string]$authority.state.root)
Add-AuthorityCheck $checks 'manifest-canonical-config' ([string]$authority.state.configPath -eq $defaults.ConfigPath) ([string]$authority.state.configPath)
Add-AuthorityCheck $checks 'runtime-pointer-valid' ((Test-Path -LiteralPath $paths.RuntimeDistEntrypoint) -and [string]$authority.runtime.commandRoot -eq $paths.RuntimeCommandRoot) ([string]$authority.runtime.commandRoot)
Add-AuthorityCheck $checks 'repo-identity-exists' (Test-Path -LiteralPath $paths.RepoIdentityPath) $paths.RepoIdentityPath
Add-AuthorityCheck $checks 'machine-identity-exists' (Test-Path -LiteralPath $paths.MachineIdentityPath) $paths.MachineIdentityPath

foreach ($alias in $defaults.Aliases) {
    $targetText = Get-LinkTargetText -Path $alias.path
    $expected = [System.IO.Path]::GetFullPath($alias.target)
    $resolved = if ($targetText) { [System.IO.Path]::GetFullPath($targetText) } else { $null }
    Add-AuthorityCheck $checks ("alias:{0}" -f $alias.path) ($resolved -eq $expected) ("resolved={0}" -f $resolved)
}

foreach ($envName in 'OPENCLAW_REPO_ROOT','OPENCLAW_STATE_DIR','OPENCLAW_CONFIG_PATH','OPENCLAW_TMP_DIR','OPENCLAW_AUTHORITY_MANIFEST_PATH','OPENCLAW_RUNTIME_COMMAND_ROOT') {
    $expected = switch ($envName) {
        'OPENCLAW_REPO_ROOT' { $defaults.Env.OPENCLAW_REPO_ROOT; break }
        'OPENCLAW_STATE_DIR' { $defaults.Env.OPENCLAW_STATE_DIR; break }
        'OPENCLAW_CONFIG_PATH' { $defaults.Env.OPENCLAW_CONFIG_PATH; break }
        'OPENCLAW_TMP_DIR' { $defaults.Env.OPENCLAW_TMP_DIR; break }
        'OPENCLAW_AUTHORITY_MANIFEST_PATH' { $defaults.Env.OPENCLAW_AUTHORITY_MANIFEST_PATH; break }
        'OPENCLAW_RUNTIME_COMMAND_ROOT' { $paths.RuntimeCommandRoot; break }
    }
    $actual = [Environment]::GetEnvironmentVariable($envName, 'User')
    Add-AuthorityCheck $checks ("env:{0}" -f $envName) ($actual -eq $expected) ("actual={0}" -f $actual)
}

$cfg = Get-Content -Raw -LiteralPath $paths.ConfigPath | ConvertFrom-Json
$configAuthority = $null
if (Test-Path -LiteralPath $paths.ConfigAuthorityPath) {
    try {
        $configAuthority = Get-Content -Raw -LiteralPath $paths.ConfigAuthorityPath | ConvertFrom-Json
    } catch {
        $configAuthority = $null
    }
}
Add-AuthorityCheck $checks 'config-authority-sidecar' ($null -ne $configAuthority -and [string]$configAuthority.generationId -eq $paths.AuthorityGenerationId) ((ConvertTo-Json $configAuthority -Depth 5 -Compress))
Add-AuthorityCheck $checks 'telegram-binding-count' (@($authority.telegram.bindings).Count -eq 4) ("count={0}" -f @($authority.telegram.bindings).Count)
Add-AuthorityCheck $checks 'agent-binding-count' (@($cfg.agents.list).Count -eq 4) ("count={0}" -f @($cfg.agents.list).Count)

$workspaceMismatches = @()
foreach ($binding in @($authority.telegram.bindings)) {
    $agent = @($cfg.agents.list | Where-Object { $_.id -eq $binding.agentId })[0]
    if (-not $agent -or [string]$agent.workspace -ne [string]$binding.workspace -or [string]$agent.heartbeat.accountId -ne [string]$binding.accountId) {
        $workspaceMismatches += $binding.agentId
    }
}
Add-AuthorityCheck $checks 'binding-workspace-alignment' ($workspaceMismatches.Count -eq 0) ("mismatches={0}" -f ($workspaceMismatches -join ','))

$taskResults = @()
foreach ($task in $defaults.Tasks) {
    $info = Get-TaskInfo -TaskName $task.name
    $ok = $false
    $detail = 'missing-task'
    if ($info) {
        $stateOk = if ($task.enabled) {
            [string]$info.state -ne 'Disabled'
        } else {
            [string]$info.state -eq 'Disabled'
        }
        $targetOk = Test-TaskTargetMatches -TaskName $task.name -ActualTarget $info.taskToRun -ExpectedTarget $task.target -Defaults $defaults
        $ok = $stateOk -and $targetOk
        $detail = "{0} | {1}" -f $info.state, $info.taskToRun
    }
    $taskResults += [pscustomobject]@{
        name = $task.name
        passed = $ok
        detail = $detail
    }
    Add-AuthorityCheck $checks ("task:{0}" -f $task.name) $ok $detail
}

$managedState = Get-OpenClawManagedState
$managedGenerationOk = [string]$managedState.generationId -eq $paths.AuthorityGenerationId
Add-AuthorityCheck $checks 'managed-state-generation' $managedGenerationOk ([string]$managedState.generationId)

$managedMissing = @()
foreach ($managedFile in @($managedState.files)) {
    if (-not (Test-Path -LiteralPath ([string]$managedFile.path))) {
        $managedMissing += [string]$managedFile.path
    }
}
Add-AuthorityCheck $checks 'managed-files-present' ($managedMissing.Count -eq 0) ("missing={0}" -f ($managedMissing -join '; '))

$result = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('o')
    generationId = $paths.AuthorityGenerationId
    runtimeGenerationId = $paths.RuntimeGenerationId
    checks = @($checks)
    passed = (@($checks | Where-Object { -not $_.passed }).Count -eq 0)
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
} else {
    $result
}
