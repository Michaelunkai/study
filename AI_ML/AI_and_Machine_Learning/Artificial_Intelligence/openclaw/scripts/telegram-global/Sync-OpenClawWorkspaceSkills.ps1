param(
    [string]$ConfigPath,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
if (-not $ConfigPath) { $ConfigPath = $paths.ConfigPath }

$authorityCheck = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
if (-not $authorityCheck.passed) {
    $failed = @($authorityCheck.checks | Where-Object { -not $_.passed } | ForEach-Object { $_.name })
    throw "OpenClaw authority drift blocks workspace skill sync: $($failed -join ', ')"
}

$workspaceRoots = @($paths.WorkspaceRoots)
$stateRootResolved = [System.IO.Path]::GetFullPath($paths.StateRoot)
$userHome = $env:USERPROFILE
$commandCatalogPath = $paths.CommandCatalogPath
$commandCatalogByCommand = @{}

$externalRoots = @(
    (Join-Path $paths.RuntimeRoot 'skills'),
    $(if ($userHome) { Join-Path $userHome '.codex\skills' }),
    $(if ($userHome) { Join-Path $userHome '.codex\superpowers\skills' }),
    $(if ($userHome) { Join-Path $userHome '.claude\skills' }),
    $paths.GeneratedSkillsRoot,
    $paths.GeneratedClaudeCommandsRoot
) | Where-Object { $_ -and (Test-Path $_) }

$pluginRoots = @(
    $(if ($userHome) { Join-Path $userHome '.codex\plugins\cache' }),
    $(if ($userHome) { Join-Path $userHome '.codex\.tmp\plugins' })
) | Where-Object { $_ -and (Test-Path $_) }

if (Test-Path $commandCatalogPath) {
    try {
        $catalog = Get-Content -Raw $commandCatalogPath | ConvertFrom-Json
        foreach ($entry in @($catalog.entries)) {
            if (-not $entry.command) {
                continue
            }
            $normalized = ([string]$entry.command).Trim().ToLowerInvariant()
            if ([string]::IsNullOrWhiteSpace($normalized)) {
                continue
            }
            $commandCatalogByCommand[$normalized] = $entry
        }
    } catch {
    }
}

function Get-WorkspaceSkillDir {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$Command
    )

    return Join-Path (Join-Path $WorkspaceRoot 'skills') $Command
}

function Get-SkillDirSignature {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path $Path)) {
        return [pscustomobject]@{
            LatestTicks = 0
            FileCount   = 0
            SkillHash   = $null
        }
    }

    $latestTicks = 0L
    $fileCount = 0
    foreach ($file in Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue) {
        $fileCount++
        $ticks = $file.LastWriteTimeUtc.Ticks
        if ($ticks -gt $latestTicks) {
            $latestTicks = $ticks
        }
    }

    $skillPath = Join-Path $Path 'SKILL.md'
    $skillHash = if (Test-Path $skillPath) {
        (Get-FileHash -Algorithm SHA256 -LiteralPath $skillPath).Hash
    } else {
        $null
    }

    return [pscustomobject]@{
        LatestTicks = $latestTicks
        FileCount   = $fileCount
        SkillHash   = $skillHash
    }
}

function Get-ExternalSourceCandidates {
    param(
        [Parameter(Mandatory = $true)][string]$Command
    )

    if ($commandCatalogByCommand.ContainsKey($Command)) {
        $manifestSource = [string]$commandCatalogByCommand[$Command].sourceDir
        if (
            -not [string]::IsNullOrWhiteSpace($manifestSource) -and
            (Test-Path (Join-Path $manifestSource 'SKILL.md'))
        ) {
            return @($manifestSource)
        }
    }

    $candidateNames = @($Command)
    $hyphenated = $Command -replace '_', '-'
    if ($hyphenated -ne $Command) {
        $candidateNames += $hyphenated
    }
    $candidateNames = @($candidateNames | Select-Object -Unique)

    $hits = New-Object System.Collections.Generic.List[string]
    foreach ($root in $externalRoots) {
        foreach ($dir in Get-ChildItem -LiteralPath $root -Recurse -Directory -ErrorAction SilentlyContinue) {
            if ($candidateNames -notcontains $dir.Name) {
                continue
            }
            if (Test-Path (Join-Path $dir.FullName 'SKILL.md')) {
                [void]$hits.Add($dir.FullName)
            }
        }
    }
    if ($hits.Count -gt 0) {
        return @($hits | Select-Object -Unique)
    }

    foreach ($root in $pluginRoots) {
        foreach ($name in $candidateNames) {
            $match = Get-ChildItem -LiteralPath $root -Recurse -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -ieq $name -and (Test-Path (Join-Path $_.FullName 'SKILL.md')) } |
                Select-Object -First 1
            if ($match) {
                return @($match.FullName)
            }
        }
    }

    return @()
}

function Resolve-CanonicalSourceDir {
    param(
        [Parameter(Mandatory = $true)][string]$Command
    )

    if ($commandCatalogByCommand.ContainsKey($Command)) {
        $catalogSource = [string]$commandCatalogByCommand[$Command].sourceDir
        if (
            -not [string]::IsNullOrWhiteSpace($catalogSource) -and
            (Test-Path (Join-Path $catalogSource 'SKILL.md'))
        ) {
            return $catalogSource
        }
    }

    $externalCandidates = @(Get-ExternalSourceCandidates -Command $Command)
    if ($externalCandidates.Count -gt 0) {
        return $externalCandidates[0]
    }

    return $null
}

