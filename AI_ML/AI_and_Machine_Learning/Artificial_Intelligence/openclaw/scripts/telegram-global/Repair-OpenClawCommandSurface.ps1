param(
    [string]$ConfigPath,
    [string]$MenuPriorityPath,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'

$paths = Get-OpenClawPaths
Ensure-OpenClawPathLayout -Paths $paths
if (-not $ConfigPath) { $ConfigPath = $paths.ConfigPath }
if (-not $MenuPriorityPath) { $MenuPriorityPath = $paths.MenuPriorityPath }

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$disabledCommands = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$requiredPriority = @('job', 'news', 'done', 'nnew', 'done_job', 'snap', 'clu', 'drivers', 'start', 'slash', 'ps', 'mem', 'claw', 'all')
$directWrappers = @(
    @{
        name = 'all'
        description = 'Fan a message to all 4 Telegram bot workspaces at once so each bot replies in its own chat.'
        script = Join-Path $paths.RepoRoot 'scripts\telegram-global\Invoke-OpenClawAllCommand.ps1'
        timeout = 600
    },
    @{
        name = 'nnew'
        description = 'Force fresh sessions for all 4 Telegram bots at once.'
        script = Join-Path $paths.RepoRoot 'scripts\telegram-global\Invoke-OpenClawNnewCommand.ps1'
        timeout = 300
    },
    @{
        name = 'clu'
        description = 'Show live Codex account usage from every OpenClaw Telegram bot.'
        script = Join-Path $paths.RepoRoot 'scripts\telegram-global\Invoke-OpenClawCluCommand.ps1'
        timeout = 300
    },
    @{
        name = 'snap'
        description = 'Capture a Windows desktop screenshot and send it back to Telegram.'
        script = Join-Path $paths.RepoRoot 'scripts\telegram-global\Invoke-OpenClawSnapCommand.ps1'
        timeout = 300
    }
)

function Set-NoteProperty {
    param(
        [Parameter(Mandatory = $true)]$Target,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value
    )

    if ($Target.PSObject.Properties.Name -contains $Name) {
        $Target.$Name = $Value
    } else {
        $Target | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Ensure-ObjectProperty {
    param(
        [Parameter(Mandatory = $true)]$Target,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ($Target.PSObject.Properties.Name -notcontains $Name -or $null -eq $Target.$Name) {
        Set-NoteProperty -Target $Target -Name $Name -Value ([pscustomobject]@{})
    }

    return $Target.$Name
}

function Normalize-CommandName {
    param([AllowNull()][string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return $null
    }

    $normalized = ([string]$Name).Trim().ToLowerInvariant()
    $normalized = $normalized -replace '^[/$]+', ''
    $normalized = $normalized -replace '\.md$', ''
    $normalized = $normalized -replace '[:/\\\s-]+', '_'
    $normalized = $normalized -replace '[^a-z0-9_]', ''
    $normalized = $normalized -replace '_+', '_'
    $normalized = $normalized.Trim('_')

    if ($normalized -notmatch '^[a-z0-9][a-z0-9_]*$') {
        return $null
    }

    if ($normalized.Length -le 32) {
        return $normalized
    }

    $sha1 = [System.Security.Cryptography.SHA1]::Create()
    try {
        $hashBytes = $sha1.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($normalized))
    } finally {
        $sha1.Dispose()
    }

    $suffix = ([System.BitConverter]::ToString($hashBytes)).Replace('-', '').ToLowerInvariant().Substring(0, 4)
    $headLength = 32 - 1 - $suffix.Length
    $head = $normalized.Substring(0, [Math]::Min($normalized.Length, $headLength)).TrimEnd('_')
    if ([string]::IsNullOrWhiteSpace($head)) {
        $head = 'cmd'
    }

    return ("{0}_{1}" -f $head, $suffix).Trim('_')
}

function Normalize-Description {
    param(
        [AllowNull()][string]$Description,
        [Parameter(Mandatory = $true)][string]$Command
    )

    $fallback = "OpenClaw command: $($Command -replace '_', ' ')"
    if ([string]::IsNullOrWhiteSpace($Description)) {
        return $fallback
    }

    $text = ([string]$Description) -replace '\s+', ' '
    $text = $text.Trim().Trim("'").Trim('"').Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $fallback
    }

    if ($text.Length -gt 180) {
        $text = $text.Substring(0, 180).TrimEnd()
    }

    return $text
}

function Get-FrontMatterValue {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $raw = Get-Content -Raw -LiteralPath $Path -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $null
    }

    $escaped = [regex]::Escape($Name)
    $match = [regex]::Match($raw, "(?im)^\s*$escaped\s*:\s*(?<value>.+?)\s*$")
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups['value'].Value.Trim().Trim("'").Trim('"').Trim()
}

function Get-FirstBodyLine {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $inFrontMatter = $false
    $frontMatterStarted = $false
    foreach ($line in @(Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)) {
        $trimmed = ([string]$line).Trim()
        if (-not $frontMatterStarted -and $trimmed -eq '---') {
            $frontMatterStarted = $true
            $inFrontMatter = $true
            continue
        }
        if ($inFrontMatter) {
            if ($trimmed -eq '---') {
                $inFrontMatter = $false
            }
            continue
        }
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith('#') -or $trimmed.StartsWith('-')) {
            continue
        }
        return $trimmed
    }

    return $null
}

function Assert-StatePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $resolvedState = [System.IO.Path]::GetFullPath($paths.StateRoot).TrimEnd('\') + '\'
    $resolved = [System.IO.Path]::GetFullPath($Path)
    if (-not $resolved.StartsWith($resolvedState, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to modify path outside OpenClaw state root: $resolved"
    }
}

function Remove-CommandDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$Command
    )

    $dir = Join-Path $Root $Command
    if (-not (Test-Path -LiteralPath $dir)) {
        return $false
    }

    Assert-StatePath -Path $dir
    Remove-Item -LiteralPath $dir -Recurse -Force
    return $true
}

