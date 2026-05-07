param(
    [string]$ConfigPath,
    [string]$MenuPriorityPath,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$repairScript = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'Repair-OpenClawCommandSurface.ps1'
if ((Test-Path -LiteralPath $repairScript) -and -not $env:OPENCLAW_LEGACY_COMMAND_CATALOG_SYNC) {
    $repairArgs = @()
    if ($ConfigPath) { $repairArgs += @('-ConfigPath', $ConfigPath) }
    if ($MenuPriorityPath) { $repairArgs += @('-MenuPriorityPath', $MenuPriorityPath) }
    if ($Quiet) { $repairArgs += '-Quiet' }
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $repairScript @repairArgs
    exit $LASTEXITCODE
}
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
if (-not $ConfigPath) { $ConfigPath = $paths.ConfigPath }
if (-not $MenuPriorityPath) { $MenuPriorityPath = $paths.MenuPriorityPath }

$authorityCheck = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
if (-not $authorityCheck.passed) {
    $failed = @($authorityCheck.checks | Where-Object { -not $_.passed } | ForEach-Object { $_.name })
    throw "OpenClaw authority drift blocks command catalog sync: $($failed -join ', ')"
}

$userHome = $env:USERPROFILE
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$slashStatePath = $paths.SlashStatePath
$syncMenuScript = Join-Path $paths.RepoRoot 'scripts\telegram-global\Sync-TelegramMenu.ps1'
$workspaceSkillSyncScript = Join-Path $paths.RepoRoot 'scripts\telegram-global\Sync-OpenClawWorkspaceSkills.ps1'
$generatedCustomCommandsRoot = $paths.GeneratedCustomCommandsRoot
$commandDescriptionMaxChars = 180
$heartbeatAccountByAgent = @{
    main      = 'bot1'
    session2  = 'bot2'
    openclaw  = 'openclaw'
    openclaw4 = 'openclaw4'
}
$protectedCommands = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(
    'new',
    'nnew',
    'all',
    'claw',
    'slash',
    'reset',
    'session_reset',
    'sessions_reset',
    'start',
    'until_done',
    'verification_loop',
    'strategic_compact'
) | ForEach-Object { [void]$protectedCommands.Add($_) }

function Save-Json {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $json = $Object | ConvertTo-Json -Depth 100
    for ($attempt = 1; $attempt -le 12; $attempt++) {
        $tempPath = Join-Path $parent ("{0}.{1}.tmp" -f ([System.IO.Path]::GetFileName($Path)), ([guid]::NewGuid().ToString('N')))
        $backupPath = Join-Path $parent ("{0}.{1}.bak" -f ([System.IO.Path]::GetFileName($Path)), ([guid]::NewGuid().ToString('N')))
        try {
            [System.IO.File]::WriteAllText($tempPath, $json, $script:utf8NoBom)
            if (Test-Path -LiteralPath $Path) {
                [System.IO.File]::Replace($tempPath, $Path, $backupPath, $true)
                Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
            } else {
                Move-Item -LiteralPath $tempPath -Destination $Path -Force
            }
            return
        } catch {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
            if ($attempt -eq 12) { throw }
            Start-Sleep -Milliseconds (150 * $attempt)
        }
    }
}

function Save-Text {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    [System.IO.File]::WriteAllText($Path, $Content, $script:utf8NoBom)
}

function Ensure-RuntimeSkillCompatibilityWrappers {
    param(
        [Parameter(Mandatory = $true)][string]$RuntimeSkillsRoot,
        [Parameter(Mandatory = $true)]$ManifestEntries
    )

    foreach ($entry in @($ManifestEntries)) {
        $command = [string]$entry.command
        $sourcePath = [string]$entry.sourcePath
        if ([string]::IsNullOrWhiteSpace($command) -or [string]::IsNullOrWhiteSpace($sourcePath)) {
            continue
        }

        $runtimeSkillPath = Join-Path (Join-Path $RuntimeSkillsRoot $command) 'SKILL.md'
        if (Test-Path -LiteralPath $runtimeSkillPath) {
            continue
        }

        $description = Normalize-CommandDescription -Description ([string]$entry.description) -Command $command
        $sourceLiteral = '`' + $sourcePath + '`'
        $content = @"
---
name: $command
description: $description
userInvocable: true
---

# /$command

Runtime compatibility wrapper for the OpenClaw toolchain.

The authoritative skill for this command is at $sourceLiteral.

Follow that authoritative skill exactly instead of inventing alternate behavior.
"@

        Save-Text -Path $runtimeSkillPath -Content $content
    }
}

function Get-DisabledSlashCommands {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    if (-not (Test-Path $Path)) {
        return $set
    }

    try {
        $state = Get-Content -Raw $Path | ConvertFrom-Json
    } catch {
        return $set
    }

    foreach ($entry in @($state.disabledCommands)) {
        $normalized = Normalize-CommandName -Name ([string]$entry)
        if ($normalized) {
            [void]$set.Add($normalized)
        }
    }

    return ,$set
}

function Get-ConfiguredPriorityCommands {
    param(
        [Parameter(Mandatory = $true)]$TelegramConfig,
        [Parameter(Mandatory = $true)][string]$PriorityPath
    )

    if (Test-Path $PriorityPath) {
        try {
            $priorityState = Get-Content -Raw $PriorityPath | ConvertFrom-Json
            if ($priorityState -and $priorityState.commands) {
                return @($priorityState.commands)
            }
        } catch {
        }
    }

    if ($TelegramConfig.PSObject.Properties.Name -contains 'menuPriorityCommands') {
        return @($TelegramConfig.menuPriorityCommands)
    }

    return @()
}

function Add-NormalizedCommandToSet {
    param(
        [System.Collections.Generic.HashSet[string]]$Set,
        [AllowNull()][string]$CommandName,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$DisabledCommands
    )

    $normalized = Normalize-CommandName -Name $CommandName
    if (-not $normalized) {
        return
    }
    if ($DisabledCommands.Contains($normalized)) {
        return
    }

    [void]$Set.Add($normalized)
}

function Get-CuratedTelegramCommandSet {
    param(
        [Parameter(Mandatory = $true)]$TelegramConfig,
        [Parameter(Mandatory = $true)][string]$PriorityPath,
        [Parameter(Mandatory = $true)][string]$GeneratedCustomCommandsRoot,
        [Parameter(Mandatory = $true)]$ExistingCommands,
        [Parameter(Mandatory = $true)][System.Collections.Generic.HashSet[string]]$DisabledCommands
    )

    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($entry in @(Get-ConfiguredPriorityCommands -TelegramConfig $TelegramConfig -PriorityPath $PriorityPath)) {
        Add-NormalizedCommandToSet -Set $set -CommandName ([string]$entry) -DisabledCommands $DisabledCommands
    }

    if (Test-Path $GeneratedCustomCommandsRoot) {
        foreach ($skillFile in Get-ChildItem -LiteralPath $GeneratedCustomCommandsRoot -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue) {
            Add-NormalizedCommandToSet -Set $set -CommandName ([string]$skillFile.Directory.Name) -DisabledCommands $DisabledCommands
        }
    }

    if ($set.Count -eq 0) {
        foreach ($entry in @($ExistingCommands)) {
            if (-not $entry.command) {
                continue
            }
            Add-NormalizedCommandToSet -Set $set -CommandName ([string]$entry.command) -DisabledCommands $DisabledCommands
        }
    }

    return $set
}

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
    param(
        [AllowNull()][string]$Name
    )

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

function Get-MarkdownFrontMatter {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $data = @{}
    if (-not (Test-Path $Path)) {
        return $data
    }

    $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return $data
    }
    $normalized = $raw -replace "^\uFEFF", ''
    if ($normalized -notmatch '^(?s)---\r?\n(.*?)\r?\n---(?:\r?\n|$)') {
        return $data
    }

    $lines = @($matches[1] -split '\r?\n')
    foreach ($line in $lines) {
        if ($line -match '^\s*([A-Za-z0-9_-]+)\s*:\s*(.+?)\s*$') {
            $data[$matches[1].ToLowerInvariant()] = $matches[2].Trim()
        }
    }

    return $data
}

