param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("add", "update", "delete", "list")]
    [string]$Action,

    [string]$CommandName,
    [string]$Description,
    [string]$SkillBodyBase64,
    [string]$ConfigPath,
    [string]$MenuPriorityPath,
    [switch]$SkipMenuSync
)

$ErrorActionPreference = "Stop"
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
if (-not $ConfigPath) { $ConfigPath = $paths.ConfigPath }
if (-not $MenuPriorityPath) { $MenuPriorityPath = $paths.MenuPriorityPath }
$workspaceRoots = $paths.WorkspaceRoots
$generatedCustomCommandsRoot = $paths.GeneratedCustomCommandsRoot
$slashStatePath = $paths.SlashStatePath

$commandCatalogSyncScript = "F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\telegram-global\Sync-OpenClawCommandCatalog.ps1"
$menuSyncScript = "F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\telegram-global\Sync-TelegramMenu.ps1"
$workspaceSkillSyncScript = "F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\telegram-global\Sync-OpenClawWorkspaceSkills.ps1"
$commandDescriptionMaxChars = 180
$nativeReservedCommands = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(
    'new'
) | ForEach-Object { [void]$nativeReservedCommands.Add($_) }

$updateOnlyInfrastructureCommands = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
@(
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
) | ForEach-Object { [void]$updateOnlyInfrastructureCommands.Add($_) }

$authorityCheck = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
if (-not $authorityCheck.passed) {
    $failed = @($authorityCheck.checks | Where-Object { -not $_.passed } | ForEach-Object { $_.name })
    throw "OpenClaw authority drift blocks /slash mutation: $($failed -join ', ')"
}
$script:mutationSnapshot = $null

function Normalize-CommandName {
    param([string]$Name)
    $normalized = ([string]$Name).Trim().ToLowerInvariant()
    if ($normalized.StartsWith("/")) {
        $normalized = $normalized.Substring(1)
    }
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

function Save-Json {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $json = $Object | ConvertTo-Json -Depth 100
    for ($attempt = 1; $attempt -le 12; $attempt++) {
        $tempPath = Join-Path $parent ("{0}.{1}.tmp" -f ([System.IO.Path]::GetFileName($Path)), ([guid]::NewGuid().ToString('N')))
        $backupPath = Join-Path $parent ("{0}.{1}.bak" -f ([System.IO.Path]::GetFileName($Path)), ([guid]::NewGuid().ToString('N')))
        try {
            [System.IO.File]::WriteAllText($tempPath, $json, [System.Text.Encoding]::UTF8)
            if (Test-Path $Path) {
                [System.IO.File]::Replace($tempPath, $Path, $backupPath, $false)
                Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
            } else {
                [System.IO.File]::Move($tempPath, $Path)
            }
            return
        } catch [System.IO.IOException] {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
            if ($attempt -ge 12) {
                throw
            }
            Start-Sleep -Milliseconds (150 * $attempt)
        } catch {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
            throw
        }
    }
}

function ConvertFrom-JsonSafe {
    param(
        [AllowNull()]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -isnot [string] -and $Value -isnot [System.Array]) {
        return $Value
    }

    $text = if ($Value -is [System.Array]) {
        ($Value -join [Environment]::NewLine)
    } else {
        [string]$Value
    }
    $text = $text.Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    try {
        return ($text | ConvertFrom-Json)
    } catch {
        return $text
    }
}

function Get-SlashState {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $raw = $null
    if (Test-Path $Path) {
        try {
            $raw = Get-Content -Raw $Path | ConvertFrom-Json
        } catch {
            $raw = $null
        }
    }

    $disabled = @()
    if ($raw -and $raw.PSObject.Properties.Name -contains 'disabledCommands') {
        foreach ($entry in @($raw.disabledCommands)) {
            try {
                $normalized = Normalize-CommandName -Name ([string]$entry)
                if ($normalized) {
                    $disabled += $normalized
                }
            } catch {
            }
        }
    }

    return [pscustomobject]@{
        disabledCommands = @($disabled | Select-Object -Unique | Sort-Object)
    }
}

function Save-SlashState {
    param(
        [Parameter(Mandatory = $true)]$State,
        [Parameter(Mandatory = $true)][string]$Path
    )

    Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
        disabledCommands = @($State.disabledCommands | Select-Object -Unique | Sort-Object)
    }) -Path $Path -Kind 'slash-state' -Source 'Set-OpenClawSlashCommand.ps1'
}

