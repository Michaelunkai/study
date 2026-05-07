Set-StrictMode -Version Latest

function Get-OpenClawCanonicalDefaults {
    $repoRoot = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw'
    $stateRoot = Join-Path $repoRoot 'openclaw-home'
    $configPath = Join-Path $stateRoot 'openclaw.json'
    $runtimeCommandRoot = Join-Path $repoRoot 'npm-global'
    $versionsRoot = Join-Path $repoRoot 'versions'
    $authorityRoot = Join-Path $stateRoot 'authority'
    $canonicalWrappers = Join-Path $repoRoot 'npm-global'

    [pscustomobject]@{
        SchemaVersion = '2026-04-29.1'
        RepoRoot = $repoRoot
        StateRoot = $stateRoot
        ConfigPath = $configPath
        RuntimeCommandRoot = $runtimeCommandRoot
        VersionsRoot = $versionsRoot
        AuthorityRoot = $authorityRoot
        ManifestPath = Join-Path $authorityRoot 'authority-manifest.json'
        RuntimePointerPath = Join-Path $authorityRoot 'active-runtime.json'
        RuntimeHistoryPath = Join-Path $authorityRoot 'runtime-history.json'
        RuntimePatchManifestPath = Join-Path $authorityRoot 'runtime-patch-manifest.json'
        ManagedStatePath = Join-Path $authorityRoot 'managed-files.json'
        RepoIdentityPath = Join-Path $authorityRoot 'repo-identity.json'
        MachineIdentityPath = Join-Path $authorityRoot 'machine-identity.json'
        AuditLogPath = Join-Path $authorityRoot 'audit.log'
        SnapshotRoot = Join-Path $authorityRoot 'snapshots'
        BackupManifestPath = Join-Path $authorityRoot 'backup-manifest.json'
        RecoveryReportPath = Join-Path $authorityRoot 'recovery-report.json'
        ConfigAuthorityPath = Join-Path $authorityRoot 'openclaw-config-authority.json'
        WrapperRoots = [pscustomobject]@{
            canonical = $canonicalWrappers
            user = Join-Path $env:LOCALAPPDATA 'npm-global'
            roaming = Join-Path $env:APPDATA 'npm'
        }
        Aliases = @(
            [pscustomobject]@{
                path = 'C:\Users\micha\.openclaw'
                target = $stateRoot
                type = 'directory'
            },
            [pscustomobject]@{
                path = 'C:\Users\micha\.clawdbot\openclaw.json'
                target = $configPath
                type = 'file'
            }
        )
        Env = [pscustomobject]@{
            OPENCLAW_REPO_ROOT = $repoRoot
            OPENCLAW_STATE_DIR = $stateRoot
            OPENCLAW_CONFIG_PATH = $configPath
            OPENCLAW_TMP_DIR = Join-Path $stateRoot 'tmp'
            OPENCLAW_AUTHORITY_MANIFEST_PATH = Join-Path $authorityRoot 'authority-manifest.json'
        }
        Tasks = @(
            [pscustomobject]@{
                name = 'ClawdBotTray'
                target = ('"{0}\System32\wscript.exe" //B //Nologo "{1}"' -f $env:SystemRoot, (Join-Path $repoRoot 'ClawdBot\ClawdbotTray.vbs'))
                enabled = $true
            },
            [pscustomobject]@{
                name = 'OpenClaw Gateway'
                target = ('"{0}"' -f (Join-Path $stateRoot 'gateway.cmd'))
                enabled = $false
            }
        )
        TelegramBindings = @(
            [pscustomobject]@{ agentId = 'main'; accountId = 'bot1'; workspace = Join-Path $stateRoot 'workspace-openclaw-main' },
            [pscustomobject]@{ agentId = 'session2'; accountId = 'bot2'; workspace = Join-Path $stateRoot 'workspace-moltbot2' },
            [pscustomobject]@{ agentId = 'openclaw'; accountId = 'openclaw'; workspace = Join-Path $stateRoot 'workspace-moltbot' },
            [pscustomobject]@{ agentId = 'openclaw4'; accountId = 'openclaw4'; workspace = Join-Path $stateRoot 'workspace-openclaw' }
        )
    }
}

