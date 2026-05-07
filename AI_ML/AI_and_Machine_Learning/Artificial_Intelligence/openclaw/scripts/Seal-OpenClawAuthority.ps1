param(
    [switch]$PersistUser,
    [switch]$SkipTelegramRefresh,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'

function Ensure-SymbolicAlias {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][ValidateSet('directory','file')][string]$Type
    )

    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path -LiteralPath $Path) {
        try {
            $item = Get-Item -LiteralPath $Path -Force
            if ($item.LinkType -and $item.Target) {
                $currentTarget = if ($item.Target -is [System.Array]) { [string]$item.Target[0] } else { [string]$item.Target }
                if ([System.IO.Path]::GetFullPath($currentTarget) -eq [System.IO.Path]::GetFullPath($Target)) {
                    return
                }
            }
        } catch {
        }

        Remove-Item -LiteralPath $Path -Recurse -Force
    }

    if ($Type -eq 'directory') {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
    } else {
        New-Item -ItemType SymbolicLink -Path $Path -Target $Target | Out-Null
    }
}

function Ensure-BackupManifest {
    param([Parameter(Mandatory = $true)]$Paths)

    $manifest = [pscustomobject]@{
        generatedAt = (Get-Date).ToString('o')
        repoRoot = $Paths.RepoRoot
        stateRoot = $Paths.StateRoot
        configPath = $Paths.ConfigPath
        runtimeCommandRoot = $Paths.RuntimeCommandRoot
        trayManagerExe = $Paths.TrayManagerExe
        trayLauncherVbs = $Paths.TrayLauncherVbs
        wrapperRoots = [pscustomobject]@{
            canonical = $Paths.NpmGlobalRoot
            user = (Get-OpenClawCanonicalDefaults).WrapperRoots.user
            roaming = (Get-OpenClawCanonicalDefaults).WrapperRoots.roaming
        }
        aliases = (Get-OpenClawCanonicalDefaults).Aliases
        tasks = (Get-OpenClawCanonicalDefaults).Tasks
    }
    Save-OpenClawJsonFile -Object $manifest -Path $Paths.BackupManifestPath
    Register-OpenClawManagedFile -Path $Paths.BackupManifestPath -Kind 'backup-manifest' -Source 'Seal-OpenClawAuthority.ps1'
}

$authority = Ensure-OpenClawAuthorityFiles -Force
$paths = Set-OpenClawProcessEnvironment -PersistUser:$PersistUser

$config = Get-Content -Raw -LiteralPath $paths.ConfigPath | ConvertFrom-Json
$null = Save-OpenClawConfigFile -Config $config -LastWriter 'Seal-OpenClawAuthority'

foreach ($alias in (Get-OpenClawCanonicalDefaults).Aliases) {
    Ensure-SymbolicAlias -Path $alias.path -Target $alias.target -Type $alias.type
}

& 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Ensure-OpenClawCommandSurface.ps1' -PersistUser:$PersistUser | Out-Null

$gatewayContent = Get-OpenClawExpectedGatewayContent -Paths $paths
Write-OpenClawManagedTextFile -Path (Join-Path $paths.StateRoot 'gateway.cmd') -Content $gatewayContent -Kind 'gateway-launcher' -Source 'Seal-OpenClawAuthority.ps1' -CommentPrefix 'rem'

& 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ProfileFunctions\Register-ClawdBotStartup.ps1' | Out-Null
try {
    schtasks.exe /Change /TN 'OpenClaw Gateway' /DISABLE > $null 2>&1
} catch {
}

if (-not $SkipTelegramRefresh) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\telegram-global\Sync-OpenClawCommandCatalog.ps1') -Quiet | Out-Null
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\telegram-global\Repair-OpenClawTelegramRoutes.ps1') -Quiet | Out-Null
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\telegram-global\Sync-OpenClawWorkspaceSkills.ps1') -Quiet | Out-Null
}

Ensure-BackupManifest -Paths $paths
Write-OpenClawAuditLog -Action 'seal' -Detail ("persistUser={0} generation={1}" -f [bool]$PersistUser, $paths.AuthorityGenerationId)

$result = powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
if ($Json) {
    $result | ConvertTo-Json -Depth 8
} else {
    $result
}