function Get-MenuPriorityCommands {
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

    if ($TelegramConfig.PSObject.Properties.Name -contains "menuPriorityCommands") {
        return @($TelegramConfig.menuPriorityCommands)
    }

    return @()
}

function Get-GeneratedSkillPath {
    param(
        [Parameter(Mandatory = $true)][string]$NormalizedCommand
    )

    return Join-Path (Join-Path $generatedCustomCommandsRoot $NormalizedCommand) "SKILL.md"
}

function Test-CommandExistsInConfig {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)][string]$NormalizedCommand
    )

    return (@($Config.channels.telegram.customCommands | Where-Object {
        ([string]$_.command).Trim().ToLowerInvariant() -eq $NormalizedCommand
    }).Count -gt 0)
}

function Copy-DirectoryContents {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    foreach ($child in @(Get-ChildItem -LiteralPath $Source -Force)) {
        Copy-Item -LiteralPath $child.FullName -Destination $Destination -Recurse -Force
    }
}

function Get-WorkspaceSkillPath {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$NormalizedCommand
    )

    return Join-Path (Join-Path $WorkspaceRoot "skills") (Join-Path $NormalizedCommand "SKILL.md")
}

function Get-WorkspaceSkillDir {
    param(
        [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
        [Parameter(Mandatory = $true)][string]$NormalizedCommand
    )

    return Split-Path -Parent (Get-WorkspaceSkillPath -WorkspaceRoot $WorkspaceRoot -NormalizedCommand $NormalizedCommand)
}

function Get-UpdatedMenuPriority {
    param(
        [AllowEmptyCollection()][array]$ExistingPriority,
        [Parameter(Mandatory = $true)][string]$NormalizedCommand,
        [Parameter(Mandatory = $true)][string]$Action
    )

    $clean = @(
        $ExistingPriority |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { ([string]$_).Trim().ToLowerInvariant() } |
            Where-Object { $_ -match '^[a-z0-9_]{1,32}$' }
    )

    if ($Action -eq "delete") {
        return @($clean | Where-Object { $_ -ne $NormalizedCommand } | Select-Object -Unique)
    }

    return @(
        @($NormalizedCommand) +
        @($clean | Where-Object { $_ -ne $NormalizedCommand }) |
            Select-Object -First 25
    )
}

function Normalize-CommandDescription {
    param(
        [AllowNull()][string]$Description,
        [Parameter(Mandatory = $true)][string]$NormalizedCommand
    )

    $fallback = "OpenClaw command: $($NormalizedCommand -replace '_', ' ')"
    if ([string]::IsNullOrWhiteSpace($Description)) {
        return $fallback
    }

    $normalized = ([string]$Description) -replace '\s+', ' '
    $normalized = $normalized.Trim()
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return $fallback
    }

    if ($normalized.Length -gt $script:commandDescriptionMaxChars) {
        $normalized = $normalized.Substring(0, $script:commandDescriptionMaxChars).TrimEnd()
    }

    return $normalized
}