function Get-SkillFrontMatterStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path $Path)) {
        return [pscustomobject]@{
            hasOpening = $false
            hasClosing = $false
            isValid    = $false
        }
    }

    $raw = Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [pscustomobject]@{
            hasOpening = $false
            hasClosing = $false
            isValid    = $false
        }
    }

    $normalized = $raw -replace "^\uFEFF", ''
    $hasOpening = $normalized -match '^(?s)---(?:\r?\n|$)'
    if (-not $hasOpening) {
        return [pscustomobject]@{
            hasOpening = $false
            hasClosing = $false
            isValid    = $false
        }
    }

    $hasClosing = $normalized -match '^(?s)---\r?\n.*?\r?\n---(?:\r?\n|$)'

    return [pscustomobject]@{
        hasOpening = $true
        hasClosing = $hasClosing
        isValid    = $hasClosing
    }
}

function Get-MarkdownFirstBodyLine {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    $lines = @(Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue)
    $inFrontMatter = $false
    $frontMatterStarted = $false

    foreach ($rawLine in $lines) {
        $line = [string]$rawLine
        $trimmed = $line.Trim()

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
        if ([string]::IsNullOrWhiteSpace($trimmed)) {
            continue
        }
        if ($trimmed -match '^#') {
            continue
        }
        if ($trimmed -match '^[-*]\s+') {
            continue
        }
        return $trimmed
    }

    return $null
}

