param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'

. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
$setSlashScript = Join-Path $paths.RepoRoot 'scripts\telegram-global\Set-OpenClawSlashCommand.ps1'
$syncCatalogScript = Join-Path $paths.RepoRoot 'scripts\telegram-global\Sync-OpenClawCommandCatalog.ps1'
$snapCommandScript = Join-Path $paths.RepoRoot 'scripts\telegram-global\Invoke-OpenClawSnapCommand.ps1'
$commandCatalogPath = $paths.CommandCatalogPath

function ConvertTo-YamlSingleQuotedScalar {
    param(
        [AllowNull()][string]$Value
    )

    if ($null -eq $Value) {
        return "''"
    }

    return "'" + ([string]$Value).Replace("'", "''") + "'"
}

function Normalize-CommandName {
    param(
        [Parameter(Mandatory = $true)][string]$Name
    )

    $normalized = ([string]$Name).Trim().ToLowerInvariant()
    $normalized = $normalized -replace '^[/$]+', ''
    $normalized = $normalized -replace '\.md$', ''
    $normalized = $normalized -replace '[:/\\\s-]+', '_'
    $normalized = $normalized -replace '[^a-z0-9_]', ''
    $normalized = $normalized -replace '_+', '_'
    $normalized = $normalized.Trim('_')

    if ($normalized -notmatch '^[a-z0-9][a-z0-9_]*$') {
        throw "Invalid Telegram command name: $Name"
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

function Normalize-ExecCommand {
    param(
        [Parameter(Mandatory = $true)][string]$RawTarget
    )

    $value = ([string]$RawTarget).Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw 'Missing command to run.'
    }

    $preferWindowsPowerShell = $false
    if ($value -match '(?i)\s+in\s+powershell\s+v5\s*$') {
        $preferWindowsPowerShell = $true
        $value = ($value -replace '(?i)\s+in\s+powershell\s+v5\s*$', '').Trim()
    }

    $value = ($value -replace '(?i)\s+and\s+send\s+output\s+in\s+telegram\s+chat\s*$', '').Trim()
    $value = ($value -replace '(?i)\s+and\s+send\s+the\s+output\s+in\s+telegram\s+chat\s*$', '').Trim()
    $value = ($value -replace '(?i)\s+and\s+send\s+output\s+here\s*$', '').Trim()
    $value = ($value -replace '(?i)\s+and\s+send\s+the\s+output\s+here\s*$', '').Trim()
    $value = ($value -replace '(?i)\s+and\s+post\s+output\s+here\s*$', '').Trim()

    if ($value -match '^(["''])(?<inner>.+)\1$') {
        $value = ([string]$Matches['inner']).Trim()
    }

    if ($value -match '^(?i)powershell(?:\.exe)?\b') {
        if ($value -notmatch '(?i)\s-NoProfile(?:\s|$)') {
            $value = $value -replace '^(?i)(powershell(?:\.exe)?)(?=\s|$)', '$1 -NoProfile'
        }
        return $value
    }

    if ($value -match '^(?i)pwsh(?:\.exe)?\b') {
        return $value
    }

    if ($value -match '(?i)\.ps1(?:"|''|\s|$)') {
        $candidatePath = $value.Trim('"').Trim("'")
        if ((Test-Path $candidatePath) -and -not (Get-Item $candidatePath).PSIsContainer) {
            return ('powershell -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $candidatePath)
        }
        if ($preferWindowsPowerShell) {
            return ('powershell -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $candidatePath)
        }
    }

    if ($preferWindowsPowerShell) {
        $escaped = $value.Replace('"', '\"')
        return ('powershell -NoProfile -ExecutionPolicy Bypass -Command "{0}"' -f $escaped)
    }

    return $value
}

function Unquote-Value {
    param(
        [AllowNull()][string]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $trimmed = ([string]$Value).Trim()
    if ($trimmed -match '^(["''])(?<inner>.+)\1$') {
        return ([string]$Matches['inner']).Trim()
    }

    return $trimmed
}

function Get-TargetFromMutationText {
    param(
        [Parameter(Mandatory = $true)][string]$Text
    )

    $value = ([string]$Text).Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    foreach ($pattern in @(
        '(?is)\bfrom\s*:\s*(?<target>[a-z]:\\[^\r\n]+?\.ps1(?:["'']|\s|$))',
        '(?is)(?<target>[a-z]:\\[^\r\n]+?\.ps1)(?=$|["'']|\s)',
        '(?is)^(?:to\s+)?(?:always\s+)?(?:run|use|execute|launch)\s+(?<target>.+)$',
        '(?is)\b(?:run|use|execute|launch)\b\s+(?<target>(?:powershell|pwsh)(?:\.exe)?\b.+)$',
        '(?is)\b(?:point|set)\s+(?:it\s+)?(?:to|at)\s+(?<target>.+)$',
        '(?is)^(?<target>(?:powershell|pwsh)(?:\.exe)?\b.+)$'
    )) {
        if ($value -match $pattern) {
            $target = Unquote-Value -Value $Matches['target']
            if ($target) {
                return $target.Trim().TrimEnd('.', ',', ';')
            }
        }
    }

    return $null
}

function Resolve-BuiltinSlashIntent {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$Text
    )

    $normalizedCommand = Normalize-CommandName -Name $CommandName
    $value = ([string]$Text).Trim().ToLowerInvariant()
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    if ($normalizedCommand -eq 'snap') {
        $mentionsScreenshot = $value -match '(screen\s*shot|screenshot|snapshot|capture|take\s+screen|full\s*screen|fullscreen)'
        $mentionsDelivery = $value -match '(send|post|reply|return).*(chat|telegram|here)|in\s+the\s+chat'
        if ($mentionsScreenshot -or $mentionsDelivery) {
            if (-not (Test-Path $snapCommandScript)) {
                throw "Missing shared /snap command script: $snapCommandScript"
            }

            return [pscustomobject]@{
                FixedCommand = ('powershell -NoProfile -ExecutionPolicy Bypass -File "{0}"' -f $snapCommandScript)
                Description  = 'Take a live full-screen screenshot and send it in Telegram across all 4 OpenClaw bots.'
            }
        }
    }

    return $null
}

function Get-CommandCatalogEntryByCommand {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName
    )

    if (-not (Test-Path $commandCatalogPath)) {
        return $null
    }

    try {
        $catalog = Get-Content -Raw $commandCatalogPath | ConvertFrom-Json
    } catch {
        return $null
    }

    $normalized = Normalize-CommandName -Name $CommandName
    $matches = @($catalog.entries | Where-Object {
        ([string]$_.command).Trim().ToLowerInvariant() -eq $normalized
    } | Select-Object -First 1)
    if ($matches.Count -eq 0) {
        return $null
    }
    return $matches[0]
}

function Get-SkillBodyParts {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $raw = (Get-Content -Raw -LiteralPath $Path) -replace "^\uFEFF", ''
    if ($raw -match '^(?s)---\r?\n(?<front>.*?)\r?\n---(?:\r?\n|$)(?<body>.*)$') {
        return [pscustomobject]@{
            FrontMatter = [string]$Matches['front']
            Body        = ([string]$Matches['body']).Trim()
        }
    }

    return [pscustomobject]@{
        FrontMatter = ''
        Body        = $raw.Trim()
    }
}

function Resolve-CanonicalMirroredSourcePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $current = $Path
    for ($i = 0; $i -lt 8; $i++) {
        if (-not (Test-Path $current)) {
            break
        }

        $parts = Get-SkillBodyParts -Path $current
        $matches = [regex]::Matches($parts.Body, '(?im)^Authoritative source skill:\s*`(?<path>[^`]+)`\s*$')
        if ($matches.Count -eq 0) {
            break
        }

        $next = $null
        for ($j = $matches.Count - 1; $j -ge 0; $j--) {
            $candidate = ([string]$matches[$j].Groups['path'].Value).Trim()
            if ([string]::IsNullOrWhiteSpace($candidate)) {
                continue
            }
            if ($candidate -eq $current) {
                continue
            }
            if (-not (Test-Path $candidate)) {
                continue
            }
            $next = $candidate
            break
        }

        if ([string]::IsNullOrWhiteSpace($next)) {
            break
        }

        $current = $next
    }

    return $current
}

function Get-GoalDrivenBaselineContext {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $currentPath = $Path
    $currentParts = Get-SkillBodyParts -Path $currentPath
    $authoritativeSourcePath = $null
    $matches = [regex]::Matches($currentParts.Body, '(?im)^Authoritative source skill:\s*`(?<path>[^`]+)`\s*$')
    for ($i = $matches.Count - 1; $i -ge 0; $i--) {
        $candidate = ([string]$matches[$i].Groups['path'].Value).Trim()
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            continue
        }
        if ($candidate -eq $currentPath) {
            continue
        }
        if (-not (Test-Path $candidate)) {
            continue
        }
        $authoritativeSourcePath = $candidate
        break
    }

    if (-not [string]::IsNullOrWhiteSpace($authoritativeSourcePath)) {
        $sourceParts = Get-SkillBodyParts -Path $authoritativeSourcePath
        return [pscustomobject]@{
            SourceSkillPath           = $authoritativeSourcePath
            PreservedFrontMatterLines = @(Get-PreservedFrontMatterLines -FrontMatter $sourceParts.FrontMatter)
            BaselineBody              = $sourceParts.Body
        }
    }

    $baselineBody = $currentParts.Body
    $baselineMatch = [regex]::Match($currentParts.Body, '(?is)\r?\n##\s+Baseline Workflow\s*\r?\n(?<baseline>.+)$')
    if ($baselineMatch.Success) {
        $baselineBody = ([string]$baselineMatch.Groups['baseline'].Value).Trim()
    }

    return [pscustomobject]@{
        SourceSkillPath           = $null
        PreservedFrontMatterLines = @(Get-PreservedFrontMatterLines -FrontMatter $currentParts.FrontMatter)
        BaselineBody              = $baselineBody
    }
}