function Get-MenuVerification {
    param(
        [AllowNull()]$SyncResult,
        [Parameter(Mandatory = $true)][string]$NormalizedCommand,
        [Parameter(Mandatory = $true)][bool]$ExpectPresent,
        [Parameter(Mandatory = $true)][bool]$SyncWasRequested
    )

    if (-not $SyncWasRequested) {
        return [pscustomobject]@{
            checkedScopes   = 0
            allOk           = $true
            commandMatches  = $true
            commandVisible  = $null
            failedScopes    = @()
        }
    }

    $rows = @()
    if ($SyncResult -is [string]) {
        $parsed = ConvertFrom-JsonSafe -Value $SyncResult
        if ($parsed) {
            $rows = @($parsed)
        }
    } elseif ($null -ne $SyncResult) {
        $rows = @($SyncResult)
    }

    if ($rows.Count -eq 0) {
        return [pscustomobject]@{
            checkedScopes   = 0
            allOk           = $false
            commandMatches  = $false
            commandVisible  = $null
            failedScopes    = @('no-telegram-sync-result')
        }
    }

    $failedScopes = New-Object System.Collections.Generic.List[string]
    $commandVisible = $false
    foreach ($row in $rows) {
        $published = @($row.publishedCommands | ForEach-Object { ([string]$_).Trim().ToLowerInvariant() })
        $hasCommand = $published -contains $NormalizedCommand
        if ($hasCommand) {
            $commandVisible = $true
        }
        if (-not [bool]$row.ok) {
            [void]$failedScopes.Add(("{0}:{1}:telegram-error" -f $row.accountId, $row.scope))
            continue
        }
        if ($ExpectPresent -and -not $hasCommand) {
            [void]$failedScopes.Add(("{0}:{1}:missing-command" -f $row.accountId, $row.scope))
            continue
        }
        if ((-not $ExpectPresent) -and $hasCommand) {
            [void]$failedScopes.Add(("{0}:{1}:command-still-published" -f $row.accountId, $row.scope))
            continue
        }
    }

    return [pscustomobject]@{
        checkedScopes   = $rows.Count
        allOk           = ($failedScopes.Count -eq 0)
        commandMatches  = ($failedScopes.Count -eq 0)
        commandVisible  = $commandVisible
        failedScopes    = @($failedScopes)
    }
}

function Get-MutationVerification {
    param(
        [Parameter(Mandatory = $true)][string]$NormalizedCommand,
        [Parameter(Mandatory = $true)][string]$Action,
        [AllowNull()]$SyncResult,
        [Parameter(Mandatory = $true)][bool]$SyncWasRequested
    )

    $cfgVerify = Get-Content -Raw $ConfigPath | ConvertFrom-Json
    $catalogEntries = @()
    if (Test-Path $paths.CommandCatalogPath) {
        try {
            $catalog = Get-Content -Raw $paths.CommandCatalogPath | ConvertFrom-Json
            $catalogEntries = @($catalog.entries | Where-Object { ([string]$_.command).Trim().ToLowerInvariant() -eq $NormalizedCommand })
        } catch {
            $catalogEntries = @()
        }
    }

    $slashState = Get-SlashState -Path $slashStatePath
    $workspaceStates = @(
        foreach ($workspaceRoot in $workspaceRoots) {
            $workspaceDir = Get-WorkspaceSkillDir -WorkspaceRoot $workspaceRoot -NormalizedCommand $NormalizedCommand
            [pscustomobject]@{
                workspaceRoot = $workspaceRoot
                exists        = (Test-Path $workspaceDir)
            }
        }
    )

    return [pscustomobject]@{
        configContains      = (@($cfgVerify.channels.telegram.customCommands | Where-Object { ([string]$_.command).Trim().ToLowerInvariant() -eq $NormalizedCommand }).Count -gt 0)
        generatedSkillExists = (Test-Path (Split-Path -Parent (Get-GeneratedSkillPath -NormalizedCommand $NormalizedCommand)))
        workspaceStates     = $workspaceStates
        catalogContains     = ($catalogEntries.Count -gt 0)
        disabledContains    = (@($slashState.disabledCommands) -contains $NormalizedCommand)
        menu                = Get-MenuVerification -SyncResult $SyncResult -NormalizedCommand $NormalizedCommand -ExpectPresent ($Action -ne 'delete') -SyncWasRequested $SyncWasRequested
    }
}