function Normalize-CommandDescription {
    param(
        [AllowNull()][string]$Description,
        [AllowNull()][string]$Command
    )

    $fallback = if ($Command) {
        "OpenClaw command: $($Command -replace '_', ' ')"
    } else {
        'OpenClaw command'
    }

    if ([string]::IsNullOrWhiteSpace($Description)) {
        return $fallback
    }

    $normalized = [string]$Description
    $normalized = $normalized -replace '\s+', ' '
    $normalized = $normalized.Trim()

    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $fallback
    }

    if ($normalized.Length -gt $script:commandDescriptionMaxChars) {
        $normalized = $normalized.Substring(0, $script:commandDescriptionMaxChars).TrimEnd()
    }

    return $normalized
}

function ConvertTo-YamlSingleQuotedScalar {
    param(
        [AllowNull()][string]$Value
    )

    if ($null -eq $Value) {
        return "''"
    }

    return "'" + ($Value -replace "'", "''") + "'"
}

function Get-ImmediateExecCommand {
    param(
        [AllowNull()][string]$SourceBody
    )

    if ([string]::IsNullOrWhiteSpace($SourceBody)) {
        return $null
    }

    $match = [regex]::Match($SourceBody, '(?im)^\s*Execute immediately:\s*`(?<command>[^`]+)`\s*$')
    if (-not $match.Success) {
        return $null
    }

    $command = $match.Groups['command'].Value.Trim()
    if ([string]::IsNullOrWhiteSpace($command)) {
        return $null
    }

    if ($command -match '^(powershell(?:\.exe)?)(\s+)(.*)$' -and $command -notmatch '(?i)(?:^|\s)-NoProfile(?:\s|$)') {
        $command = "$($Matches[1]) -NoProfile $($Matches[3].TrimStart())"
    }

    return $command
}

function New-CatalogCandidate {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$SourceDir,
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [Parameter(Mandatory = $true)][string]$SourceKind,
        [Parameter(Mandatory = $true)][int]$SourceRank,
        [AllowNull()][string]$Description,
        [AllowNull()][string]$OriginPath,
        [Parameter(Mandatory = $true)][long]$LastWriteTicks
    )

    return [pscustomobject]@{
        Command        = $Command
        SourceDir      = $SourceDir
        SourcePath     = $SourcePath
        SourceKind     = $SourceKind
        SourceRank     = $SourceRank
        Description    = Normalize-CommandDescription -Description $Description -Command $Command
        OriginPath     = $OriginPath
        LastWriteTicks = $LastWriteTicks
    }
}

function Add-CatalogCandidate {
    param(
        [Parameter(Mandatory = $true)]$CandidateMap,
        [Parameter(Mandatory = $true)]$Candidate
    )

    if (-not $CandidateMap.ContainsKey($Candidate.Command)) {
        $CandidateMap[$Candidate.Command] = New-Object System.Collections.ArrayList
    }

    [void]$CandidateMap[$Candidate.Command].Add($Candidate)
}

function Get-SkillCandidatesFromRoots {
    param(
        [Parameter(Mandatory = $true)][string[]]$Roots,
        [Parameter(Mandatory = $true)][string]$SourceKind,
        [Parameter(Mandatory = $true)][int]$SourceRank,
        [Parameter(Mandatory = $true)]$CandidateMap,
        [Parameter(Mandatory = $true)]$InvalidEntries
    )

    foreach ($root in @($Roots | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique)) {
        foreach ($skillFile in Get-ChildItem -LiteralPath $root -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue) {
            $frontMatterStatus = Get-SkillFrontMatterStatus -Path $skillFile.FullName
            if (-not $frontMatterStatus.isValid) {
                [void]$InvalidEntries.Add([pscustomobject]@{
                    sourceKind = $SourceKind
                    sourcePath = $skillFile.FullName
                    rawName    = $skillFile.Directory.Name
                    reason     = if ($frontMatterStatus.hasOpening) { 'unterminated-frontmatter' } else { 'missing-frontmatter' }
                })
                continue
            }

            $frontMatter = Get-MarkdownFrontMatter -Path $skillFile.FullName
            $rawName = if ($frontMatter.ContainsKey('name') -and -not [string]::IsNullOrWhiteSpace($frontMatter['name'])) {
                [string]$frontMatter['name']
            } else {
                [string]$skillFile.Directory.Name
            }
            $command = Normalize-CommandName -Name $rawName
            if (-not $command) {
                [void]$InvalidEntries.Add([pscustomobject]@{
                    sourceKind = $SourceKind
                    sourcePath = $skillFile.FullName
                    rawName    = $rawName
                })
                continue
            }

            $description = if ($frontMatter.ContainsKey('description') -and -not [string]::IsNullOrWhiteSpace($frontMatter['description'])) {
                [string]$frontMatter['description']
            } else {
                Get-MarkdownFirstBodyLine -Path $skillFile.FullName
            }

            Add-CatalogCandidate -CandidateMap $CandidateMap -Candidate (New-CatalogCandidate `
                -Command $command `
                -SourceDir $skillFile.Directory.FullName `
                -SourcePath $skillFile.FullName `
                -SourceKind $SourceKind `
                -SourceRank $SourceRank `
                -Description $description `
                -OriginPath $null `
                -LastWriteTicks $skillFile.LastWriteTimeUtc.Ticks)
        }
    }
}