function ConvertTo-OpenClawHash {
    param([Parameter(Mandatory = $true)][string]$Text)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
        $hashBytes = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hashBytes)).Replace('-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Save-OpenClawJsonFile {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Path
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $json = $Object | ConvertTo-Json -Depth 100
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)

    for ($attempt = 1; $attempt -le 12; $attempt++) {
        $tempPath = Join-Path $parent ("{0}.{1}.tmp" -f ([System.IO.Path]::GetFileName($Path)), ([guid]::NewGuid().ToString('N')))
        $backupPath = Join-Path $parent ("{0}.{1}.bak" -f ([System.IO.Path]::GetFileName($Path)), ([guid]::NewGuid().ToString('N')))
        try {
            [System.IO.File]::WriteAllText($tempPath, $json, $utf8NoBom)
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
            if ($attempt -eq 12) {
                [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
                return
            }
            Start-Sleep -Milliseconds (150 * $attempt)
        }
    }
}

function Get-OpenClawIdentityValue {
    param([Parameter(Mandatory = $true)][string]$RegistryPath, [Parameter(Mandatory = $true)][string]$Name)

    try {
        $item = Get-ItemProperty -Path $RegistryPath -ErrorAction Stop
        $value = $item.$Name
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return [string]$value
        }
    } catch {
    }

    return $null
}

function Get-OpenClawMachineIdentityObject {
    $machineGuid = Get-OpenClawIdentityValue -RegistryPath 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name 'MachineGuid'
    $base = '{0}|{1}|{2}' -f $env:COMPUTERNAME, $env:USERNAME, $machineGuid
    $machineId = (ConvertTo-OpenClawHash -Text $base).Substring(0, 16)

    [pscustomobject]@{
        machineId = $machineId
        computerName = $env:COMPUTERNAME
        userName = $env:USERNAME
        machineGuid = $machineGuid
    }
}

function Get-OpenClawRepoIdentityObject {
    $defaults = Get-OpenClawCanonicalDefaults
    $repoId = (ConvertTo-OpenClawHash -Text ('repo|' + $defaults.RepoRoot)).Substring(0, 16)
    [pscustomobject]@{
        repoId = $repoId
        repoRoot = $defaults.RepoRoot
        stateRoot = $defaults.StateRoot
    }
}

function Get-OpenClawRuntimePointerRecord {
    $defaults = Get-OpenClawCanonicalDefaults
    $record = $null
    if (Test-Path -LiteralPath $defaults.RuntimePointerPath) {
        try {
            $record = Get-Content -Raw -LiteralPath $defaults.RuntimePointerPath | ConvertFrom-Json
        } catch {
            $record = $null
        }
    }

    $commandRoot = $defaults.RuntimeCommandRoot
    if ($record -and -not [string]::IsNullOrWhiteSpace([string]$record.commandRoot)) {
        $candidate = [string]$record.commandRoot
        if (Test-Path -LiteralPath (Join-Path $candidate 'node_modules\openclaw\package.json')) {
            $commandRoot = $candidate
        }
    } elseif (-not [string]::IsNullOrWhiteSpace($env:OPENCLAW_RUNTIME_COMMAND_ROOT)) {
        $candidate = $env:OPENCLAW_RUNTIME_COMMAND_ROOT.Trim()
        if (Test-Path -LiteralPath (Join-Path $candidate 'node_modules\openclaw\package.json')) {
            $commandRoot = $candidate
        }
    }

    $entrypoint = Join-Path $commandRoot 'node_modules\openclaw\dist\index.js'
    $runtimeRoot = Join-Path $commandRoot 'node_modules\openclaw'
    $generationId = (ConvertTo-OpenClawHash -Text ('runtime|' + $commandRoot + '|' + $entrypoint)).Substring(0, 16)

    [pscustomobject]@{
        commandRoot = $commandRoot
        runtimeRoot = $runtimeRoot
        entrypoint = Join-Path $commandRoot 'node_modules\openclaw\openclaw.mjs'
        distEntrypoint = $entrypoint
        generationId = $generationId
    }
}

