param(
    [string]$ConfigPath,
    [string]$MenuPriorityPath,
    [string]$AgentsRoot
)

$ErrorActionPreference = "Stop"
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
if (-not $ConfigPath) { $ConfigPath = $paths.ConfigPath }
if (-not $MenuPriorityPath) { $MenuPriorityPath = $paths.MenuPriorityPath }
if (-not $AgentsRoot) { $AgentsRoot = $paths.AgentsRoot }
$catalogSyncScript = Join-Path $paths.RepoRoot 'scripts\telegram-global\Sync-OpenClawCommandCatalog.ps1'
$workspaceSkillSyncScript = Join-Path $paths.RepoRoot 'scripts\telegram-global\Sync-OpenClawWorkspaceSkills.ps1'

if (Test-Path $catalogSyncScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $catalogSyncScript -ConfigPath $ConfigPath -MenuPriorityPath $MenuPriorityPath -Quiet | Out-Null
} elseif (Test-Path $workspaceSkillSyncScript) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $workspaceSkillSyncScript -ConfigPath $ConfigPath -Quiet | Out-Null
}

function Get-StaticTelegramScopes {
    return @(
        @{ name = "default"; body = @{} },
        @{ name = "all_private_chats"; body = @{ scope = @{ type = "all_private_chats" } } },
        @{ name = "all_group_chats"; body = @{ scope = @{ type = "all_group_chats" } } },
        @{ name = "all_chat_administrators"; body = @{ scope = @{ type = "all_chat_administrators" } } }
    )
}