function Copy-SkillDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$TargetDir,
        [switch]$Overwrite
    )

    if (-not (Test-Path -LiteralPath (Join-Path $SourceDir 'SKILL.md'))) {
        return $false
    }

    Assert-StatePath -Path $TargetDir
    if ((Test-Path -LiteralPath $TargetDir) -and -not $Overwrite) {
        return $false
    }

    if (Test-Path -LiteralPath $TargetDir) {
        Remove-Item -LiteralPath $TargetDir -Recurse -Force
    }

    $parent = Split-Path -Parent $TargetDir
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Copy-Item -LiteralPath $SourceDir -Destination $TargetDir -Recurse -Force
    return $true
}

function New-ExecSkillBody {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Description,
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][int]$Timeout
    )

    $fixedCommand = 'powershell -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $ScriptPath
    @"
---
name: $Name
description: $Description
userInvocable: true
disable-model-invocation: true
command-dispatch: tool
command-tool: exec
command-fixed-args: '$fixedCommand'
command-yield-ms: 180000
command-timeout-sec: $Timeout
command-background: false
---

# /$Name

Execute this fixed command directly and return the raw output in Telegram.

Fixed command: $fixedCommand

Rules:

- Pass any slash arguments after the fixed command unchanged.
- Do not paraphrase the output.
- Do not add generic acknowledgements, idle text, or heartbeat text.
- Return the command output directly.
"@
}

function Write-DirectWrapper {
    param([Parameter(Mandatory = $true)]$Wrapper)

    $dir = Join-Path $paths.GeneratedCustomCommandsRoot ([string]$Wrapper.name)
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $skillPath = Join-Path $dir 'SKILL.md'
    $body = New-ExecSkillBody -Name ([string]$Wrapper.name) -Description ([string]$Wrapper.description) -ScriptPath ([string]$Wrapper.script) -Timeout ([int]$Wrapper.timeout)
    [System.IO.File]::WriteAllText($skillPath, $body, $script:utf8NoBom)
    Register-OpenClawManagedFile -Path $skillPath -Kind 'generated-telegram-skill' -Source ([string]$Wrapper.name) -GeneratedBy 'Repair-OpenClawCommandSurface.ps1'
    return $dir
}