function New-OpenClawAuthorityManifestObject {
    $defaults = Get-OpenClawCanonicalDefaults
    $runtime = Get-OpenClawRuntimePointerRecord
    $machine = Get-OpenClawMachineIdentityObject
    $repoIdentity = Get-OpenClawRepoIdentityObject
    $generationSeed = @(
        $defaults.SchemaVersion
        $defaults.RepoRoot
        $defaults.StateRoot
        $defaults.ConfigPath
        $runtime.commandRoot
        ($defaults.TelegramBindings | ForEach-Object { "$($_.agentId)|$($_.accountId)|$($_.workspace)" })
    ) -join '|'
    $generationId = (ConvertTo-OpenClawHash -Text $generationSeed).Substring(0, 16)

    [pscustomobject]@{
        schemaVersion = $defaults.SchemaVersion
        generatedAt = (Get-Date).ToString('o')
        generationId = $generationId
        repo = [pscustomobject]@{
            root = $defaults.RepoRoot
            identity = $repoIdentity
        }
        state = [pscustomobject]@{
            root = $defaults.StateRoot
            configPath = $defaults.ConfigPath
            authorityRoot = $defaults.AuthorityRoot
            tempRoot = $defaults.Env.OPENCLAW_TMP_DIR
        }
        runtime = $runtime
        wrappers = $defaults.WrapperRoots
        aliases = $defaults.Aliases
        env = $defaults.Env
        tasks = $defaults.Tasks
        telegram = [pscustomobject]@{
            bindings = $defaults.TelegramBindings
            expectedAccountCount = 4
        }
        machine = $machine
    }
}

function Write-OpenClawAuditLog {
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [string]$Detail
    )

    $defaults = Get-OpenClawCanonicalDefaults
    $line = '[{0}] {1} {2}' -f (Get-Date).ToString('o'), $Action, $Detail
    $parent = Split-Path -Parent $defaults.AuditLogPath
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Add-Content -LiteralPath $defaults.AuditLogPath -Value $line
}

function Ensure-OpenClawAuthorityFiles {
    param([switch]$Force)

    $defaults = Get-OpenClawCanonicalDefaults
    foreach ($path in @($defaults.AuthorityRoot, $defaults.SnapshotRoot)) {
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
    }

    $machine = Get-OpenClawMachineIdentityObject
    $repoIdentity = Get-OpenClawRepoIdentityObject
    $runtime = Get-OpenClawRuntimePointerRecord

    if ($Force -or -not (Test-Path -LiteralPath $defaults.MachineIdentityPath)) {
        Save-OpenClawJsonFile -Object $machine -Path $defaults.MachineIdentityPath
    }
    if ($Force -or -not (Test-Path -LiteralPath $defaults.RepoIdentityPath)) {
        Save-OpenClawJsonFile -Object $repoIdentity -Path $defaults.RepoIdentityPath
    }

    $runtimeRecord = [pscustomobject]@{
        commandRoot = $runtime.commandRoot
        updatedAt = (Get-Date).ToString('o')
    }
    if ($Force -or -not (Test-Path -LiteralPath $defaults.RuntimePointerPath)) {
        Save-OpenClawJsonFile -Object $runtimeRecord -Path $defaults.RuntimePointerPath
    }
    if ($Force -or -not (Test-Path -LiteralPath $defaults.RuntimePatchManifestPath)) {
        Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
            updatedAt = (Get-Date).ToString('o')
            activeCommandRoot = $runtime.commandRoot
            entries = @(
                [pscustomobject]@{
                    commandRoot = $runtime.commandRoot
                    expectedPackagePath = (Join-Path $runtime.commandRoot 'node_modules\openclaw\package.json')
                    patches = @()
                    verification = @(
                        'Test-OpenClawAuthority.ps1',
                        'Invoke-OpenClawSmoke.ps1 -SkipTelegramNetwork',
                        'Test-OpenClawTelegramIntegrity.ps1'
                    )
                }
            )
        }) -Path $defaults.RuntimePatchManifestPath -Kind 'runtime-patch-manifest' -Source 'OpenClawAuthority.ps1'
    }

    $manifest = New-OpenClawAuthorityManifestObject
    if ($Force -or -not (Test-Path -LiteralPath $defaults.ManifestPath)) {
        Save-OpenClawJsonFile -Object $manifest -Path $defaults.ManifestPath
    } else {
        try {
            $existing = Get-Content -Raw -LiteralPath $defaults.ManifestPath | ConvertFrom-Json
        } catch {
            $existing = $null
        }
        if ($Force -or -not $existing -or [string]$existing.generationId -ne [string]$manifest.generationId -or [string]$existing.runtime.commandRoot -ne [string]$manifest.runtime.commandRoot) {
            Save-OpenClawJsonFile -Object $manifest -Path $defaults.ManifestPath
        }
    }

    return $manifest
}