function Assert-MutationVerified {
    param(
        [Parameter(Mandatory = $true)][string]$NormalizedCommand,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)]$Verification,
        [Parameter(Mandatory = $true)][bool]$SyncWasRequested
    )

    $errors = New-Object System.Collections.Generic.List[string]
    $workspaceFailures = @($Verification.workspaceStates | Where-Object {
        if ($Action -eq 'delete') { $_.exists } else { -not $_.exists }
    } | ForEach-Object { Split-Path -Leaf ([string]$_.workspaceRoot) })

    if ($Action -eq 'delete') {
        if ($Verification.configContains) {
            [void]$errors.Add('config still contains command')
        }
        if ($Verification.generatedSkillExists) {
            [void]$errors.Add('generated skill still exists')
        }
        if ($workspaceFailures.Count -gt 0) {
            [void]$errors.Add(('workspace mirrors still exist: {0}' -f ($workspaceFailures -join ', ')))
        }
        if ($Verification.catalogContains) {
            [void]$errors.Add('command catalog still contains command')
        }
        if (-not $Verification.disabledContains) {
            [void]$errors.Add('slash-state did not persist deletion')
        }
    } else {
        if (-not $Verification.configContains) {
            [void]$errors.Add('config is missing command')
        }
        if (-not $Verification.generatedSkillExists) {
            [void]$errors.Add('generated skill is missing')
        }
        if ($workspaceFailures.Count -gt 0) {
            [void]$errors.Add(('workspace mirrors missing: {0}' -f ($workspaceFailures -join ', ')))
        }
        if (-not $Verification.catalogContains) {
            [void]$errors.Add('command catalog is missing command')
        }
        if ($Verification.disabledContains) {
            [void]$errors.Add('slash-state still marks command disabled')
        }
    }

    if ($SyncWasRequested -and -not $Verification.menu.allOk) {
        [void]$errors.Add(('telegram menu mismatch: {0}' -f ($Verification.menu.failedScopes -join ', ')))
    }

    if ($errors.Count -gt 0) {
        throw ("Slash mutation post-check failed for /{0}: {1}" -f $NormalizedCommand, ($errors -join '; '))
    }
}

function Test-MutationVerificationNeedsRetry {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)]$Verification,
        [Parameter(Mandatory = $true)][bool]$SyncWasRequested
    )

    $workspaceFailures = @($Verification.workspaceStates | Where-Object {
        if ($Action -eq 'delete') { $_.exists } else { -not $_.exists }
    })

    if ($Action -eq 'delete') {
        if ($Verification.configContains -or
            $Verification.generatedSkillExists -or
            $Verification.catalogContains -or
            (-not $Verification.disabledContains) -or
            $workspaceFailures.Count -gt 0) {
            return $true
        }
    } else {
        if ((-not $Verification.configContains) -or
            (-not $Verification.generatedSkillExists) -or
            (-not $Verification.catalogContains) -or
            $Verification.disabledContains -or
            $workspaceFailures.Count -gt 0) {
            return $true
        }
    }

    if ($SyncWasRequested -and -not $Verification.menu.allOk) {
        return $true
    }

    return $false
}

