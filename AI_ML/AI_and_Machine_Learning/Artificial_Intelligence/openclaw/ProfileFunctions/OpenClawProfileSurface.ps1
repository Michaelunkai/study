. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$script:OpenClawResolvedPaths = Set-OpenClawProcessEnvironment -PersistUser
& 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Ensure-OpenClawCommandSurface.ps1' -PersistUser | Out-Null

try {
    schtasks.exe /Change /TN 'OpenClaw Gateway' /DISABLE > $null 2>&1
} catch {
}

function Get-OpenClawProfileAuthorityStatus {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
}

function Repair-OpenClawAuthority {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'scripts\Seal-OpenClawAuthority.ps1') -PersistUser -SkipTelegramRefresh @args
}

function Invoke-OpenClawProfileScript {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$ForwardArgs
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "OpenClaw profile script not found: $Path"
    }

    if ($null -eq $ForwardArgs -or $ForwardArgs.Count -eq 0) {
        & $Path
        return
    }

    & $Path @ForwardArgs
}

function Invoke-OpenClawRepoScript {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$ForwardArgs
    )

    $path = Join-Path $script:OpenClawResolvedPaths.RepoRoot ("ProfileFunctions\{0}.ps1" -f $Name)
    Invoke-OpenClawProfileScript -Path $path @ForwardArgs
}

function Test-OpenClawStartupMode {
    param([object[]]$ForwardArgs)

    if (-not $ForwardArgs -or $ForwardArgs.Count -eq 0) {
        return $true
    }

    $argsList = @($ForwardArgs | ForEach-Object { [string]$_ })
    if ($argsList -contains '-SelfTest') {
        return $false
    }
    if ($argsList -contains '-DryRun') {
        return $false
    }

    for ($i = 0; $i -lt $argsList.Count; $i++) {
        if ($argsList[$i] -eq '-Mode' -and ($i + 1) -lt $argsList.Count) {
            return ($argsList[$i + 1] -eq 'Startup')
        }
    }

    return ($argsList[0] -eq 'Startup')
}

function Invoke-OpenClawAllstartFinalize {
    $ok = & (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'ProfileFunctions\Restart-OpenclawGateway.ps1') -TimeoutSec 150 -Quiet
    if (-not $ok) {
        Write-Warning 'OpenClaw tray-managed runtime did not reach healthy state during allstart.'
    }
}

function ccvbs {
    $script:OpenClawResolvedPaths.TrayLauncherVbs | Set-Clipboard
    Write-Host ("Copied to clipboard: {0}" -f $script:OpenClawResolvedPaths.TrayLauncherVbs) -ForegroundColor Green
}

function Register-ClawdBotStartup {
    Invoke-OpenClawRepoScript -Name 'Register-ClawdBotStartup' @args
}

function oc-fast {
    param([switch]$Silent)
    & 'F:\study\Shells\powershell\scripts\misc\openclaw\faststart\fast-start.ps1' @PSBoundParameters
}

function openclaw-start {
    Invoke-OpenClawRepoScript -Name 'openclaw-start' @args
}

function openclaw-stop {
    Invoke-OpenClawRepoScript -Name 'openclaw-stop' @args
}

function openclaw-restart {
    Invoke-OpenClawRepoScript -Name 'Restart-OpenclawGateway' @args
}

function openclaw-status {
    & $script:OpenClawResolvedPaths.NodeExePath $script:OpenClawResolvedPaths.RuntimeEntrypoint gateway status @args
}

function ccclaw {
    Invoke-OpenClawRepoScript -Name 'ccclaw' @args
}

function cldown {
    Invoke-OpenClawRepoScript -Name 'cldown' @args
}

function clawkey {
    Invoke-OpenClawRepoScript -Name 'clawkey' @args
}

function clawgate {
    Invoke-OpenClawRepoScript -Name 'clawgate' @args
}

function clawlog {
    Invoke-OpenClawRepoScript -Name 'clawlog' @args
}

function Restart-OpenclawGateway {
    Invoke-OpenClawRepoScript -Name 'Restart-OpenclawGateway' @args
}

function regate {
    [CmdletBinding()]
    param(
        [int]$TimeoutSec = 210,
        [switch]$CheckOnly
    )

    if ($CheckOnly) {
        $ok = & (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'ProfileFunctions\Restart-OpenclawGateway.ps1') -TimeoutSec $TimeoutSec -CheckOnly
    } else {
        $ok = & (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'ProfileFunctions\Restart-OpenclawGateway.ps1') -TimeoutSec $TimeoutSec -Force
    }

    if (-not $ok) {
        throw 'ClawdBot gateway failed to restart cleanly'
    }

    return $true
}

function allstart {
    $script = 'F:\study\Learning\01\01\Shells\powershell\profile-functions\windows\startup\session-bootstrap\AllStartBootstrap\Invoke-allstart.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        throw "allstart script not found: $script"
    }

    $forwardArgs = @($args)
    Invoke-OpenClawProfileScript -Path $script @forwardArgs
    if (Test-OpenClawStartupMode -ForwardArgs $forwardArgs) {
        Invoke-OpenClawAllstartFinalize
    }
}