function Get-OpenClawAuthority {
    param([switch]$EnsureFiles)

    $defaults = Get-OpenClawCanonicalDefaults
    if ($EnsureFiles) {
        return Ensure-OpenClawAuthorityFiles
    }

    if (Test-Path -LiteralPath $defaults.ManifestPath) {
        try {
            return Get-Content -Raw -LiteralPath $defaults.ManifestPath | ConvertFrom-Json
        } catch {
        }
    }

    return New-OpenClawAuthorityManifestObject
}

function Set-OpenClawObjectProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value
    )

    if ($Object.PSObject.Properties.Name -contains $Name) {
        $Object.$Name = $Value
    } else {
        $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Set-OpenClawConfigAuthorityMetadata {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [Parameter(Mandatory = $true)]$Authority,
        [string]$LastWriter = "$env:COMPUTERNAME\$env:USERNAME"
    )

    if ($Config.PSObject.Properties.Name -notcontains 'meta' -or $null -eq $Config.meta) {
        Set-OpenClawObjectProperty -Object $Config -Name 'meta' -Value ([pscustomobject]@{})
    }

    if ($Config.meta.PSObject.Properties.Name -contains 'authority') {
        [void]$Config.meta.PSObject.Properties.Remove('authority')
    }
    Set-OpenClawObjectProperty -Object $Config.meta -Name 'lastTouchedAt' -Value ((Get-Date).ToString('o'))
    return $Config
}

function Save-OpenClawConfigAuthoritySidecar {
    param(
        [Parameter(Mandatory = $true)]$Authority,
        [string]$LastWriter = "$env:COMPUTERNAME\$env:USERNAME"
    )

    $defaults = Get-OpenClawCanonicalDefaults
    Save-OpenClawManagedJsonFile -Object ([pscustomobject]@{
        generationId = $Authority.generationId
        canonicalRepoRoot = $Authority.repo.root
        canonicalStateRoot = $Authority.state.root
        canonicalConfigPath = $Authority.state.configPath
        runtimeCommandRoot = $Authority.runtime.commandRoot
        runtimeGenerationId = $Authority.runtime.generationId
        lastWriter = $LastWriter
        updatedAt = (Get-Date).ToString('o')
    }) -Path $defaults.ConfigAuthorityPath -Kind 'config-authority' -Source 'OpenClawAuthority.ps1'
}

function Save-OpenClawConfigFile {
    param(
        [Parameter(Mandatory = $true)]$Config,
        [string]$LastWriter = "$env:COMPUTERNAME\$env:USERNAME"
    )

    $authority = Get-OpenClawAuthority -EnsureFiles
    $defaults = Get-OpenClawCanonicalDefaults
    $config = Set-OpenClawConfigAuthorityMetadata -Config $Config -Authority $authority -LastWriter $LastWriter
    $configPath = $defaults.ConfigPath
    $snapshotStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $snapshotPath = Join-Path $defaults.SnapshotRoot ("openclaw.{0}.json" -f $snapshotStamp)
    $lastGoodPath = $configPath + '.last-good'

    if (Test-Path -LiteralPath $configPath) {
        try {
            Copy-Item -LiteralPath $configPath -Destination $snapshotPath -Force
        } catch {
        }
        try {
            Copy-Item -LiteralPath $configPath -Destination $lastGoodPath -Force
        } catch {
        }
    }

    Save-OpenClawJsonFile -Object $config -Path $configPath
    Save-OpenClawConfigAuthoritySidecar -Authority $authority -LastWriter $LastWriter
    Write-OpenClawAuditLog -Action 'config-write' -Detail ("writer={0} generation={1}" -f $LastWriter, $authority.generationId)
    return $config
}

function Get-OpenClawManagedState {
    $defaults = Get-OpenClawCanonicalDefaults
    if (-not (Test-Path -LiteralPath $defaults.ManagedStatePath)) {
        return [pscustomobject]@{
            generationId = (Get-OpenClawAuthority).generationId
            files = @()
        }
    }

    try {
        return Get-Content -Raw -LiteralPath $defaults.ManagedStatePath | ConvertFrom-Json
    } catch {
        return [pscustomobject]@{
            generationId = (Get-OpenClawAuthority).generationId
            files = @()
        }
    }
}

function Save-OpenClawManagedState {
    param([Parameter(Mandatory = $true)]$State)

    $defaults = Get-OpenClawCanonicalDefaults
    Save-OpenClawJsonFile -Object $State -Path $defaults.ManagedStatePath
}