$mutationSnapshot = $null
function Copy-OptionalPathSnapshot {
    param(
        [AllowNull()][string]$Path,
        [Parameter(Mandatory = $true)][string]$SnapshotRoot,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $target = Join-Path $SnapshotRoot $Name
    $item = Get-Item -LiteralPath $Path
    if ($item.PSIsContainer) {
        Copy-DirectoryContents -Source $Path -Destination $target
    } else {
        $parent = Split-Path -Parent $target
        if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
        Copy-Item -LiteralPath $Path -Destination $target -Force
    }

    [pscustomobject]@{
        original = $Path
        snapshot = $target
        isDirectory = [bool]$item.PSIsContainer
        existed = $true
    }
}

function New-AbsentPathSnapshot {
    param([Parameter(Mandatory = $true)][string]$Path)

    [pscustomobject]@{
        original = $Path
        snapshot = $null
        isDirectory = $null
        existed = $false
    }
}

function New-SlashMutationSnapshot {
    param([Parameter(Mandatory = $true)][string]$NormalizedCommand)

    $root = Join-Path $paths.TempRoot ("slash-mutation-snapshot-{0}-{1}" -f $NormalizedCommand, ([guid]::NewGuid().ToString('N')))
    New-Item -ItemType Directory -Force -Path $root | Out-Null
    $entries = New-Object System.Collections.ArrayList
    foreach ($entry in @(
        (Copy-OptionalPathSnapshot -Path $ConfigPath -SnapshotRoot $root -Name 'openclaw.json'),
        (Copy-OptionalPathSnapshot -Path $MenuPriorityPath -SnapshotRoot $root -Name 'menu-priority.json'),
        (Copy-OptionalPathSnapshot -Path $slashStatePath -SnapshotRoot $root -Name 'slash-state.json'),
        (Copy-OptionalPathSnapshot -Path $paths.CommandCatalogPath -SnapshotRoot $root -Name 'command-catalog.json'),
        (Copy-OptionalPathSnapshot -Path $paths.RouteRegistryPath -SnapshotRoot $root -Name 'route-registry.json'),
        (Copy-OptionalPathSnapshot -Path $paths.GeneratedClaudeCommandsRoot -SnapshotRoot $root -Name 'generated-claude-commands')
    )) {
        if ($entry) { [void]$entries.Add($entry) }
    }
    $generatedSkillDir = Split-Path -Parent (Get-GeneratedSkillPath -NormalizedCommand $NormalizedCommand)
    $generatedEntry = Copy-OptionalPathSnapshot -Path $generatedSkillDir -SnapshotRoot $root -Name 'generated-skill'
    if ($generatedEntry) {
        [void]$entries.Add($generatedEntry)
    } else {
        [void]$entries.Add((New-AbsentPathSnapshot -Path $generatedSkillDir))
    }
    foreach ($workspaceRoot in $workspaceRoots) {
        $skillDir = Get-WorkspaceSkillDir -WorkspaceRoot $workspaceRoot -NormalizedCommand $NormalizedCommand
        $entry = Copy-OptionalPathSnapshot -Path $skillDir -SnapshotRoot $root -Name ('workspace-' + (Split-Path -Leaf $workspaceRoot))
        if ($entry) {
            [void]$entries.Add($entry)
        } else {
            [void]$entries.Add((New-AbsentPathSnapshot -Path $skillDir))
        }
    }

    [pscustomobject]@{
        root = $root
        entries = @($entries)
    }
}

function Restore-SlashMutationSnapshot {
    param([AllowNull()]$Snapshot)

    if (-not $Snapshot) { return }
    foreach ($entry in @($Snapshot.entries)) {
        if (-not $entry.existed) {
            if (Test-Path -LiteralPath $entry.original) {
                Remove-Item -LiteralPath $entry.original -Recurse -Force -ErrorAction SilentlyContinue
            }
            continue
        }
        if (Test-Path -LiteralPath $entry.original) {
            if ($entry.isDirectory) {
                Remove-Item -LiteralPath $entry.original -Recurse -Force -ErrorAction SilentlyContinue
            } else {
                Remove-Item -LiteralPath $entry.original -Force -ErrorAction SilentlyContinue
            }
        }
        $parent = Split-Path -Parent $entry.original
        if ($parent) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
        if ($entry.isDirectory) {
            Copy-DirectoryContents -Source $entry.snapshot -Destination $entry.original
        } else {
            Copy-Item -LiteralPath $entry.snapshot -Destination $entry.original -Force
        }
    }
}

if ($Action -eq "list") {
    if (Test-Path $commandCatalogSyncScript) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $commandCatalogSyncScript -ConfigPath $ConfigPath -MenuPriorityPath $MenuPriorityPath -Quiet | Out-Null
    }
    $cfg = Get-Content -Raw $ConfigPath | ConvertFrom-Json
    @($cfg.channels.telegram.customCommands) | Sort-Object command | ConvertTo-Json -Depth 8
    exit 0
}

$normalizedCommand = Normalize-CommandName $CommandName
$cfg = Get-Content -Raw $ConfigPath | ConvertFrom-Json
$commandExistsInConfig = Test-CommandExistsInConfig -Config $cfg -NormalizedCommand $normalizedCommand
$generatedSkillExistsBeforeMutation = Test-Path -LiteralPath (Get-GeneratedSkillPath -NormalizedCommand $normalizedCommand)

if ($script:nativeReservedCommands.Contains($normalizedCommand) -and $Action -in @('add', 'update')) {
    throw "Native Telegram command '/$normalizedCommand' is reserved and cannot be added or updated through /slash mutation."
}

