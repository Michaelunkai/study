. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\OpenClawAuthority.ps1'

function Get-OpenClawActiveRuntimePrefix {
    param([Parameter(Mandatory = $true)][string]$RepoRoot)

    $authority = Get-OpenClawAuthority
    if ($authority -and $authority.runtime -and -not [string]::IsNullOrWhiteSpace([string]$authority.runtime.commandRoot)) {
        return [string]$authority.runtime.commandRoot
    }

    return (Join-Path $RepoRoot 'npm-global')
}

function Resolve-OpenClawNodeExePath {
    $candidates = New-Object System.Collections.Generic.List[string]
    $programFiles = [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles)
    if (-not [string]::IsNullOrWhiteSpace($programFiles)) {
        [void]$candidates.Add((Join-Path $programFiles 'nodejs\node.exe'))
    }

    foreach ($segment in @(($env:PATH -split ';') | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })) {
        try {
            [void]$candidates.Add((Join-Path -Path $segment.Trim() -ChildPath 'node.exe' -ErrorAction Stop))
        } catch {
        }
    }

    foreach ($candidate in $candidates | Select-Object -Unique) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return 'C:\Program Files\nodejs\node.exe'
}

function Get-OpenClawPaths {
    $authority = Get-OpenClawAuthority
    $repoRoot = [string]$authority.repo.root
    $stateRoot = [string]$authority.state.root
    $configPath = [string]$authority.state.configPath
    $runtimeCommandRoot = [string]$authority.runtime.commandRoot
    $npmGlobalRoot = Join-Path $repoRoot 'npm-global'

    $workspaceMap = [ordered]@{
        main      = Join-Path $stateRoot 'workspace-openclaw-main'
        session2  = Join-Path $stateRoot 'workspace-moltbot2'
        openclaw  = Join-Path $stateRoot 'workspace-moltbot'
        openclaw4 = Join-Path $stateRoot 'workspace-openclaw'
    }

    [pscustomobject]@{
        RepoRoot                    = $repoRoot
        StateRoot                   = $stateRoot
        TempRoot                    = Join-Path $stateRoot 'tmp'
        ConfigPath                  = $configPath
        GeneratedSkillsRoot         = Join-Path $stateRoot 'generated-skills'
        GeneratedCustomCommandsRoot = Join-Path $stateRoot 'generated-skills\custom-commands'
        GeneratedClaudeCommandsRoot = Join-Path $stateRoot 'generated-skills\claude-commands'
        VersionsRoot                = Join-Path $repoRoot 'versions'
        ToolNodeRoot                = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw-tool-cache\node-tools'
        ToolNodeBinRoot             = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw-tool-cache\node-tools\node_modules\.bin'
        NpmGlobalRoot               = $npmGlobalRoot
        RuntimeCommandRoot          = $runtimeCommandRoot
        RuntimeRoot                 = [string]$authority.runtime.runtimeRoot
        RuntimeEntrypoint           = [string]$authority.runtime.entrypoint
        RuntimeDistEntrypoint       = [string]$authority.runtime.distEntrypoint
        RuntimePointerPath          = (Get-OpenClawCanonicalDefaults).RuntimePointerPath
        RuntimeHistoryPath          = (Get-OpenClawCanonicalDefaults).RuntimeHistoryPath
        RuntimePatchManifestPath    = (Get-OpenClawCanonicalDefaults).RuntimePatchManifestPath
        RuntimeGenerationId         = [string]$authority.runtime.generationId
        TrayRoot                    = Join-Path $repoRoot 'ClawdBot'
        TrayLauncherVbs             = Join-Path $repoRoot 'ClawdBot\ClawdbotTray.vbs'
        TrayManagerExe              = Join-Path $repoRoot 'ClawdBot\ClawdBotManager.exe'
        AgentsRoot                  = Join-Path $stateRoot 'agents'
        TelegramRoot                = Join-Path $stateRoot 'telegram'
        ChannelsRoot                = Join-Path $stateRoot 'channels'
        MenuPriorityPath            = Join-Path $stateRoot 'telegram\menu-priority.json'
        CommandCatalogPath          = Join-Path $stateRoot 'telegram\command-catalog.json'
        SlashStatePath              = Join-Path $stateRoot 'telegram\slash-state.json'
        RouteRegistryPath           = Join-Path $stateRoot 'telegram\route-registry.json'
        TokenPath                   = Join-Path $stateRoot 'token.json'
        DiscordTokenBackupPath      = Join-Path $stateRoot 'discord_tokens_backup.json'
        Workspaces                  = [pscustomobject]$workspaceMap
        WorkspaceRoots              = @($workspaceMap.Values)
        ManifestPath                = [string](Get-OpenClawCanonicalDefaults).ManifestPath
        ManagedStatePath            = [string](Get-OpenClawCanonicalDefaults).ManagedStatePath
        AuthorityRoot               = [string](Get-OpenClawCanonicalDefaults).AuthorityRoot
        AuthorityGenerationId       = [string]$authority.generationId
        RepoIdentityPath            = [string](Get-OpenClawCanonicalDefaults).RepoIdentityPath
        MachineIdentityPath         = [string](Get-OpenClawCanonicalDefaults).MachineIdentityPath
        AliasStateRoot              = 'C:\Users\micha\.openclaw'
        AliasConfigPath             = 'C:\Users\micha\.clawdbot\openclaw.json'
        BackupManifestPath          = [string](Get-OpenClawCanonicalDefaults).BackupManifestPath
        RecoveryReportPath          = [string](Get-OpenClawCanonicalDefaults).RecoveryReportPath
        ConfigAuthorityPath         = [string](Get-OpenClawCanonicalDefaults).ConfigAuthorityPath
        NodeExePath                 = Resolve-OpenClawNodeExePath
    }
}

function Ensure-OpenClawPathLayout {
    param(
        [Parameter(Mandatory = $true)]
        $Paths
    )

    foreach ($path in @(
        $Paths.StateRoot,
        $Paths.TempRoot,
        $Paths.GeneratedSkillsRoot,
        $Paths.GeneratedCustomCommandsRoot,
        $Paths.GeneratedClaudeCommandsRoot,
        $Paths.AgentsRoot,
        $Paths.TelegramRoot,
        $Paths.ChannelsRoot,
        $Paths.AuthorityRoot
    ) + $Paths.WorkspaceRoots) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }
}

function Set-OpenClawProcessEnvironment {
    param([switch]$PersistUser)

    $authority = Get-OpenClawAuthority -EnsureFiles
    $paths = Get-OpenClawPaths
    Ensure-OpenClawPathLayout -Paths $paths

    $envMap = [ordered]@{
        OPENCLAW_REPO_ROOT = $paths.RepoRoot
        OPENCLAW_STATE_DIR = $paths.StateRoot
        OPENCLAW_CONFIG_PATH = $paths.ConfigPath
        OPENCLAW_TMP_DIR = $paths.TempRoot
        OPENCLAW_AUTHORITY_MANIFEST_PATH = $paths.ManifestPath
        OPENCLAW_AUTHORITY_GENERATION = $paths.AuthorityGenerationId
        OPENCLAW_RUNTIME_COMMAND_ROOT = $paths.RuntimeCommandRoot
        OPENCLAW_RUNTIME_GENERATION = $paths.RuntimeGenerationId
    }

    foreach ($entry in $envMap.GetEnumerator()) {
        Set-Item -Path ("Env:{0}" -f $entry.Key) -Value $entry.Value
        if ($PersistUser) {
            [Environment]::SetEnvironmentVariable($entry.Key, $entry.Value, 'User')
        }
    }

    return $paths
}