function Normalize-GoalText {
    param(
        [AllowNull()][string]$Text
    )

    $value = ([string]$Text).Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    $value = ($value -replace '^(?i)to\s+', '').Trim()
    $value = ($value -replace '\s+', ' ').Trim()
    $value = $value.TrimEnd('.', ';')
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    return $value
}

function Convert-GoalTextToDescription {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [AllowNull()][string]$GoalText
    )

    $goal = Normalize-GoalText -Text $GoalText
    if ([string]::IsNullOrWhiteSpace($goal)) {
        return "Operator-defined workflow for /$CommandName across all 4 OpenClaw Telegram bots."
    }

    $goal = $goal.Trim()
    if ($goal.Length -gt 140) {
        $goal = $goal.Substring(0, 140).TrimEnd()
    }

    $goal = [char]::ToUpperInvariant($goal[0]) + $goal.Substring(1)
    return $goal
}

function Get-PreservedFrontMatterLines {
    param(
        [Parameter(Mandatory = $true)][string]$FrontMatter
    )

    $allowedKeys = @(
        'disable-model-invocation',
        'command-dispatch',
        'command-tool',
        'command-fixed-args',
        'command-yield-ms',
        'command-timeout-sec',
        'command-background'
    )

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in @($FrontMatter -split '\r?\n')) {
        if ($line -match '^\s*(?<key>[A-Za-z0-9_-]+)\s*:') {
            $key = ([string]$Matches['key']).Trim().ToLowerInvariant()
            if ($allowedKeys -contains $key) {
                [void]$lines.Add($line.TrimEnd())
            }
        }
    }

    return @($lines)
}