function Test-ClaudeCommandEnabled {
    param(
        [Parameter(Mandatory = $true)][string]$CommandsRoot,
        [Parameter(Mandatory = $true)][string]$FilePath
    )

    $relative = $FilePath.Substring($CommandsRoot.Length).TrimStart('\')
    if ([string]::IsNullOrWhiteSpace($relative)) {
        return $true
    }

    $segments = @($relative -split '[\\/]')
    if ($segments.Count -le 1) {
        return $true
    }

    for ($i = 0; $i -lt ($segments.Count - 1); $i++) {
        if ($segments[$i] -like '_*') {
            return $false
        }
    }

    return $true
}

function Ensure-ClaudeCommandWrapper {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [Parameter(Mandatory = $true)][string]$SourceFile,
        [Parameter(Mandatory = $true)][string]$WrapperRoot
    )

    $targetDir = Join-Path $WrapperRoot $Command
    $targetFile = Join-Path $targetDir 'SKILL.md'
    $sourceRaw = Get-Content -Raw -LiteralPath $SourceFile
    $sourceBody = ($sourceRaw -replace "^\uFEFF", '').Trim()
    if ($sourceBody -match '(?s)^---\r?\n.*?\r?\n---\r?\n(.*)$') {
        $sourceBody = $Matches[1].Trim()
    }
    $sourceFileLiteral = '`' + $SourceFile + '`'
    $immediateExecCommand = Get-ImmediateExecCommand -SourceBody $sourceBody
    $dispatchFrontMatter = ''
    if ($immediateExecCommand) {
        $dispatchFrontMatter = @"
disable-model-invocation: true
command-dispatch: tool
command-tool: exec
command-fixed-args: $(ConvertTo-YamlSingleQuotedScalar -Value $immediateExecCommand)
"@
    }
    $body = @"
---
name: $Command
description: Mirror Claude command $Command for Telegram slash invocation.
userInvocable: true
$dispatchFrontMatter
---

# /$Command

Use the Claude command file at $sourceFileLiteral as the authoritative workflow for this Telegram slash command.

## Rules

- Treat this as a strict slash-command invocation, not a generic Telegram chat request.
- Execute the authoritative command content below directly instead of paraphrasing it.
- Do not fall back to generic acknowledgements, idle text, or `HEARTBEAT_OK` unless the command content explicitly requires that exact reply.
- If the authoritative content includes a `Usage:` line and the user did not supply required arguments, return only that usage line.
- If it references files or scripts under `C:\Users\micha\.claude`, use those exact paths.
- If it references Claude-only tool names, use the closest live OpenClaw/Codex equivalent instead of ignoring the command.
- If it references `mcp__claude-in-chrome__*`, prefer the `computer-use-mcp` skill and the available browser-control tools in this session.
- If it references `C:\Users\micha\.openclaw\...`, prefer the real filesystem target under `F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\openclaw-home\...` when executing it, because the `.openclaw` symlink can be rejected by exec path safety.
- If the workflow changes shared Telegram slash-command behavior, resync the global catalog with:
  `powershell -NoProfile -ExecutionPolicy Bypass -File "$syncMenuScript"`

## Authoritative command content

$sourceBody
"@

    $existingBody = if (Test-Path $targetFile) { Get-Content -Raw -LiteralPath $targetFile } else { $null }
    if ($existingBody -ne $body) {
        Save-Text -Path $targetFile -Content $body
    }

    return $targetFile
}