function Register-OpenClawManagedFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Kind,
        [string]$Source,
        [string]$GeneratedBy
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    $authority = Get-OpenClawAuthority
    $resolved = [System.IO.Path]::GetFullPath($Path)
    $state = Get-OpenClawManagedState
    $items = @($state.files)
    $remaining = @($items | Where-Object { [string]$_.path -ne $resolved })
    $entry = [pscustomobject]@{
        path = $resolved
        kind = $Kind
        source = $Source
        generatedBy = $GeneratedBy
        generationId = $authority.generationId
        runtimeGenerationId = $authority.runtime.generationId
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolved).Hash
        updatedAt = (Get-Date).ToString('o')
    }
    $state.generationId = $authority.generationId
    $state.files = @($remaining + $entry)
    Save-OpenClawManagedState -State $state
}

function Write-OpenClawManagedTextFile {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Kind,
        [string]$Source,
        [string]$GeneratedBy = $MyInvocation.MyCommand.Name,
        [string]$CommentPrefix = '#'
    )

    $authority = Get-OpenClawAuthority
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $header = @(
        '{0} OpenClaw managed file' -f $CommentPrefix
        '{0} kind: {1}' -f $CommentPrefix, $Kind
        '{0} authority_generation: {1}' -f $CommentPrefix, $authority.generationId
        '{0} runtime_generation: {1}' -f $CommentPrefix, $authority.runtime.generationId
        '{0} source: {1}' -f $CommentPrefix, $Source
        ''
    ) -join [Environment]::NewLine

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $header + $Content, $utf8NoBom)
    Register-OpenClawManagedFile -Path $Path -Kind $Kind -Source $Source -GeneratedBy $GeneratedBy
}

function Save-OpenClawManagedJsonFile {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Kind,
        [string]$Source,
        [string]$GeneratedBy = $MyInvocation.MyCommand.Name
    )

    $authority = Get-OpenClawAuthority
    if ($Object -isnot [psobject]) {
        $Object = [pscustomobject]$Object
    }
    Set-OpenClawObjectProperty -Object $Object -Name 'openclawAuthority' -Value ([pscustomobject]@{
        generationId = $authority.generationId
        runtimeGenerationId = $authority.runtime.generationId
        repoRoot = $authority.repo.root
        stateRoot = $authority.state.root
        source = $Source
        kind = $Kind
        updatedAt = (Get-Date).ToString('o')
    })
    Save-OpenClawJsonFile -Object $Object -Path $Path
    Register-OpenClawManagedFile -Path $Path -Kind $Kind -Source $Source -GeneratedBy $GeneratedBy
}

function Get-OpenClawExpectedGatewayContent {
    param([Parameter(Mandatory = $true)]$Paths)

    $authority = Get-OpenClawAuthority
    @"
@echo off
setlocal EnableExtensions
set "HOME=$env:USERPROFILE"
set "TMPDIR=$env:LOCALAPPDATA\Temp"
set "OPENCLAW_STATE_DIR=$($Paths.StateRoot)"
set "OPENCLAW_CONFIG_PATH=$($Paths.ConfigPath)"
set "OPENCLAW_GATEWAY_PORT=18789"
set "OPENCLAW_SYSTEMD_UNIT=openclaw-gateway.service"
set "OPENCLAW_WINDOWS_TASK_NAME=OpenClaw Gateway"
set "OPENCLAW_SERVICE_MARKER=openclaw"
set "OPENCLAW_SERVICE_KIND=gateway"
set "OPENCLAW_SERVICE_VERSION=$($authority.schemaVersion)"
set "OPENCLAW_REPO_ROOT=$($Paths.RepoRoot)"
set "OPENCLAW_AUTHORITY_MANIFEST_PATH=$($Paths.ManifestPath)"
set "OPENCLAW_AUTHORITY_GENERATION=$($Paths.AuthorityGenerationId)"
set "OPENCLAW_RUNTIME_COMMAND_ROOT=$($Paths.RuntimeCommandRoot)"
set "OPENCLAW_RUNTIME_GENERATION=$($Paths.RuntimeGenerationId)"
set "POWERSHELL_EXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%POWERSHELL_EXE%" "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "$($Paths.RepoRoot)\scripts\telegram-global\Sync-OpenClawCommandCatalog.ps1" -Quiet
if exist "%POWERSHELL_EXE%" "%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "$($Paths.RepoRoot)\scripts\telegram-global\Repair-OpenClawTelegramRoutes.ps1" -Quiet
"$($Paths.NodeExePath)" "$($Paths.RuntimeDistEntrypoint)" gateway run --port 18789
"@
}