if ($script:updateOnlyInfrastructureCommands.Contains($normalizedCommand)) {
    if ($Action -eq 'add') {
        throw "Protected OpenClaw infrastructure command '/$normalizedCommand' cannot be added through /slash mutation. Use update on the existing canonical command instead."
    }
    if ($Action -eq 'delete') {
        throw "Protected OpenClaw infrastructure command '/$normalizedCommand' cannot be deleted through /slash mutation."
    }
    if ($Action -eq 'update' -and -not ($commandExistsInConfig -or $generatedSkillExistsBeforeMutation)) {
        throw "Protected OpenClaw infrastructure command '/$normalizedCommand' can only be updated when the canonical command already exists."
    }
}

$script:mutationSnapshot = New-SlashMutationSnapshot -NormalizedCommand $normalizedCommand
trap {
    $originalError = $_
    Restore-SlashMutationSnapshot -Snapshot $script:mutationSnapshot
    throw $originalError
}

$existingPriority = @(Get-MenuPriorityCommands -TelegramConfig $cfg.channels.telegram -PriorityPath $MenuPriorityPath)

if (-not $cfg.channels.telegram.customCommands) {
    $cfg.channels.telegram | Add-Member -NotePropertyName customCommands -NotePropertyValue @()
}

$existing = @($cfg.channels.telegram.customCommands)
$next = New-Object System.Collections.ArrayList
foreach ($item in $existing) {
    if (-not $item.command) { continue }
    if ([string]$item.command -ieq $normalizedCommand) { continue }
    [void]$next.Add([pscustomobject]@{
        command = [string]$item.command
        description = Normalize-CommandDescription -Description ([string]$item.description) -NormalizedCommand ([string]$item.command)
    })
}

$slashState = Get-SlashState -Path $slashStatePath
$updatedDisabledCommands = @($slashState.disabledCommands)
if ($Action -eq "delete") {
    $updatedDisabledCommands = @($updatedDisabledCommands + $normalizedCommand | Select-Object -Unique | Sort-Object)
} else {
    $updatedDisabledCommands = @($updatedDisabledCommands | Where-Object { $_ -ne $normalizedCommand } | Select-Object -Unique | Sort-Object)
}

if ($Action -in @("add", "update")) {
    if ([string]::IsNullOrWhiteSpace($Description)) {
        throw "Description is required for add/update."
    }
    if ([string]::IsNullOrWhiteSpace($SkillBodyBase64)) {
        throw "SkillBodyBase64 is required for add/update."
    }

    $skillBody = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($SkillBodyBase64))
    [void]$next.Add([pscustomobject]@{
        command = $normalizedCommand
        description = Normalize-CommandDescription -Description $Description -NormalizedCommand $normalizedCommand
    })

    $generatedSkillPath = Get-GeneratedSkillPath -NormalizedCommand $normalizedCommand
    $generatedSkillDir = Split-Path -Parent $generatedSkillPath
    New-Item -ItemType Directory -Force -Path $generatedSkillDir | Out-Null
    [System.IO.File]::WriteAllText($generatedSkillPath, $skillBody, [System.Text.Encoding]::UTF8)
    Register-OpenClawManagedFile -Path $generatedSkillPath -Kind 'generated-telegram-skill' -Source $normalizedCommand -GeneratedBy 'Set-OpenClawSlashCommand.ps1'
    Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
        command = $normalizedCommand
        generatedAt = (Get-Date).ToString('o')
        generationId = $paths.AuthorityGenerationId
    }) -Path (Join-Path $generatedSkillDir '.openclaw-managed.json') -Kind 'generated-telegram-skill-metadata' -Source $normalizedCommand
}

if ($Action -eq "delete") {
    $generatedSkillPath = Get-GeneratedSkillPath -NormalizedCommand $normalizedCommand
    $generatedSkillDir = Split-Path -Parent $generatedSkillPath
    if (Test-Path $generatedSkillDir) {
        Remove-Item -LiteralPath $generatedSkillDir -Recurse -Force
    }
    foreach ($workspaceRoot in $workspaceRoots) {
        $skillPath = Get-WorkspaceSkillPath -WorkspaceRoot $workspaceRoot -NormalizedCommand $normalizedCommand
        $skillDir = Split-Path -Parent $skillPath
        if (Test-Path $skillDir) {
            Remove-Item -LiteralPath $skillDir -Recurse -Force
        }
    }
}