function New-MirroredWorkflowBody {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$SourceCommand,
        [Parameter(Mandatory = $true)][string]$SourcePath
    )

    $parts = Get-SkillBodyParts -Path $SourcePath
    $preservedFrontMatterLines = @(Get-PreservedFrontMatterLines -FrontMatter $parts.FrontMatter)
    $frontMatterLines = New-Object System.Collections.Generic.List[string]
    [void]$frontMatterLines.Add('---')
    [void]$frontMatterLines.Add(("name: {0}" -f $CommandName))
    [void]$frontMatterLines.Add(("description: Mirror /{0} workflow across all 4 OpenClaw Telegram bots." -f $SourceCommand))
    [void]$frontMatterLines.Add('userInvocable: true')
    foreach ($line in $preservedFrontMatterLines) {
        [void]$frontMatterLines.Add($line)
    }
    [void]$frontMatterLines.Add('---')

    $bodyLines = New-Object System.Collections.Generic.List[string]
    foreach ($line in $frontMatterLines) {
        [void]$bodyLines.Add($line)
    }
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add(("# /{0}" -f $CommandName))
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add(('Use the same workflow as /{0}.' -f $SourceCommand))
    [void]$bodyLines.Add(('Authoritative source skill: `{0}`' -f $SourcePath))
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add('Rules:')
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add(('- Follow the mirrored workflow exactly as if the user invoked /{0} in Codex/OpenClaw.' -f $SourceCommand))
    [void]$bodyLines.Add('- Do not claim success unless the mirrored workflow actually completed.')
    [void]$bodyLines.Add('- If the mirrored workflow produces direct command output, return that output directly.')
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add('## Mirrored workflow')
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add($parts.Body)

    return ($bodyLines -join [Environment]::NewLine)
}