function Test-NeedsSkillSync {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$TargetDir
    )

    if (-not (Test-Path (Join-Path $TargetDir 'SKILL.md'))) {
        return $true
    }

    $sourceSignature = Get-SkillDirSignature -Path $SourceDir
    $targetSignature = Get-SkillDirSignature -Path $TargetDir

    if ($sourceSignature.FileCount -ne $targetSignature.FileCount) {
        return $true
    }
    if ($sourceSignature.SkillHash -ne $targetSignature.SkillHash) {
        return $true
    }
    if ($sourceSignature.LatestTicks -gt $targetSignature.LatestTicks) {
        return $true
    }

    return $false
}

function Assert-WorkspacePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    if (-not $resolvedPath.StartsWith($stateRootResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify path outside OpenClaw state root: $resolvedPath"
    }
}

function Sync-SkillDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$TargetDir
    )

    Assert-WorkspacePath -Path $TargetDir
    $targetParent = Split-Path -Parent $TargetDir
    if (-not (Test-Path $targetParent)) {
        New-Item -ItemType Directory -Force -Path $targetParent | Out-Null
    }
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    } else {
        foreach ($child in Get-ChildItem -LiteralPath $TargetDir -Force -ErrorAction SilentlyContinue) {
            try {
                Remove-Item -LiteralPath $child.FullName -Recurse -Force -ErrorAction Stop
            } catch {
            }
        }
    }

    foreach ($child in Get-ChildItem -LiteralPath $SourceDir -Force -ErrorAction SilentlyContinue) {
        Copy-Item -LiteralPath $child.FullName -Destination $TargetDir -Recurse -Force
    }

    $skillPath = Join-Path $TargetDir 'SKILL.md'
    if (Test-Path -LiteralPath $skillPath) {
        Register-OpenClawManagedFile -Path $skillPath -Kind 'workspace-skill-mirror' -Source $SourceDir -GeneratedBy 'Sync-OpenClawWorkspaceSkills.ps1'
    }
    Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
        sourceDir = $SourceDir
        targetDir = $TargetDir
        syncedAt = (Get-Date).ToString('o')
        generationId = $paths.AuthorityGenerationId
    }) -Path (Join-Path $TargetDir '.openclaw-managed.json') -Kind 'workspace-skill-mirror-metadata' -Source $SourceDir
}

$cfg = Get-Content -Raw $ConfigPath | ConvertFrom-Json
if (-not $cfg.channels.telegram -or -not $cfg.channels.telegram.customCommands) {
    if (-not $Quiet) {
        @() | ConvertTo-Json -Depth 5
    }
    exit 0
}

$results = New-Object System.Collections.ArrayList
$desiredCommands = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($entry in @($cfg.channels.telegram.customCommands)) {
    $command = ([string]$entry.command).Trim().ToLowerInvariant()
    if ($command -match '^[a-z0-9_]{1,32}$') {
        [void]$desiredCommands.Add($command)
    }
}

foreach ($workspaceRoot in $workspaceRoots) {
    $skillsRoot = Join-Path $workspaceRoot 'skills'
    if (-not (Test-Path $skillsRoot)) {
        continue
    }

    foreach ($skillDir in Get-ChildItem -LiteralPath $skillsRoot -Directory -ErrorAction SilentlyContinue) {
        $command = ([string]$skillDir.Name).Trim().ToLowerInvariant()
        if ($command -notmatch '^[a-z0-9_]{1,32}$') {
            continue
        }
        if ($desiredCommands.Contains($command)) {
            continue
        }

        Assert-WorkspacePath -Path $skillDir.FullName
        $status = 'removed-stale'
        $errorText = $null
        try {
            Remove-Item -LiteralPath $skillDir.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            $status = 'stale-remove-failed'
            $errorText = $_.Exception.Message
        }

        [void]$results.Add([pscustomobject]@{
            command       = $command
            workspaceRoot = $workspaceRoot
            sourceDir     = $null
            targetDir     = $skillDir.FullName
            status        = $status
            error         = $errorText
        })
    }
}

foreach ($entry in @($cfg.channels.telegram.customCommands)) {
    $command = ([string]$entry.command).Trim().ToLowerInvariant()
    if ($command -notmatch '^[a-z0-9_]{1,32}$') {
        continue
    }

    $canonicalSource = Resolve-CanonicalSourceDir -Command $command
    if (-not $canonicalSource) {
        [void]$results.Add([pscustomobject]@{
            command = $command
            status  = 'missing-source'
        })
        continue
    }

    $canonicalResolved = [System.IO.Path]::GetFullPath($canonicalSource)
    foreach ($workspaceRoot in $workspaceRoots) {
        $targetDir = Get-WorkspaceSkillDir -WorkspaceRoot $workspaceRoot -Command $command
        $targetResolved = [System.IO.Path]::GetFullPath($targetDir)
        $status = 'ok'

        if ($targetResolved.TrimEnd('\') -ine $canonicalResolved.TrimEnd('\')) {
            if (Test-NeedsSkillSync -SourceDir $canonicalSource -TargetDir $targetDir) {
                Sync-SkillDirectory -SourceDir $canonicalSource -TargetDir $targetDir
                $status = 'synced'
            }
        }

        [void]$results.Add([pscustomobject]@{
            command       = $command
            workspaceRoot = $workspaceRoot
            sourceDir     = $canonicalSource
            targetDir     = $targetDir
            status        = $status
        })
    }
}

if (-not $Quiet) {
    $results | ConvertTo-Json -Depth 8
}