function Add-CatalogCandidate {
    param(
        [Parameter(Mandatory = $true)]$CandidateMap,
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$SourceKind,
        [Parameter(Mandatory = $true)][int]$SourceRank,
        [AllowNull()][string]$Description
    )

    if ($script:disabledCommands.Contains($Command)) {
        return
    }

    if (-not $CandidateMap.ContainsKey($Command)) {
        $CandidateMap[$Command] = New-Object System.Collections.ArrayList
    }

    [void]$CandidateMap[$Command].Add([pscustomobject]@{
        command = $Command
        description = Normalize-Description -Description $Description -Command $Command
        sourceKind = $SourceKind
        sourceDir = $SourceDir
        sourcePath = $SourcePath
        originPath = ''
        sourceRank = $SourceRank
        lastWriteTicks = (Get-Item -LiteralPath $SourcePath).LastWriteTimeUtc.Ticks
    })
}

function Add-SkillCandidatesFromRoot {
    param(
        [Parameter(Mandatory = $true)]$CandidateMap,
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][string]$SourceKind,
        [Parameter(Mandatory = $true)][int]$SourceRank
    )

    if (-not (Test-Path -LiteralPath $Root)) {
        return
    }

    foreach ($skillFile in Get-ChildItem -LiteralPath $Root -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue) {
        $rawName = Get-FrontMatterValue -Path $skillFile.FullName -Name 'name'
        if ([string]::IsNullOrWhiteSpace($rawName)) {
            $rawName = $skillFile.Directory.Name
        }

        $command = Normalize-CommandName -Name $rawName
        if (-not $command) {
            continue
        }

        $description = Get-FrontMatterValue -Path $skillFile.FullName -Name 'description'
        if ([string]::IsNullOrWhiteSpace($description)) {
            $description = Get-FirstBodyLine -Path $skillFile.FullName
        }

        Add-CatalogCandidate -CandidateMap $CandidateMap -Command $command -SourceDir $skillFile.Directory.FullName -SourcePath $skillFile.FullName -SourceKind $SourceKind -SourceRank $SourceRank -Description $description
    }
}

function Get-ExistingPriorityCommands {
    $commands = @()
    if (Test-Path -LiteralPath $MenuPriorityPath) {
        try {
            $priorityState = Get-Content -Raw -LiteralPath $MenuPriorityPath | ConvertFrom-Json
            if ($priorityState -and $priorityState.commands) {
                $commands += @($priorityState.commands)
            }
        } catch {
        }
    }

    try {
        $cfg = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
        if ($cfg.channels.telegram.PSObject.Properties.Name -contains 'menuPriorityCommands') {
            $commands += @($cfg.channels.telegram.menuPriorityCommands)
        }
    } catch {
    }

    return @($commands)
}

function Read-DisabledCommands {
    if (-not (Test-Path -LiteralPath $paths.SlashStatePath)) {
        return
    }

    try {
        $state = Get-Content -Raw -LiteralPath $paths.SlashStatePath | ConvertFrom-Json
        foreach ($entry in @($state.disabledCommands)) {
            $normalized = Normalize-CommandName -Name ([string]$entry)
            if ($normalized) {
                [void]$script:disabledCommands.Add($normalized)
            }
        }
    } catch {
    }
}