function allstart2 {
    $script = 'F:\study\Learning\01\01\Shells\powershell\profile-functions\windows\startup\session-bootstrap\AllStartTwoBootstrap\Invoke-allstart2.ps1'
    if (-not (Test-Path -LiteralPath $script)) {
        throw "allstart2 script not found: $script"
    }

    Invoke-OpenClawProfileScript -Path $script @args
}

function gclaw {
    Invoke-OpenClawRepoScript -Name 'gclaw' @args
}

function clawd {
    Invoke-OpenClawRepoScript -Name 'clawd' @args
}

function cdclaw {
    Set-Location $script:OpenClawResolvedPaths.RepoRoot
}

function clawskills {
    & (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'skills\Top150SkillsNotYetInstalled\clawskills.ps1') @args
}

function clawhooks {
    & (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'scripts\clawhooks\clawhooks.ps1') @args
}

function ccbots {
    py 'F:\backup\windowsapps\Credentials\telegram\openclaw\scripts\clear_bot_history.py'
}

function resclaw {
    & (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'setup\Restore-OpenClaw-ThisMachine.bat')
}

function disdis {
    $configPath = $script:OpenClawResolvedPaths.ConfigPath
    $backupPath = $script:OpenClawResolvedPaths.DiscordTokenBackupPath
    $agentsBase = $script:OpenClawResolvedPaths.AgentsRoot

    $json = Get-Content $configPath -Raw | ConvertFrom-Json
    $json.channels.discord.enabled = $false
    if ($json.plugins.entries.discord.PSObject.Properties['enabled']) { $json.plugins.entries.discord.enabled = $false }
    if ($json.plugins.entries.discord.config.PSObject.Properties['enabled']) { $json.plugins.entries.discord.config.enabled = $false }
    if ($json.channels.discord.accounts.main.PSObject.Properties['enabled']) { $json.channels.discord.accounts.main.enabled = $false }

    $discordToken = $json.channels.discord.accounts.main.token
    if (![string]::IsNullOrWhiteSpace($discordToken)) {
        @{ token = $discordToken } | ConvertTo-Json -Depth 5 | Set-Content $backupPath -NoNewline
        $json.channels.discord.accounts.main.token = ""
    }

    $json | ConvertTo-Json -Depth 20 | Set-Content $configPath -NoNewline

    @('discord-main','discord-session2','discord-openclaw','discord-openclaw4') | ForEach-Object {
        $sf = Join-Path $agentsBase "$_\sessions\sessions.json"
        if (Test-Path $sf) {
            Set-Content $sf '[]' -NoNewline
            Write-Host "  Cleared sessions for $_" -ForegroundColor DarkGray
        }
    }

    Write-Host '? Discord DISABLED (tokens invalidated + sessions cleared)' -ForegroundColor Green
    Restart-OpenclawGateway
    Write-Host '? Discord is now OFF' -ForegroundColor Green
}

function endis {
    $configPath = $script:OpenClawResolvedPaths.ConfigPath
    $backupPath = $script:OpenClawResolvedPaths.DiscordTokenBackupPath

    if (!(Test-Path $backupPath)) {
        Write-Host "No token backup found at $backupPath" -ForegroundColor Red
        return
    }

    $json = Get-Content $configPath -Raw | ConvertFrom-Json
    $backup = Get-Content $backupPath -Raw | ConvertFrom-Json

    $json.channels.discord.enabled = $true
    if ($json.plugins.entries.discord.PSObject.Properties['enabled']) { $json.plugins.entries.discord.enabled = $true }
    if ($json.plugins.entries.discord.config.PSObject.Properties['enabled']) { $json.plugins.entries.discord.config.enabled = $true }
    if ($json.channels.discord.accounts.main.PSObject.Properties['enabled']) { $json.channels.discord.accounts.main.enabled = $true }
    if ($backup.token) { $json.channels.discord.accounts.main.token = $backup.token }

    $json | ConvertTo-Json -Depth 20 | Set-Content $configPath -NoNewline
    Write-Host '? Discord ENABLED (tokens restored)' -ForegroundColor Green
    Restart-OpenclawGateway
    Write-Host '? Discord is now ON' -ForegroundColor Green
}

function backgame {
    $scriptPath = Join-Path $script:OpenClawResolvedPaths.Workspaces.openclaw 'scripts\backgame.ps1'
    if (Test-Path $scriptPath) {
        & $scriptPath @args
    } else {
        Write-Warning "backgame: script not found: $scriptPath"
    }
}

function resgame {
    $scriptPath = Join-Path $script:OpenClawResolvedPaths.Workspaces.openclaw 'scripts\resgame.ps1'
    if (Test-Path $scriptPath) {
        & $scriptPath @args
    } else {
        Write-Warning "resgame: script not found: $scriptPath"
    }
}