function Get-TelegramChatIdFromText {
    param(
        [AllowNull()][string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $match = [regex]::Match([string]$Value, 'telegram:(-?\d+)')
    if (-not $match.Success) {
        return $null
    }

    return [int64]$match.Groups[1].Value
}

function Get-TelegramDirectChatsByAccount {
    param(
        [Parameter(Mandatory = $true)][string]$AgentsRootPath
    )

    $chatIdsByAccount = @{}
    if (-not (Test-Path $AgentsRootPath)) {
        return $chatIdsByAccount
    }

    foreach ($sessionsPath in Get-ChildItem -Path $AgentsRootPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Join-Path $_.FullName "sessions\sessions.json"
    }) {
        if (-not (Test-Path $sessionsPath)) {
            continue
        }

        try {
            $sessions = Get-Content -Raw $sessionsPath | ConvertFrom-Json
        } catch {
            continue
        }

        foreach ($entryProperty in $sessions.PSObject.Properties) {
            $entry = $entryProperty.Value
            if (-not $entry) {
                continue
            }

            if ($entry.PSObject.Properties.Name -notcontains 'origin' -or -not $entry.origin) {
                continue
            }

            $origin = $entry.origin
            if (-not $origin -or $origin.PSObject.Properties.Name -notcontains 'provider') {
                continue
            }

            $provider = [string]$origin.provider
            $chatType = if ($origin.PSObject.Properties.Name -contains "chatType") {
                [string]$origin.chatType
            } else {
                [string]$entry.chatType
            }
            $accountId = [string]$origin.accountId

            if ($provider -ne "telegram" -or $chatType -ne "direct" -or [string]::IsNullOrWhiteSpace($accountId)) {
                continue
            }

            $chatId = Get-TelegramChatIdFromText -Value ([string]$origin.from)
            if ($null -eq $chatId) {
                $chatId = Get-TelegramChatIdFromText -Value ([string]$origin.to)
            }
            if ($null -eq $chatId) {
                continue
            }

            if (-not $chatIdsByAccount.ContainsKey($accountId)) {
                $chatIdsByAccount[$accountId] = New-Object System.Collections.Generic.HashSet[string]
            }

            [void]$chatIdsByAccount[$accountId].Add([string]$chatId)
        }
    }

    return $chatIdsByAccount
}

function Get-TelegramScopes {
    param(
        [Parameter(Mandatory = $true)][string]$AccountId,
        [Parameter(Mandatory = $true)]$DirectChatsByAccount
    )

    $scopes = @()
    $scopes += @(Get-StaticTelegramScopes)

    if ($DirectChatsByAccount.ContainsKey($AccountId)) {
        foreach ($chatId in @($DirectChatsByAccount[$AccountId] | Sort-Object {[int64]$_})) {
            $scopes += @{
                name = "chat:$chatId"
                body = @{ scope = @{ type = "chat"; chat_id = [int64]$chatId } }
            }
        }
    }

    return @($scopes)
}

function Get-TelegramMenuPriority {
    $defaultPriority = @(
        "all",
        "nnew",
        "slash",
        "mem",
        "done",
        "vault_save",
        "vault_search",
        "obs",
        "jobs",
        "job",
        "until_done",
        "sub",
        "todos",
        "todos_sub",
        "yt"
    )
    $configuredPriority = @($script:TelegramMenuPriorityCommands)
    return @(
        $configuredPriority + $defaultPriority |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { ([string]$_).Trim().ToLowerInvariant() } |
            Select-Object -Unique
    )
}

function Get-TelegramMenuPriorityCommands {
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

function Get-TelegramMenuDescriptionOverrides {
    return @{
        acceptance_criteria_verification = "Verify acceptance"
        adversarial_review               = "Challenge local diff"
        advisor                          = "Advisor mode"
        ahk                              = "AutoHotkey edit"
        all                              = "Send to all bots"
        api_design                       = "Design REST APIs"
        autonomous_operation             = "Autonomous mode"
        autonomous_orchestration         = "Auto multi-agent"
        backclau                         = "Backup workspace"
        backend_patterns                 = "Node backend patterns"
        backgame                         = "Backup game save"
        backres                          = "Backup or restore C"
        claw                             = "OpenClaw rulebook"
        clp                              = "Copy last output"
        clu                              = "Codex usage"
        coding_agent                     = "Delegate coding"
        coding_standards                 = "Apply code standards"
        computer_use_mcp                 = "Browser automation"
        conit                            = "Storage cleanup"
        cpu_toggle                       = "Toggle CPU mode"
        done                             = "Log work summary"
        done_job                         = "Log job summary"
        dream                            = "Clean memory files"
        e2e_testing                      = "Playwright E2E"
        end                              = "End session ritual"
        eval_harness                     = "Eval-driven dev"
        excel                            = "Spreadsheet work"
        frontend_patterns                = "React UI patterns"
        frontend_slides                  = "HTML slides"
        game                             = "Game history"
        gemini                           = "Gemini CLI"
        gh_issues                        = "GitHub issue batch"
        github                           = "GitHub ops"
        healthcheck                      = "Host hardening"
        hook                             = "Save to memory"
        imagegen                         = "Generate images"
        imp                              = "Improve Claude Code"
        job                              = "Apply to jobs"
        jobs                             = "Triage one issue"
        later                            = "Handoff prompt"
        mem                              = "Save to vault"
        mission_merge                    = "Merge missions"
        mission_split                    = "Split mission"
        mission_to_todo                  = "Mission into todo"
        net                              = "Enable browser tool"
        nextjs_turbopack                 = "Next.js Turbopack"
        nnew                             = "Fresh all bots"
        no_deferred_work                 = "Finish now, no TODOs"
        node_connect                     = "Node pairing help"
        obs                              = "Save full session"
        ola                              = "Ollama project memory"
        openai_docs                      = "Official OpenAI docs"
        openai_whisper                   = "Local speech to text"
        playwright_cli                   = "Playwright automation"
        plugin_creator                   = "Create plugin"
        powerpoint                       = "PowerPoint work"
        prompt_architect                 = "Engineer a prompt"
        ps                               = "PowerShell profile"
        redone                           = "Reopen RLP todos"
        rerlp                            = "Rehaul RLP UI"
        rescue                           = "Delegated rescue task"
        research_after_failure           = "Research after fail"
        resgame                          = "Restore game save"
        review                           = "Review local changes"
        rlp                              = "Ralph loop plus"
        rlp_clear                        = "Clear RLP state"
        rmdone                           = "Done then clear RLP"
        router                           = "OpenRouter mode"
        security_review                  = "Security audit"
        session_logs                     = "Search session logs"
        skill_creator                    = "Create skill"
        skill_installer                  = "Install skill"
        slash                            = "Manage slash cmds"
        smart_git_commit                 = "AI git commit"
        snap                             = "Take snapshot"
        start                            = "Session startup"
        strategic_compact                = "Manual compact plan"
        sub                              = "Spawn sub-agents"
        sysopt                           = "Improve this system"
        taskflow                         = "TaskFlow mission"
        taskflow_inbox_triage            = "Inbox TaskFlow"
        tdd_workflow                     = "Test-driven coding"
        time                             = "Timed task"
        todo_to_mission                  = "Todo into mission"
        todoist                          = "Todoist append"
        todos                            = "Make todos"
        todos_sub                        = "Todos with subagents"
        until_done                       = "Work till verified"
        vault_save                       = "Save to vault"
        vault_search                     = "Search vault"
        verification_loop                = "Run verification"
        vid                              = "Add research videos"
        video_frames                     = "Extract video frames"
        weather                          = "Weather forecast"
        web_scraping                     = "Scrape web data"
        windows_ui_automation            = "Windows UI automate"
        work                             = "Pick and do work"
        yt                               = "Add YouTube videos"
    }
}

function Get-TelegramFallbackDescription {
    param(
        [Parameter(Mandatory = $true)][string]$Command
    )

    return (([string]$Command).Trim().ToLowerInvariant() -replace '_', ' ').Trim()
}

function ConvertTo-TelegramSafeDescription {
    param(
        [AllowNull()][string]$Description,
        [AllowNull()][string]$FallbackCommand
    )

    $normalized = ([string]$Description).Normalize([Text.NormalizationForm]::FormKD)
    $builder = New-Object System.Text.StringBuilder
    foreach ($ch in $normalized.ToCharArray()) {
        $code = [int][char]$ch
        if ($code -eq 8212 -or $code -eq 8211) {
            [void]$builder.Append('-')
            continue
        }
        if ($code -eq 8217 -or $code -eq 8216) {
            [void]$builder.Append("'")
            continue
        }
        if ($code -eq 8220 -or $code -eq 8221) {
            [void]$builder.Append('"')
            continue
        }
        if ($code -eq 8230) {
            [void]$builder.Append('...')
            continue
        }
        if (($code -ge 32 -and $code -le 126) -or [char]::IsWhiteSpace($ch)) {
            [void]$builder.Append($ch)
        }
    }
    $value = $builder.ToString()
    $value = $value -replace '\s+', ' '
    $value = $value.Trim()
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = [string]$FallbackCommand
    }
    if ([string]::IsNullOrWhiteSpace($value)) {
        $value = "OpenClaw command"
    }
    if (
        $value.Length -gt 24 -and
        -not [string]::IsNullOrWhiteSpace($FallbackCommand) -and
        ([string]$FallbackCommand).Length -le 24
    ) {
        $value = [string]$FallbackCommand
    }
    if ($value.Length -gt 24) {
        $value = $value.Substring(0, 24).TrimEnd()
    }
    return $value
}

function Resolve-TelegramMenuDescription {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [AllowNull()][string]$Description,
        [Parameter(Mandatory = $true)]$CommandConfig
    )

    $fallbackDescription = Get-TelegramFallbackDescription -Command $Command
    $explicitTelegramDescription = $null
    if ($CommandConfig.PSObject.Properties.Name -contains "telegramDescription") {
        $explicitTelegramDescription = [string]$CommandConfig.telegramDescription
    }

    if (-not [string]::IsNullOrWhiteSpace($explicitTelegramDescription)) {
        return ConvertTo-TelegramSafeDescription -Description $explicitTelegramDescription -FallbackCommand $fallbackDescription
    }

    if ($script:TelegramMenuDescriptionOverrides.ContainsKey($Command)) {
        return ConvertTo-TelegramSafeDescription -Description ([string]$script:TelegramMenuDescriptionOverrides[$Command]) -FallbackCommand $fallbackDescription
    }

    return ConvertTo-TelegramSafeDescription -Description $Description -FallbackCommand $fallbackDescription
}