function New-GoalDrivenWorkflowBody {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$GoalText,
        [AllowNull()][string]$SourceCommand,
        [AllowNull()][string]$SourcePath
    )

    $goal = Normalize-GoalText -Text $GoalText
    if ([string]::IsNullOrWhiteSpace($goal)) {
        throw "Missing goal text for /$CommandName."
    }

    $preservedFrontMatterLines = @()
    $baselineBody = $null
    $sourceSkillLine = $null

    if (-not [string]::IsNullOrWhiteSpace($SourcePath) -and (Test-Path $SourcePath)) {
        $baselineContext = Get-GoalDrivenBaselineContext -Path $SourcePath
        $preservedFrontMatterLines = @($baselineContext.PreservedFrontMatterLines)
        $baselineBody = [string]$baselineContext.BaselineBody
        if (-not [string]::IsNullOrWhiteSpace([string]$baselineContext.SourceSkillPath)) {
            $sourceSkillLine = ('Authoritative source skill: `{0}`' -f ([string]$baselineContext.SourceSkillPath))
        }
    }

    $frontMatterLines = New-Object System.Collections.Generic.List[string]
    [void]$frontMatterLines.Add('---')
    [void]$frontMatterLines.Add(("name: {0}" -f $CommandName))
    [void]$frontMatterLines.Add(("description: {0}" -f (Convert-GoalTextToDescription -CommandName $CommandName -GoalText $goal)))
    [void]$frontMatterLines.Add('userInvocable: true')
    foreach ($line in $preservedFrontMatterLines) {
        [void]$frontMatterLines.Add($line)
    }
    [void]$frontMatterLines.Add('---')

    $bodyLines = New-Object System.Collections.Generic.List[string]
    foreach ($line in $frontMatterLines) {
        [void]$bodyLines.Add($line)
    }
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add(("# /{0}" -f $CommandName))
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add('This command was defined or updated through `/slash` using a plain-language behavior request.')
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add('## Operator Goal')
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add($goal)
    [void]$bodyLines.Add('')

    if ($sourceSkillLine) {
        [void]$bodyLines.Add('## Baseline Source')
        [void]$bodyLines.Add('')
        [void]$bodyLines.Add($sourceSkillLine)
        if ($SourceCommand) {
            [void]$bodyLines.Add(('Baseline command: /{0}' -f $SourceCommand))
        }
        [void]$bodyLines.Add('')
    }

    [void]$bodyLines.Add('## Rules')
    [void]$bodyLines.Add('')
    [void]$bodyLines.Add('- Treat the operator goal above as authoritative.')
    [void]$bodyLines.Add('- When the user invokes this slash command, make the real behavior satisfy that goal.')
    [void]$bodyLines.Add('- Do not argue that the mutation format is unsupported.')
    [void]$bodyLines.Add('- Do not claim success unless the requested action actually happened.')
    [void]$bodyLines.Add('- If a baseline source is included, use it as the starting workflow and adapt it only as needed to satisfy the operator goal.')
    [void]$bodyLines.Add('- Keep replies concise and user-facing; do not dump internal parser or tool details.')

    if ($baselineBody) {
        [void]$bodyLines.Add('')
        [void]$bodyLines.Add('## Baseline Workflow')
        [void]$bodyLines.Add('')
        [void]$bodyLines.Add($baselineBody)
    }

    return ($bodyLines -join [Environment]::NewLine)
}