function Get-ClaudeCommandCandidates {
    param(
        [Parameter(Mandatory = $true)][string]$CommandsRoot,
        [Parameter(Mandatory = $true)][string]$WrapperRoot,
        [Parameter(Mandatory = $true)]$CandidateMap,
        [Parameter(Mandatory = $true)]$InvalidEntries
    )

    if (-not (Test-Path $CommandsRoot)) {
        return
    }

    foreach ($commandFile in Get-ChildItem -LiteralPath $CommandsRoot -Recurse -File -Filter '*.md' -ErrorAction SilentlyContinue) {
        if (-not (Test-ClaudeCommandEnabled -CommandsRoot $CommandsRoot -FilePath $commandFile.FullName)) {
            continue
        }

        $frontMatter = Get-MarkdownFrontMatter -Path $commandFile.FullName
        $rawName = if ($frontMatter.ContainsKey('name') -and -not [string]::IsNullOrWhiteSpace($frontMatter['name'])) {
            [string]$frontMatter['name']
        } else {
            [string]$commandFile.BaseName
        }
        $command = Normalize-CommandName -Name $rawName
        if (-not $command) {
            [void]$InvalidEntries.Add([pscustomobject]@{
                sourceKind = 'claude-command'
                sourcePath = $commandFile.FullName
                rawName    = $rawName
            })
            continue
        }

        $wrapperSkillPath = Ensure-ClaudeCommandWrapper -Command $command -SourceFile $commandFile.FullName -WrapperRoot $WrapperRoot
        $description = Get-MarkdownFirstBodyLine -Path $commandFile.FullName
        if ([string]::IsNullOrWhiteSpace($description)) {
            $description = "Mirror Claude command $command for Telegram."
        }

        Add-CatalogCandidate -CandidateMap $CandidateMap -Candidate (New-CatalogCandidate `
            -Command $command `
            -SourceDir (Split-Path -Parent $wrapperSkillPath) `
            -SourcePath $wrapperSkillPath `
            -SourceKind 'claude-command' `
            -SourceRank 600 `
            -Description $description `
            -OriginPath $commandFile.FullName `
            -LastWriteTicks ([Math]::Max((Get-Item -LiteralPath $wrapperSkillPath).LastWriteTimeUtc.Ticks, $commandFile.LastWriteTimeUtc.Ticks)))
    }
}