function Restore-WorkspacePayloadSkills {
    $sourceBase = Join-Path $paths.RepoRoot 'Setup\payload\openclaw-home'
    if (-not (Test-Path -LiteralPath $sourceBase)) {
        return 0
    }

    $restored = 0
    foreach ($workspaceRoot in @($paths.WorkspaceRoots)) {
        $workspaceName = Split-Path -Leaf $workspaceRoot
        $sourceSkills = Join-Path $sourceBase "$workspaceName\skills"
        $targetSkills = Join-Path $workspaceRoot 'skills'
        if (-not (Test-Path -LiteralPath $sourceSkills)) {
            continue
        }

        New-Item -ItemType Directory -Force -Path $targetSkills | Out-Null
        foreach ($sourceDir in Get-ChildItem -LiteralPath $sourceSkills -Directory -ErrorAction SilentlyContinue) {
            $command = Normalize-CommandName -Name $sourceDir.Name
            if (-not $command -or $script:disabledCommands.Contains($command)) {
                continue
            }
            $targetDir = Join-Path $targetSkills $command
            if (Copy-SkillDirectory -SourceDir $sourceDir.FullName -TargetDir $targetDir) {
                $restored++
            }
        }
    }

    return $restored
}

Read-DisabledCommands
[void]$disabledCommands.Add('new')

$removedDisabled = 0
foreach ($disabled in @($disabledCommands)) {
    if (Remove-CommandDirectory -Root $paths.GeneratedCustomCommandsRoot -Command $disabled) {
        $removedDisabled++
    }
    foreach ($workspaceRoot in @($paths.WorkspaceRoots)) {
        $skillsRoot = Join-Path $workspaceRoot 'skills'
        if (Remove-CommandDirectory -Root $skillsRoot -Command $disabled) {
            $removedDisabled++
        }
    }
}

$restoredFromPayload = Restore-WorkspacePayloadSkills
$wrapperDirs = @{}
foreach ($wrapper in $directWrappers) {
    $wrapperDirs[[string]$wrapper.name] = Write-DirectWrapper -Wrapper $wrapper
}

foreach ($workspaceRoot in @($paths.WorkspaceRoots)) {
    foreach ($entry in $wrapperDirs.GetEnumerator()) {
        $target = Join-Path (Join-Path $workspaceRoot 'skills') ([string]$entry.Key)
        [void](Copy-SkillDirectory -SourceDir ([string]$entry.Value) -TargetDir $target -Overwrite)
    }
}

$candidateMap = @{}
Add-SkillCandidatesFromRoot -CandidateMap $candidateMap -Root $paths.GeneratedCustomCommandsRoot -SourceKind 'generated-custom-command' -SourceRank 900
Add-SkillCandidatesFromRoot -CandidateMap $candidateMap -Root (Join-Path $paths.WorkspaceRoots[0] 'skills') -SourceKind 'openclaw-workspace' -SourceRank 700
for ($i = 1; $i -lt @($paths.WorkspaceRoots).Count; $i++) {
    Add-SkillCandidatesFromRoot -CandidateMap $candidateMap -Root (Join-Path $paths.WorkspaceRoots[$i] 'skills') -SourceKind 'openclaw-workspace' -SourceRank 650
}

$entries = @()
foreach ($command in @($candidateMap.Keys | Sort-Object)) {
    $winner = @($candidateMap[$command] | Sort-Object @{ Expression = { $_.sourceRank }; Descending = $true }, @{ Expression = { $_.lastWriteTicks }; Descending = $true } | Select-Object -First 1)[0]
    if ($winner) {
        $entries += [pscustomobject]@{
            command = [string]$winner.command
            description = [string]$winner.description
            sourceKind = [string]$winner.sourceKind
            sourceDir = [string]$winner.sourceDir
            sourcePath = [string]$winner.sourcePath
            originPath = [string]$winner.originPath
            sourceRank = [int]$winner.sourceRank
        }
    }
}

if (@($entries | Where-Object { $_.command -eq 'new' }).Count -gt 0) {
    throw 'Repair failed: /new is still present in generated catalog entries.'
}

$config = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
$channels = Ensure-ObjectProperty -Target $config -Name 'channels'
$telegram = Ensure-ObjectProperty -Target $channels -Name 'telegram'
Set-NoteProperty -Target $telegram -Name 'customCommands' -Value @($entries | Sort-Object command | ForEach-Object {
    [pscustomobject]@{
        command = $_.command
        description = $_.description
    }
})
if ($telegram.PSObject.Properties.Name -contains 'menuPriorityCommands') {
    [void]$telegram.PSObject.Properties.Remove('menuPriorityCommands')
}