$cfg.channels.telegram.customCommands = @($next | Sort-Object command)
$updatedPriority = @(Get-UpdatedMenuPriority -ExistingPriority $existingPriority -NormalizedCommand $normalizedCommand -Action $Action)
if ($cfg.channels.telegram.PSObject.Properties.Name -contains "menuPriorityCommands") {
    [void]$cfg.channels.telegram.PSObject.Properties.Remove("menuPriorityCommands")
}
Save-OpenClawConfigFile -Config $cfg -LastWriter 'Set-OpenClawSlashCommand'
Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{ commands = $updatedPriority }) -Path $MenuPriorityPath -Kind 'menu-priority' -Source 'Set-OpenClawSlashCommand.ps1'
Save-SlashState -State ([pscustomobject]@{ disabledCommands = $updatedDisabledCommands }) -Path $slashStatePath

$catalogSyncResult = $null
$catalogSynced = $false
if (Test-Path $commandCatalogSyncScript) {
    $catalogSyncResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $commandCatalogSyncScript -ConfigPath $ConfigPath -MenuPriorityPath $MenuPriorityPath
    $catalogSynced = $true
} elseif (Test-Path $workspaceSkillSyncScript) {
    $catalogSyncResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $workspaceSkillSyncScript -ConfigPath $ConfigPath
    $catalogSynced = $true
}

$syncResult = $null
if (-not $SkipMenuSync) {
    $syncResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $menuSyncScript -ConfigPath $ConfigPath -MenuPriorityPath $MenuPriorityPath
}

$catalogSyncResult = ConvertFrom-JsonSafe -Value $catalogSyncResult
$syncResult = ConvertFrom-JsonSafe -Value $syncResult
$syncWasRequested = [bool](-not $SkipMenuSync)
$verification = $null
$maxVerificationAttempts = if ($Action -eq 'delete') { 4 } else { 3 }
for ($attempt = 1; $attempt -le $maxVerificationAttempts; $attempt++) {
    $verification = Get-MutationVerification -NormalizedCommand $normalizedCommand -Action $Action -SyncResult $syncResult -SyncWasRequested $syncWasRequested
    if (-not (Test-MutationVerificationNeedsRetry -Action $Action -Verification $verification -SyncWasRequested $syncWasRequested)) {
        break
    }

    if ($attempt -eq $maxVerificationAttempts) {
        break
    }

    Start-Sleep -Milliseconds (250 * $attempt)
    if (Test-Path $commandCatalogSyncScript) {
        $catalogSyncResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $commandCatalogSyncScript -ConfigPath $ConfigPath -MenuPriorityPath $MenuPriorityPath -Quiet
        $catalogSynced = $true
        $catalogSyncResult = ConvertFrom-JsonSafe -Value $catalogSyncResult
    } elseif (Test-Path $workspaceSkillSyncScript) {
        $catalogSyncResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $workspaceSkillSyncScript -ConfigPath $ConfigPath -Quiet
        $catalogSynced = $true
        $catalogSyncResult = ConvertFrom-JsonSafe -Value $catalogSyncResult
    }

    if ($syncWasRequested) {
        $syncResult = & powershell -NoProfile -ExecutionPolicy Bypass -File $menuSyncScript -ConfigPath $ConfigPath -MenuPriorityPath $MenuPriorityPath
        $syncResult = ConvertFrom-JsonSafe -Value $syncResult
    }
}

Assert-MutationVerified -NormalizedCommand $normalizedCommand -Action $Action -Verification $verification -SyncWasRequested $syncWasRequested

[pscustomobject]@{
    action = $Action
    command = $normalizedCommand
    description = $Description
    generatedSkillRoot = $generatedCustomCommandsRoot
    workspaces = $workspaceRoots
    menuPriorityCommands = $updatedPriority
    catalogSynced = $catalogSynced
    catalogSyncResult = $catalogSyncResult
    synced = [bool]($verification.menu.allOk -or $SkipMenuSync)
    syncResult = $syncResult
    verification = $verification
} | ConvertTo-Json -Depth 20