function Select-CanonicalCandidate {
    param(
        [Parameter(Mandatory = $true)]$Candidates
    )

    $bestBySourceDir = @{}
    foreach ($candidate in @($Candidates)) {
        if (-not $candidate.SourceDir) {
            continue
        }

        $key = [System.IO.Path]::GetFullPath($candidate.SourceDir)
        if (-not $bestBySourceDir.ContainsKey($key)) {
            $bestBySourceDir[$key] = $candidate
            continue
        }

        $existing = $bestBySourceDir[$key]
        $isBetter = $false
        if ($candidate.SourceRank -gt $existing.SourceRank) {
            $isBetter = $true
        } elseif ($candidate.SourceRank -eq $existing.SourceRank -and $candidate.LastWriteTicks -gt $existing.LastWriteTicks) {
            $isBetter = $true
        } elseif (
            $candidate.SourceRank -eq $existing.SourceRank -and
            $candidate.LastWriteTicks -eq $existing.LastWriteTicks -and
            [string]$candidate.SourcePath -lt [string]$existing.SourcePath
        ) {
            $isBetter = $true
        }

        if ($isBetter) {
            $bestBySourceDir[$key] = $candidate
        }
    }

    return @($bestBySourceDir.Values |
        Sort-Object `
            @{ Expression = { $_.SourceRank }; Descending = $true }, `
            @{ Expression = { $_.LastWriteTicks }; Descending = $true }, `
            @{ Expression = { $_.SourcePath } } |
        Select-Object -First 1)
}

$cfg = Get-Content -Raw $ConfigPath | ConvertFrom-Json
$existingCommands = @($cfg.channels.telegram.customCommands)
$disabledCommands = Get-DisabledSlashCommands -Path $slashStatePath
$existingByCommand = @{}
foreach ($entry in $existingCommands) {
    if (-not $entry.command) {
        continue
    }
    $normalized = Normalize-CommandName -Name ([string]$entry.command)
    if (-not $normalized) {
        continue
    }
    if ($disabledCommands.Contains($normalized)) {
        continue
    }
    $existingByCommand[$normalized] = [pscustomobject]@{
        command     = $normalized
        description = Normalize-CommandDescription -Description ([string]$entry.description) -Command $normalized
    }
}

$candidateMap = @{}
$invalidEntries = New-Object System.Collections.ArrayList

$codexSkillsRoot = if ($userHome) { Join-Path $userHome '.codex\skills' } else { $null }
$codexSuperpowersRoot = if ($userHome) { Join-Path $userHome '.codex\superpowers\skills' } else { $null }
$pluginRoots = @(
    $(if ($userHome) { Join-Path $userHome '.codex\plugins\cache' }),
    $(if ($userHome) { Join-Path $userHome '.codex\.tmp\plugins' })
) | Where-Object { $_ -and (Test-Path $_) }
$claudeSkillsRoot = if ($userHome) { Join-Path $userHome '.claude\skills' } else { $null }
$claudeCommandsRoot = if ($userHome) { Join-Path $userHome '.claude\commands' } else { $null }
$runtimeSkillsRoot = Join-Path $paths.RuntimeRoot 'skills'
$workspaceSkillRoots = @($paths.WorkspaceRoots | ForEach-Object { Join-Path ([string]$_) 'skills' })

Get-SkillCandidatesFromRoots -Roots @($codexSkillsRoot) -SourceKind 'codex-skill' -SourceRank 700 -CandidateMap $candidateMap -InvalidEntries $invalidEntries
Get-SkillCandidatesFromRoots -Roots @($codexSuperpowersRoot) -SourceKind 'codex-superpower' -SourceRank 680 -CandidateMap $candidateMap -InvalidEntries $invalidEntries
Get-SkillCandidatesFromRoots -Roots @($runtimeSkillsRoot) -SourceKind 'runtime-skill' -SourceRank 660 -CandidateMap $candidateMap -InvalidEntries $invalidEntries
Get-SkillCandidatesFromRoots -Roots $workspaceSkillRoots -SourceKind 'openclaw-workspace' -SourceRank 650 -CandidateMap $candidateMap -InvalidEntries $invalidEntries
Get-SkillCandidatesFromRoots -Roots @($pluginRoots) -SourceKind 'plugin-skill' -SourceRank 640 -CandidateMap $candidateMap -InvalidEntries $invalidEntries
Get-SkillCandidatesFromRoots -Roots @($claudeSkillsRoot) -SourceKind 'claude-skill' -SourceRank 620 -CandidateMap $candidateMap -InvalidEntries $invalidEntries
Get-ClaudeCommandCandidates -CommandsRoot $claudeCommandsRoot -WrapperRoot $paths.GeneratedClaudeCommandsRoot -CandidateMap $candidateMap -InvalidEntries $invalidEntries
Get-SkillCandidatesFromRoots -Roots @($generatedCustomCommandsRoot) -SourceKind 'generated-custom-command' -SourceRank 800 -CandidateMap $candidateMap -InvalidEntries $invalidEntries

foreach ($workspaceSkillRoot in @($workspaceSkillRoots | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique)) {
    foreach ($skillFile in Get-ChildItem -LiteralPath $workspaceSkillRoot -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue) {
        $frontMatterStatus = Get-SkillFrontMatterStatus -Path $skillFile.FullName
        if (-not $frontMatterStatus.isValid) {
            continue
        }

        $frontMatter = Get-MarkdownFrontMatter -Path $skillFile.FullName
        $rawName = if ($frontMatter.ContainsKey('name') -and -not [string]::IsNullOrWhiteSpace($frontMatter['name'])) {
            [string]$frontMatter['name']
        } else {
            [string]$skillFile.Directory.Name
        }
        $command = Normalize-CommandName -Name $rawName
        if (-not $command) {
            continue
        }

        if (-not $candidateMap.ContainsKey($command)) {
            $description = if ($frontMatter.ContainsKey('description') -and -not [string]::IsNullOrWhiteSpace($frontMatter['description'])) {
                [string]$frontMatter['description']
            } else {
                Get-MarkdownFirstBodyLine -Path $skillFile.FullName
            }

            Add-CatalogCandidate -CandidateMap $candidateMap -Candidate (New-CatalogCandidate `
                -Command $command `
                -SourceDir $skillFile.Directory.FullName `
                -SourcePath $skillFile.FullName `
                -SourceKind 'openclaw-workspace' `
                -SourceRank 650 `
                -Description $description `
                -OriginPath $null `
                -LastWriteTicks $skillFile.LastWriteTimeUtc.Ticks)
        }
    }
}

$curatedCommandSet = Get-CuratedTelegramCommandSet `
    -TelegramConfig $cfg.channels.telegram `
    -PriorityPath $MenuPriorityPath `
    -GeneratedCustomCommandsRoot $generatedCustomCommandsRoot `
    -ExistingCommands $existingCommands `
    -DisabledCommands $disabledCommands

foreach ($candidateCommand in @($candidateMap.Keys)) {
    Add-NormalizedCommandToSet -Set $curatedCommandSet -CommandName ([string]$candidateCommand) -DisabledCommands $disabledCommands
}

$allCommands = @($curatedCommandSet | Sort-Object)

$customCommands = New-Object System.Collections.ArrayList
$manifestEntries = New-Object System.Collections.ArrayList
$missingSourceCommands = New-Object System.Collections.ArrayList

foreach ($command in $allCommands) {
    $chosenCandidate = if ($candidateMap.ContainsKey($command)) {
        Select-CanonicalCandidate -Candidates $candidateMap[$command]
    } else {
        $null
    }

    $description = if ($chosenCandidate -and -not [string]::IsNullOrWhiteSpace($chosenCandidate.Description)) {
        [string]$chosenCandidate.Description
    } elseif (
        $existingByCommand.ContainsKey($command) -and
        -not [string]::IsNullOrWhiteSpace($existingByCommand[$command].description)
    ) {
        [string]$existingByCommand[$command].description
    } else {
        $null
    }
    $description = Normalize-CommandDescription -Description $description -Command $command

    [void]$customCommands.Add([pscustomobject]@{
        command     = $command
        description = $description
    })

    if (-not $chosenCandidate) {
        [void]$missingSourceCommands.Add($command)
    }

    [void]$manifestEntries.Add([pscustomobject]@{
        command     = $command
        description = $description
        sourceKind  = if ($chosenCandidate) { $chosenCandidate.SourceKind } else { 'missing' }
        sourceDir   = if ($chosenCandidate) { $chosenCandidate.SourceDir } else { $null }
        sourcePath  = if ($chosenCandidate) { $chosenCandidate.SourcePath } else { $null }
        originPath  = if ($chosenCandidate) { $chosenCandidate.OriginPath } else { $null }
        sourceRank  = if ($chosenCandidate) { $chosenCandidate.SourceRank } else { 0 }
    })
}

$channels = Ensure-ObjectProperty -Target $cfg -Name 'channels'
$telegram = Ensure-ObjectProperty -Target $channels -Name 'telegram'
Set-NoteProperty -Target $telegram -Name 'customCommands' -Value @($customCommands | Sort-Object command)

$channelDefaults = Ensure-ObjectProperty -Target $channels -Name 'defaults'
$channelHeartbeat = Ensure-ObjectProperty -Target $channelDefaults -Name 'heartbeat'
Set-NoteProperty -Target $channelHeartbeat -Name 'showOk' -Value $false
Set-NoteProperty -Target $channelHeartbeat -Name 'showAlerts' -Value $true
Set-NoteProperty -Target $channelHeartbeat -Name 'useIndicator' -Value $true

$tools = Ensure-ObjectProperty -Target $cfg -Name 'tools'
$elevated = Ensure-ObjectProperty -Target $tools -Name 'elevated'
Set-NoteProperty -Target $elevated -Name 'enabled' -Value $true
$elevatedAllowFrom = Ensure-ObjectProperty -Target $elevated -Name 'allowFrom'
Set-NoteProperty -Target $elevatedAllowFrom -Name 'telegram' -Value @('*')

$exec = Ensure-ObjectProperty -Target $tools -Name 'exec'
Set-NoteProperty -Target $exec -Name 'ask' -Value 'off'

$message = Ensure-ObjectProperty -Target $tools -Name 'message'
Set-NoteProperty -Target $message -Name 'allowCrossContextSend' -Value $true
$crossContext = Ensure-ObjectProperty -Target $message -Name 'crossContext'
Set-NoteProperty -Target $crossContext -Name 'allowWithinProvider' -Value $true
Set-NoteProperty -Target $crossContext -Name 'allowAcrossProviders' -Value $true

$browser = Ensure-ObjectProperty -Target $cfg -Name 'browser'
Set-NoteProperty -Target $browser -Name 'enabled' -Value $true
Set-NoteProperty -Target $browser -Name 'evaluateEnabled' -Value $true
Set-NoteProperty -Target $browser -Name 'defaultProfile' -Value 'user'
$browserProfiles = Ensure-ObjectProperty -Target $browser -Name 'profiles'
$userBrowserProfile = Ensure-ObjectProperty -Target $browserProfiles -Name 'user'
Set-NoteProperty -Target $userBrowserProfile -Name 'driver' -Value 'existing-session'
Set-NoteProperty -Target $userBrowserProfile -Name 'attachOnly' -Value $true

$plugins = Ensure-ObjectProperty -Target $cfg -Name 'plugins'
$pluginEntries = Ensure-ObjectProperty -Target $plugins -Name 'entries'
$openaiPlugin = Ensure-ObjectProperty -Target $pluginEntries -Name 'openai'
Set-NoteProperty -Target $openaiPlugin -Name 'enabled' -Value $true
$browserPlugin = Ensure-ObjectProperty -Target $pluginEntries -Name 'browser'
Set-NoteProperty -Target $browserPlugin -Name 'enabled' -Value $true

$agents = Ensure-ObjectProperty -Target $cfg -Name 'agents'
$agentDefaults = Ensure-ObjectProperty -Target $agents -Name 'defaults'
Set-NoteProperty -Target $agentDefaults -Name 'elevatedDefault' -Value 'full'

foreach ($agent in @($agents.list)) {
    if (-not $agent.id) {
        continue
    }

    $agentTools = Ensure-ObjectProperty -Target $agent -Name 'tools'
    Set-NoteProperty -Target $agentTools -Name 'profile' -Value 'full'
    $agentElevated = Ensure-ObjectProperty -Target $agentTools -Name 'elevated'
    Set-NoteProperty -Target $agentElevated -Name 'enabled' -Value $true
    $agentAllowFrom = Ensure-ObjectProperty -Target $agentElevated -Name 'allowFrom'
    Set-NoteProperty -Target $agentAllowFrom -Name 'telegram' -Value @('*')

    $heartbeatConfig = [pscustomobject]@{
        every                      = '30s'
        target                     = 'last'
        directPolicy               = 'allow'
        accountId                  = $heartbeatAccountByAgent[[string]$agent.id]
        prompt                     = 'Read HEARTBEAT.md if it exists (workspace context). Follow it strictly. During active work, send concise user-visible progress at least every 30 seconds to the originating Telegram chat/thread when available; if no chat target exists, use the active session reply/commentary channel. When idle and no task/event is due, stay quiet.'
        includeSystemPromptSection = $false
        ackMaxChars                = 280
        timeoutSeconds             = 25
        isolatedSession            = $true
    }
    Set-NoteProperty -Target $agent -Name 'heartbeat' -Value $heartbeatConfig
}

$session = Ensure-ObjectProperty -Target $cfg -Name 'session'
Set-NoteProperty -Target $session -Name 'dmScope' -Value 'per-account-channel-peer'

$skills = Ensure-ObjectProperty -Target $cfg -Name 'skills'
$skillsLimits = Ensure-ObjectProperty -Target $skills -Name 'limits'
Set-NoteProperty -Target $skillsLimits -Name 'maxCandidatesPerRoot' -Value 1000
Set-NoteProperty -Target $skillsLimits -Name 'maxSkillsLoadedPerSource' -Value 1000

Save-OpenClawConfigFile -Config $cfg -LastWriter 'Sync-OpenClawCommandCatalog'
Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
    generatedAt = [DateTime]::UtcNow.ToString('o')
    entries     = @($manifestEntries | Sort-Object command)
}) -Path $paths.CommandCatalogPath -Kind 'command-catalog' -Source 'Sync-OpenClawCommandCatalog.ps1'
Ensure-RuntimeSkillCompatibilityWrappers -RuntimeSkillsRoot (Join-Path $paths.RuntimeRoot 'skills') -ManifestEntries $manifestEntries