$tools = Ensure-ObjectProperty -Target $config -Name 'tools'
Set-NoteProperty -Target $tools -Name 'profile' -Value 'full'
$exec = Ensure-ObjectProperty -Target $tools -Name 'exec'
Set-NoteProperty -Target $exec -Name 'ask' -Value 'off'
$elevated = Ensure-ObjectProperty -Target $tools -Name 'elevated'
Set-NoteProperty -Target $elevated -Name 'enabled' -Value $true
$message = Ensure-ObjectProperty -Target $tools -Name 'message'
Set-NoteProperty -Target $message -Name 'allowCrossContextSend' -Value $true
$crossContext = Ensure-ObjectProperty -Target $message -Name 'crossContext'
Set-NoteProperty -Target $crossContext -Name 'allowWithinProvider' -Value $true
Set-NoteProperty -Target $crossContext -Name 'allowAcrossProviders' -Value $true

$browser = Ensure-ObjectProperty -Target $config -Name 'browser'
Set-NoteProperty -Target $browser -Name 'enabled' -Value $true
Set-NoteProperty -Target $browser -Name 'evaluateEnabled' -Value $true
if ($browser.PSObject.Properties.Name -contains 'evaluate') {
    [void]$browser.PSObject.Properties.Remove('evaluate')
}

[void](Save-OpenClawConfigFile -Config $config -LastWriter 'Repair-OpenClawCommandSurface')

$priority = New-Object System.Collections.Generic.List[string]
foreach ($name in @($requiredPriority + (Get-ExistingPriorityCommands))) {
    $normalized = Normalize-CommandName -Name ([string]$name)
    if (-not $normalized -or $disabledCommands.Contains($normalized)) {
        continue
    }
    if (@($entries | Where-Object { $_.command -eq $normalized }).Count -eq 0) {
        continue
    }
    if (-not $priority.Contains($normalized)) {
        [void]$priority.Add($normalized)
    }
}

Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
    commands = @($priority)
}) -Path $MenuPriorityPath -Kind 'menu-priority' -Source 'Repair-OpenClawCommandSurface.ps1'

Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
    disabledCommands = @($disabledCommands | Sort-Object)
}) -Path $paths.SlashStatePath -Kind 'slash-state' -Source 'Repair-OpenClawCommandSurface.ps1'

Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
    generatedAt = (Get-Date).ToUniversalTime().ToString('o')
    commandCount = @($entries).Count
    entries = @($entries | Sort-Object command)
}) -Path $paths.CommandCatalogPath -Kind 'command-catalog' -Source 'Repair-OpenClawCommandSurface.ps1'

$workspaceCounts = @()
foreach ($workspaceRoot in @($paths.WorkspaceRoots)) {
    $skillsRoot = Join-Path $workspaceRoot 'skills'
    $workspaceCounts += [pscustomobject]@{
        workspace = Split-Path -Leaf $workspaceRoot
        count = @(Get-ChildItem -LiteralPath $skillsRoot -Directory -ErrorAction SilentlyContinue).Count
        hasNew = Test-Path -LiteralPath (Join-Path $skillsRoot 'new')
    }
}

$result = [pscustomobject]@{
    ok = $true
    commandCount = @($entries).Count
    menuPriorityCount = @($priority).Count
    disabledCommands = @($disabledCommands | Sort-Object)
    removedDisabledDirectories = $removedDisabled
    restoredFromPayload = $restoredFromPayload
    directWrappers = @($directWrappers | ForEach-Object { $_.name })
    workspaceCounts = $workspaceCounts
    catalogPath = $paths.CommandCatalogPath
    configPath = $ConfigPath
    menuPriorityPath = $MenuPriorityPath
}

if (-not $Quiet) {
    $result | ConvertTo-Json -Depth 10
}