function Invoke-TelegramJsonApi {
    param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][hashtable]$Body
    )

    $uri = "https://api.telegram.org/bot$Token/$Method"
    $jsonBody = $Body | ConvertTo-Json -Depth 20 -Compress
    return Invoke-RestMethod -Method Post -Uri $uri -ContentType "application/json" -Body $jsonBody
}

function Get-TelegramCommandsFromApi {
    param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][hashtable]$ScopeBody
    )

    $response = Invoke-TelegramJsonApi -Token $Token -Method "getMyCommands" -Body $ScopeBody
    return @($response.result)
}

function Get-PrioritizedCommandList {
    param(
        [Parameter(Mandatory = $true)][array]$Commands
    )

    $priorityOrder = Get-TelegramMenuPriority
    $priorityIndex = @{}
    for ($i = 0; $i -lt $priorityOrder.Count; $i++) {
        $priorityIndex[$priorityOrder[$i]] = $i
    }

    return @(
        $Commands |
            Sort-Object `
                @{ Expression = { if ($priorityIndex.ContainsKey($_.command)) { 0 } else { 1 } } }, `
                @{ Expression = { if ($priorityIndex.ContainsKey($_.command)) { $priorityIndex[$_.command] } else { [int]::MaxValue } } }, `
                @{ Expression = { $_.command } }
    )
}

function Set-TelegramCommandsWithFallback {
    param(
        [Parameter(Mandatory = $true)][string]$Token,
        [Parameter(Mandatory = $true)][hashtable]$ScopeBody,
        [Parameter(Mandatory = $true)][array]$Commands
    )

    $ordered = Get-PrioritizedCommandList -Commands $Commands
    $maxTelegramCommands = 100
    $startCount = [Math]::Min($ordered.Count, $maxTelegramCommands)
    $best = $null

    for ($count = $startCount; $count -ge 1; $count--) {
        $candidate = @($ordered | Select-Object -First $count)
        $setBody = @{ commands = $candidate }
        foreach ($key in $ScopeBody.Keys) {
            $setBody[$key] = $ScopeBody[$key]
        }

        try {
            $response = Invoke-TelegramJsonApi -Token $Token -Method "setMyCommands" -Body $setBody
            if (-not $response.ok) {
                throw "Telegram rejected command set."
            }
            $verified = @(Get-TelegramCommandsFromApi -Token $Token -ScopeBody $ScopeBody)
            if ($verified.Count -ne $candidate.Count) {
                throw "Telegram did not persist the full command subset."
            }
            $verifiedNames = @($verified | ForEach-Object { [string]$_.command })
            $candidateNames = @($candidate | ForEach-Object { [string]$_.command })
            $difference = @(Compare-Object -ReferenceObject $candidateNames -DifferenceObject $verifiedNames)
            if ($difference.Count -ne 0) {
                throw "Telegram persisted a different command subset than requested."
            }
            $best = [pscustomobject]@{
                response = $response
                commands = $candidate
            }
            break
        } catch {
            $errorDetailsMessage = $null
            if ($_.ErrorDetails) {
                $errorDetailsMessage = $_.ErrorDetails.Message
            }
            $errorText = @(
                $_.Exception.Message,
                $errorDetailsMessage
            ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Out-String
            if (
                $errorText -notmatch "BOT_COMMANDS_TOO_MUCH" -and
                $errorText -notmatch "did not persist the full command subset" -and
                $errorText -notmatch "persisted a different command subset"
            ) {
                throw
            }
        }
    }

    if ($null -eq $best) {
        throw "Telegram rejected even the smallest command subset."
    }

    return $best
}

$cfg = Get-Content -Raw $ConfigPath | ConvertFrom-Json
$telegram = $cfg.channels.telegram
if (-not $telegram) {
    throw "channels.telegram is missing in $ConfigPath"
}
$script:TelegramMenuPriorityCommands = @(Get-TelegramMenuPriorityCommands -TelegramConfig $telegram -PriorityPath $MenuPriorityPath)
$script:TelegramMenuDescriptionOverrides = Get-TelegramMenuDescriptionOverrides
$directChatsByAccount = Get-TelegramDirectChatsByAccount -AgentsRootPath $AgentsRoot

$commands = @()
foreach ($command in @($telegram.customCommands)) {
    if (-not $command.command) { continue }
    $normalizedCommand = ([string]$command.command).Trim().ToLowerInvariant()
    if ($normalizedCommand -notmatch '^[a-z0-9_]{1,32}$') { continue }
    $commands += @{
        command = $normalizedCommand
        description = Resolve-TelegramMenuDescription -Command $normalizedCommand -Description ([string]$command.description) -CommandConfig $command
    }
}

$results = @()
foreach ($accountProperty in $telegram.accounts.PSObject.Properties) {
    $accountId = $accountProperty.Name
    $account = $accountProperty.Value
    if (-not $account.enabled) { continue }
    if (-not $account.botToken) { continue }

    foreach ($scope in @(Get-TelegramScopes -AccountId $accountId -DirectChatsByAccount $directChatsByAccount)) {
        $deleteOk = $true
        try {
            Invoke-TelegramJsonApi -Token $account.botToken -Method "deleteMyCommands" -Body $scope.body | Out-Null
        } catch {
            $deleteOk = $false
        }

        $publish = Set-TelegramCommandsWithFallback -Token $account.botToken -ScopeBody $scope.body -Commands $commands
        $response = $publish.response
        $results += [pscustomobject]@{
            accountId = $accountId
            scope = $scope.name
            commandCount = $commands.Count
            publishedCommandCount = @($publish.commands).Count
            publishedCommands = @($publish.commands | ForEach-Object { $_.command })
            deleteOk = $deleteOk
            ok = [bool]$response.ok
        }
    }
}

$results | ConvertTo-Json -Depth 5