if ((-not (Test-Path $MenuPriorityPath)) -and $telegram.PSObject.Properties.Name -contains 'menuPriorityCommands') {
    Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
        commands = @($telegram.menuPriorityCommands)
    }) -Path $MenuPriorityPath -Kind 'menu-priority' -Source 'Sync-OpenClawCommandCatalog.ps1'
}

if (Test-Path $workspaceSkillSyncScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $workspaceSkillSyncScript -ConfigPath $ConfigPath -Quiet | Out-Null
}

$newCommands = @($customCommands | ForEach-Object { [string]$_.command })
$previousCommands = @($existingByCommand.Keys)
$addedCommands = @(
    Compare-Object -ReferenceObject $previousCommands -DifferenceObject $newCommands |
        Where-Object { $_.SideIndicator -eq '=>' } |
        ForEach-Object { [string]$_.InputObject } |
        Sort-Object
)
$removedCommands = @(
    Compare-Object -ReferenceObject $previousCommands -DifferenceObject $newCommands |
        Where-Object { $_.SideIndicator -eq '<=' } |
        ForEach-Object { [string]$_.InputObject } |
        Sort-Object
)

if (-not $Quiet) {
    [pscustomobject]@{
        commandCount          = $newCommands.Count
        candidateCommandCount = $candidateMap.Keys.Count
        workspaceSkillRoots   = @($workspaceSkillRoots)
        workspaceSkillFiles   = @($workspaceSkillRoots | ForEach-Object { if ($_ -and (Test-Path -LiteralPath $_)) { @(Get-ChildItem -LiteralPath $_ -Recurse -File -Filter 'SKILL.md' -ErrorAction SilentlyContinue).Count } else { 0 } })
        addedCommands         = $addedCommands
        removedCommands       = $removedCommands
        missingSourceCommands = @($missingSourceCommands)
        invalidEntries        = @($invalidEntries)
        disabledCommands      = @($disabledCommands | Sort-Object)
        commandCatalogPath    = $paths.CommandCatalogPath
        generatedCustomCommandRoot = $generatedCustomCommandsRoot
        generatedWrapperRoot  = $paths.GeneratedClaudeCommandsRoot
    } | ConvertTo-Json -Depth 12
}
