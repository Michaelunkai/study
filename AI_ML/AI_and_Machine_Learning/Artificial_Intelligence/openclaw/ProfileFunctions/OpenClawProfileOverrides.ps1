. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$script:OpenClawResolvedPaths = Set-OpenClawProcessEnvironment
& 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Ensure-OpenClawCommandSurface.ps1' | Out-Null

try {
    $authorityCheck = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json
    if (-not $authorityCheck.passed) {
        Write-Warning ("OpenClaw authority drift detected. Run {0} before using OpenClaw helpers." -f (Join-Path $script:OpenClawResolvedPaths.RepoRoot 'scripts\Seal-OpenClawAuthority.ps1'))
    }
} catch {
    Write-Warning "OpenClaw authority self-check failed: $($_.Exception.Message)"
}

function gclaw {
    & 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ProfileFunctions\gclaw.ps1' @args
}

function clawd {
    & 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ProfileFunctions\clawd.ps1' @args
}

function regate {
    $restartScript = 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ProfileFunctions\Restart-OpenclawGateway.ps1'
    if (-not (Test-Path -LiteralPath $restartScript)) {
        Write-Error "Restart script not found: $restartScript"
        return
    }

    $ok = & $restartScript -TimeoutSec 210 -Force
    if (-not $ok) {
        Write-Error 'ClawdBot gateway failed to restart cleanly'
    }
}

function cdclaw {
    Set-Location $script:OpenClawResolvedPaths.RepoRoot
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
        if (Test-Path $sf) { Set-Content $sf '[]' -NoNewline; Write-Host "  Cleared sessions for $_" -ForegroundColor DarkGray }
    }

    Write-Host '? Discord DISABLED (tokens invalidated + sessions cleared)' -ForegroundColor Green
    Restart-OpenclawGateway
    Write-Host '? Discord is now OFF' -ForegroundColor Green
}

function endis {
    $configPath = $script:OpenClawResolvedPaths.ConfigPath
    $backupPath = $script:OpenClawResolvedPaths.DiscordTokenBackupPath

    if (!(Test-Path $backupPath)) { Write-Host "No token backup found at $backupPath" -ForegroundColor Red; return }

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