function Resolve-MirroredSlashIntent {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$Text
    )

    $value = ([string]$Text).Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        return $null
    }

    $targetName = $null
    foreach ($pattern in @(
        "(?is)\b(?:do\s+same\s+as|same\s+as|same\s+workflow\s+as|same\s+thing\s+as|behave\s+like|work\s+like|act\s+like|mirror)\s+['`"](?<target>[^'`"]+)['`"]",
        '(?is)\b(?:do\s+same\s+as|same\s+as|same\s+workflow\s+as|same\s+thing\s+as|behave\s+like|work\s+like|act\s+like|mirror)\s+(?<target>/?[a-z0-9_/-]+)'
    )) {
        if ($value -match $pattern) {
            $targetName = [string]$Matches['target']
            break
        }
    }

    if ([string]::IsNullOrWhiteSpace($targetName)) {
        return $null
    }

    $normalizedTarget = Normalize-CommandName -Name $targetName
    $entry = Get-CommandCatalogEntryByCommand -CommandName $normalizedTarget
    if (-not $entry -or [string]::IsNullOrWhiteSpace([string]$entry.sourcePath) -or -not (Test-Path ([string]$entry.sourcePath))) {
        throw "Unable to mirror /$normalizedTarget because its source skill could not be resolved from the command catalog."
    }

    $resolvedSourcePath = Resolve-CanonicalMirroredSourcePath -Path ([string]$entry.sourcePath)

    return [pscustomobject]@{
        SkillBody      = (New-MirroredWorkflowBody -CommandName $CommandName -SourceCommand $normalizedTarget -SourcePath $resolvedSourcePath)
        Description    = ("Mirror /{0} workflow across all 4 OpenClaw Telegram bots." -f $normalizedTarget)
        SuccessSummary = ("Mirrored workflow: /{0} from {1}" -f $normalizedTarget, $resolvedSourcePath)
    }
}

function Resolve-GoalDrivenSlashIntent {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$Text
    )

    $goal = Normalize-GoalText -Text $Text
    if ([string]::IsNullOrWhiteSpace($goal)) {
        return $null
    }

    $existingEntry = Get-CommandCatalogEntryByCommand -CommandName $CommandName
    $sourceCommand = $null
    $sourcePath = $null
    if ($existingEntry -and -not [string]::IsNullOrWhiteSpace([string]$existingEntry.sourcePath) -and (Test-Path ([string]$existingEntry.sourcePath))) {
        $sourceCommand = $CommandName
        $sourcePath = Resolve-CanonicalMirroredSourcePath -Path ([string]$existingEntry.sourcePath)
    }

    return [pscustomobject]@{
        SkillBody      = (New-GoalDrivenWorkflowBody -CommandName $CommandName -GoalText $goal -SourceCommand $sourceCommand -SourcePath $sourcePath)
        Description    = (Convert-GoalTextToDescription -CommandName $CommandName -GoalText $goal)
        SuccessSummary = ("Goal-driven workflow set: {0}" -f $goal)
    }
}

function New-ExecWrapperBody {
    param(
        [Parameter(Mandatory = $true)][string]$CommandName,
        [Parameter(Mandatory = $true)][string]$FixedCommand
    )

    $fixedLiteral = ConvertTo-YamlSingleQuotedScalar -Value $FixedCommand
    return @"
---
name: $CommandName
description: Direct exec wrapper for /$CommandName across all 4 OpenClaw Telegram bots.
userInvocable: true
disable-model-invocation: true
command-dispatch: tool
command-tool: exec
command-fixed-args: $fixedLiteral
command-yield-ms: 180000
command-timeout-sec: 300
command-background: false
---

# /$CommandName

Execute this exact fixed command directly and return the raw output in Telegram:

Fixed command: $FixedCommand

Rules:

- Do not paraphrase the output.
- Do not add generic acknowledgements, idle text, or heartbeat text.
- Return the command output directly.
"@
}

function Invoke-SetSlashCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [string]$CommandName,
        [string]$Description,
        [string]$SkillBody
    )

    $params = @{
        Action = $Action
    }
    if ($CommandName) {
        $params.CommandName = $CommandName
    }
    if ($Description) {
        $params.Description = $Description
    }
    if ($SkillBody) {
        $params.SkillBodyBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($SkillBody))
    }

    $raw = & powershell -NoProfile -ExecutionPolicy Bypass -File $setSlashScript @params 2>&1
    $exitCode = $LASTEXITCODE
    $lines = @($raw | ForEach-Object {
        if ($_ -is [System.Management.Automation.ErrorRecord]) {
            $_.ToString()
        } else {
            [string]$_
        }
    } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
    $text = ($lines -join [Environment]::NewLine).Trim()
    if ($exitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($text)) {
            throw "Shared /slash mutation failed for /$CommandName."
        }
        throw $text
    }

    try {
        return ($text | ConvertFrom-Json)
    } catch {
        $jsonMatch = [regex]::Match($text, '(?s)(\{\s*"action"\s*:.*\})\s*$')
        if ($jsonMatch.Success) {
            $jsonText = ([string]$jsonMatch.Groups[1].Value).Trim()
            try {
                return ($jsonText | ConvertFrom-Json)
            } catch {
            }
        }

        throw
    }
}

function Get-BatchedSlashMutations {
    param(
        [Parameter(Mandatory = $true)][string]$RawInput
    )

    $inputText = ([string]$RawInput).Trim()
    $actionMatch = [regex]::Match($inputText, '^(?i)(?<action>add|create|update|change)\b')
    if (-not $actionMatch.Success) {
        return @()
    }

    $actionRaw = ([string]$actionMatch.Groups['action'].Value).ToLowerInvariant()
    $action = if ($actionRaw -in @('add', 'create')) { 'add' } else { 'update' }
    $remainder = $inputText.Substring($actionMatch.Length).Trim()
    if ([string]::IsNullOrWhiteSpace($remainder)) {
        return @()
    }

    $commandMatches = [regex]::Matches($remainder, '(?ix)
        (?:
            ^\s*
          |
            [\s,;]+(?:and|then|also)\s+
        )
        (?:
            "(?<qdouble>/?[a-z0-9_/-]+)"
          |
            ''(?<qsingle>/?[a-z0-9_/-]+)''
          |
            (?<bare>/[a-z0-9_/-]+)
        )
        (?=\s|$)')

    if ($commandMatches.Count -lt 2) {
        return @()
    }

    $mutations = New-Object System.Collections.Generic.List[object]
    for ($index = 0; $index -lt $commandMatches.Count; $index++) {
        $match = $commandMatches[$index]
        $commandGroup = $null
        foreach ($groupName in @('qdouble', 'qsingle', 'bare')) {
            $candidateGroup = $match.Groups[$groupName]
            if ($candidateGroup.Success -and -not [string]::IsNullOrWhiteSpace([string]$candidateGroup.Value)) {
                $commandGroup = $candidateGroup
                break
            }
        }

        $commandRaw = if ($commandGroup) { ([string]$commandGroup.Value).Trim() } else { $null }
        if ([string]::IsNullOrWhiteSpace($commandRaw)) {
            continue
        }

        $segmentStart = $commandGroup.Index + $commandGroup.Length
        $segmentEnd = if ($index + 1 -lt $commandMatches.Count) { $commandMatches[$index + 1].Index } else { $remainder.Length }
        if ($segmentEnd -lt $segmentStart) {
            continue
        }

        $rest = $remainder.Substring($segmentStart, $segmentEnd - $segmentStart).Trim()
        $rest = ($rest -replace '^(?i)(?:and|then|also)\b', '').Trim()
        $rest = ($rest -replace '^[,;:\-]+', '').Trim()
        if ([string]::IsNullOrWhiteSpace($rest)) {
            continue
        }

        $mutations.Add([pscustomobject]@{
            Action = $action
            CommandRaw = $commandRaw
            Rest = $rest
        })
    }

    return $mutations.ToArray()
}

function Invoke-SlashMutationRequest {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$CommandRaw,
        [Parameter(Mandatory = $true)][string]$Rest
    )

    $commandName = Normalize-CommandName -Name $CommandRaw
    $target = Get-TargetFromMutationText -Text $Rest
    $intent = $null
    if (-not $target) {
        $intent = Resolve-BuiltinSlashIntent -CommandName $commandName -Text $Rest
        if (-not $intent) {
            $intent = Resolve-MirroredSlashIntent -CommandName $commandName -Text $Rest
        }
        if (-not $intent) {
            $intent = Resolve-GoalDrivenSlashIntent -CommandName $commandName -Text $Rest
        }
        if (-not $intent) {
            throw 'Unsupported /slash mutation. Use: /slash create <command> <goal-or-command>, /slash update <command> <goal-or-command>, or /slash delete <command>. Natural-language create/update requests are allowed if they include the real command or .ps1 path, match a built-in intent such as /snap screenshot delivery, mirror an existing command/skill such as "same as ''done'' skill", or define a plain-language goal for the command.'
        }
    }

    $fixedCommand = if ($intent -and $intent.PSObject.Properties.Name -contains 'FixedCommand') {
        [string]$intent.FixedCommand
    } elseif ($intent) {
        $null
    } else {
        Normalize-ExecCommand -RawTarget $target
    }

    $skillBody = if ($intent -and $intent.PSObject.Properties.Name -contains 'SkillBody') {
        [string]$intent.SkillBody
    } else {
        New-ExecWrapperBody -CommandName $commandName -FixedCommand $fixedCommand
    }

    $description = if ($intent -and $intent.PSObject.Properties.Name -contains 'Description' -and $intent.Description) {
        [string]$intent.Description
    } else {
        "Direct exec wrapper for /$commandName across all 4 OpenClaw Telegram bots."
    }

    $result = Invoke-SetSlashCommand -Action $Action -CommandName $commandName -Description $description -SkillBody $skillBody
    $scopeCount = if ($result.verification -and $result.verification.menu) { [int]$result.verification.menu.checkedScopes } else { 0 }
    $successSummary = if ($intent -and $intent.PSObject.Properties.Name -contains 'SuccessSummary' -and $intent.SuccessSummary) {
        [string]$intent.SuccessSummary
    } elseif ($fixedCommand) {
        ("Fixed command: {0}" -f $fixedCommand)
    } else {
        "Workflow updated."
    }

    return [pscustomobject]@{
        Action = $Action
        Result = $result
        ScopeCount = $scopeCount
        SuccessSummary = $successSummary
    }
}

function Get-MatchedGroupValue {
    param(
        [Parameter(Mandatory = $true)][System.Text.RegularExpressions.Match]$Match,
        [Parameter(Mandatory = $true)][string[]]$Names
    )

    foreach ($name in $Names) {
        $value = ([string]$Match.Groups[$name].Value).Trim()
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value
        }
    }

    return $null
}

function Format-ListResult {
    param(
        [Parameter(Mandatory = $true)]$Entries
    )

    $commands = @($Entries)
    $top = @($commands | Select-Object -First 40)
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add(("Shared slash commands: {0}" -f $commands.Count))
    [void]$lines.Add('')
    foreach ($entry in $top) {
        [void]$lines.Add(('/{0} - {1}' -f $entry.command, $entry.description))
    }
    if ($commands.Count -gt $top.Count) {
        [void]$lines.Add('')
        [void]$lines.Add(("Showing first {0} of {1} commands." -f $top.Count, $commands.Count))
    }
    return ($lines -join [Environment]::NewLine)
}

try {
    $rawInput = (($Args | Where-Object { $_ -ne $null }) -join ' ').Trim()
    $rawInput = ($rawInput -replace '^(?i)/?slash\b', '').Trim()

    if ([string]::IsNullOrWhiteSpace($rawInput) -or $rawInput -match '^(?i)(list|ls|show)$') {
        $cfg = Get-Content -Raw $paths.ConfigPath | ConvertFrom-Json
        $entries = @($cfg.channels.telegram.customCommands) | Sort-Object command
        Write-Output (Format-ListResult -Entries $entries)
        exit 0
    }

    $deleteMatch = [regex]::Match($rawInput, '^(?i)(delete|remove)\s+(?:"(?<qcommand>[^"]+)"|''(?<scommand>[^'']+)''|(?<command>/?[a-z0-9_/-]+))\s*$')
    if ($deleteMatch.Success) {
        $commandRaw = Get-MatchedGroupValue -Match $deleteMatch -Names @('qcommand', 'scommand', 'command')
        $commandName = Normalize-CommandName -Name $commandRaw
        $result = Invoke-SetSlashCommand -Action 'delete' -CommandName $commandName
        $scopeCount = if ($result.verification -and $result.verification.menu) { [int]$result.verification.menu.checkedScopes } else { 0 }
        Write-Output ("Deleted /{0}. Verified removed from config, command catalog, all 4 workspace mirrors, and {1} Telegram menu scopes." -f $result.command, $scopeCount)
        exit 0
    }

    $batchedMutations = @(Get-BatchedSlashMutations -RawInput $rawInput)
    if ($batchedMutations.Count -gt 1) {
        $messages = New-Object System.Collections.Generic.List[string]
        foreach ($mutation in $batchedMutations) {
            $mutationResult = Invoke-SlashMutationRequest -Action ([string]$mutation.Action) -CommandRaw ([string]$mutation.CommandRaw) -Rest ([string]$mutation.Rest)
            $verb = ([string]$mutationResult.Action)
            $verb = $verb.Substring(0,1).ToUpperInvariant() + $verb.Substring(1)
            [void]$messages.Add(("{0} /{1}. {2}`nVerified in config, command catalog, all 4 workspace mirrors, and {3} Telegram menu scopes." -f $verb, $mutationResult.Result.command, $mutationResult.SuccessSummary, $mutationResult.ScopeCount))
        }
        Write-Output ($messages -join "`n`n")
        exit 0
    }

    $mutationMatch = [regex]::Match($rawInput, '^(?i)(?<action>add|create|update|change)\s+(?:"(?<qcommand>[^"]+)"|''(?<scommand>[^'']+)''|(?<command>/?[a-z0-9_/-]+))\s+(?<rest>.+)$')
    if ($mutationMatch.Success) {
        $actionRaw = $mutationMatch.Groups['action'].Value.ToLowerInvariant()
        $action = if ($actionRaw -eq 'add' -or $actionRaw -eq 'create') { 'add' } else { 'update' }
        $commandRaw = Get-MatchedGroupValue -Match $mutationMatch -Names @('qcommand', 'scommand', 'command')
        $rest = $mutationMatch.Groups['rest'].Value.Trim()
        $mutationResult = Invoke-SlashMutationRequest -Action $action -CommandRaw $commandRaw -Rest $rest
        Write-Output ("{0} /{1}. {2}`nVerified in config, command catalog, all 4 workspace mirrors, and {3} Telegram menu scopes." -f ($action.Substring(0,1).ToUpperInvariant() + $action.Substring(1)), $mutationResult.Result.command, $mutationResult.SuccessSummary, $mutationResult.ScopeCount)
        exit 0
    }

    throw "Unsupported /slash syntax. Use: /slash list, /slash delete <command>, /slash create <command> <goal-or-command>, or /slash update <command> <goal-or-command>."
} catch {
    $message = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$_
    }
    $stack = [string]$_.ScriptStackTrace
    if (-not [string]::IsNullOrWhiteSpace($stack)) {
        Write-Output (($message.Trim()) + "`n" + $stack.Trim())
    } else {
        Write-Output $message.Trim()
    }
    exit 1
}
