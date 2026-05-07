param(
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'

function Add-TelegramCheck {
    param(
        [System.Collections.Generic.List[object]]$Checks,
        [string]$Name,
        [bool]$Passed,
        [string]$Detail
    )

    [void]$Checks.Add([pscustomobject]@{
        name = $Name
        passed = $Passed
        detail = $Detail
    })
}

$paths = Get-OpenClawPaths
$authority = Get-OpenClawAuthority
$cfg = Get-Content -Raw -LiteralPath $paths.ConfigPath | ConvertFrom-Json
$checks = [System.Collections.Generic.List[object]]::new()

$accounts = @($cfg.channels.telegram.accounts.PSObject.Properties | ForEach-Object { $_.Name })
Add-TelegramCheck $checks 'telegram-account-count' ($accounts.Count -eq 4) ("accounts={0}" -f ($accounts -join ','))

$bindings = @($authority.telegram.bindings)
$bindingAccountIds = @($bindings | ForEach-Object { $_.accountId } | Sort-Object -Unique)
Add-TelegramCheck $checks 'telegram-binding-count' ($bindings.Count -eq 4) ("bindings={0}" -f ($bindingAccountIds -join ','))

$bindingMismatches = @()
foreach ($binding in $bindings) {
    $agent = @($cfg.agents.list | Where-Object { $_.id -eq $binding.agentId })[0]
    if (-not $agent -or [string]$agent.workspace -ne [string]$binding.workspace -or [string]$agent.heartbeat.accountId -ne [string]$binding.accountId) {
        $bindingMismatches += $binding.agentId
    }
}
Add-TelegramCheck $checks 'telegram-binding-alignment' ($bindingMismatches.Count -eq 0) ("mismatches={0}" -f ($bindingMismatches -join ','))

$catalog = Get-Content -Raw -LiteralPath $paths.CommandCatalogPath | ConvertFrom-Json
Add-TelegramCheck $checks 'command-catalog-readable' (($catalog.PSObject.Properties.Name -contains 'generatedAt') -and @($catalog.entries).Count -gt 0) ("entries={0}" -f @($catalog.entries).Count)

$routes = Get-Content -Raw -LiteralPath $paths.RouteRegistryPath | ConvertFrom-Json
$telegramRoutes = @($routes.routes | Where-Object {
    $_.PSObject.Properties.Name -contains 'channel' -and
    $_.PSObject.Properties.Name -contains 'accountId' -and
    [string]$_.channel -eq 'telegram' -and
    -not [string]::IsNullOrWhiteSpace([string]$_.accountId)
})
$routeAccountIds = @($telegramRoutes | ForEach-Object { [string]$_.accountId } | Sort-Object -Unique)
Add-TelegramCheck $checks 'route-registry-account-coverage' (@($bindingAccountIds | Where-Object { $_ -in $routeAccountIds }).Count -eq $bindingAccountIds.Count) ("accounts={0}" -f ($routeAccountIds -join ','))

$customCommands = @($cfg.channels.telegram.customCommands)
$customCommandNames = @($customCommands | ForEach-Object { [string]$_.command })
Add-TelegramCheck $checks 'telegram-command-catalog-nonempty' ($customCommands.Count -gt 0) ("count={0}; typed dispatch supports commands beyond Telegram visible menu limit" -f $customCommands.Count)
Add-TelegramCheck $checks 'telegram-native-new-not-shadowed' ('new' -notin $customCommandNames) ("hasNew={0}" -f ([bool]('new' -in $customCommandNames)))

$allowCrossContextSend = [bool]$cfg.tools.message.allowCrossContextSend
$allowWithinProvider = [bool]$cfg.tools.message.crossContext.allowWithinProvider
$allowAcrossProviders = [bool]$cfg.tools.message.crossContext.allowAcrossProviders
Add-TelegramCheck $checks 'telegram-cross-context-policy-present' ($allowCrossContextSend -and $allowWithinProvider -and $allowAcrossProviders) ("allowCross={0};within={1};across={2}" -f $allowCrossContextSend, $allowWithinProvider, $allowAcrossProviders)

$menuPriorityCommands = @()
if (Test-Path -LiteralPath $paths.MenuPriorityPath) {
    try {
        $menuPriorityState = Get-Content -Raw -LiteralPath $paths.MenuPriorityPath | ConvertFrom-Json
        if ($menuPriorityState -and $menuPriorityState.commands) {
            $menuPriorityCommands = @($menuPriorityState.commands | ForEach-Object { [string]$_ })
        }
    } catch {
        $menuPriorityCommands = @()
    }
}
Add-TelegramCheck $checks 'telegram-menu-priority-clean' ('new' -notin $menuPriorityCommands) ("hasNew={0}" -f ([bool]('new' -in $menuPriorityCommands)))

$requiredCommands = @('nnew','all','claw','slash','start','snap','clu','job','news')
$catalogCommands = @($catalog.entries | ForEach-Object { [string]$_.command })
$missingRequired = @($requiredCommands | Where-Object { $_ -notin $catalogCommands })
Add-TelegramCheck $checks 'required-commands-present' ($missingRequired.Count -eq 0) ("missing={0}" -f ($missingRequired -join ','))

$missingCatalogSources = @(
    $catalog.entries |
        Where-Object { [string]$_.command -in $requiredCommands } |
        Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.sourcePath) -and -not (Test-Path -LiteralPath ([string]$_.sourcePath)) } |
        ForEach-Object { [string]$_.command }
)
Add-TelegramCheck $checks 'required-command-catalog-source-paths-exist' ($missingCatalogSources.Count -eq 0) ("missing={0}" -f ($missingCatalogSources -join ','))

$runtimeSkillsRoot = Join-Path $paths.RuntimeRoot 'skills'
$missingRuntimeCompatibility = @()
foreach ($entry in @($catalog.entries)) {
    $command = [string]$entry.command
    if ($command -notin $requiredCommands) {
        continue
    }
    if ([string]::IsNullOrWhiteSpace($command)) {
        continue
    }

    $runtimeSkillPath = Join-Path (Join-Path $runtimeSkillsRoot $command) 'SKILL.md'
    if (-not (Test-Path -LiteralPath $runtimeSkillPath)) {
        $missingRuntimeCompatibility += $command
    }
}
Add-TelegramCheck $checks 'required-runtime-skill-compatibility-paths-present' ($missingRuntimeCompatibility.Count -eq 0) ("missing={0}" -f ($missingRuntimeCompatibility -join ','))

$workspaceMirrorFailures = @()
foreach ($binding in $bindings) {
    $skillsRoot = Join-Path $binding.workspace 'skills'
    if (-not (Test-Path -LiteralPath $skillsRoot)) {
        $workspaceMirrorFailures += "$($binding.agentId):missing-skills-root"
        continue
    }
}
Add-TelegramCheck $checks 'workspace-skill-roots-present' ($workspaceMirrorFailures.Count -eq 0) ("failures={0}" -f ($workspaceMirrorFailures -join ','))

$sessionStoreFailures = @()
foreach ($binding in $bindings) {
    $sessionPath = Join-Path $paths.AgentsRoot "$($binding.agentId)\sessions\sessions.json"
    if (-not (Test-Path -LiteralPath $sessionPath)) {
        $sessionStoreFailures += "$($binding.agentId):missing-session-store"
    }
}
Add-TelegramCheck $checks 'telegram-session-stores-present' ($sessionStoreFailures.Count -eq 0) ("failures={0}" -f ($sessionStoreFailures -join ','))

$imageModelPrimary = $null
if ($cfg.agents -and $cfg.agents.PSObject.Properties.Name -contains 'defaults' -and
    $cfg.agents.defaults -and $cfg.agents.defaults.PSObject.Properties.Name -contains 'imageModel' -and
    $cfg.agents.defaults.imageModel -and $cfg.agents.defaults.imageModel.PSObject.Properties.Name -contains 'primary') {
    $imageModelPrimary = [string]$cfg.agents.defaults.imageModel.primary
}
Add-TelegramCheck $checks 'image-model-primary-optional' $true ("primary={0}" -f $(if ([string]::IsNullOrWhiteSpace($imageModelPrimary)) { 'not configured' } else { $imageModelPrimary }))

$imageModelCapabilityDeclared = [string]::IsNullOrWhiteSpace($imageModelPrimary)
if (-not [string]::IsNullOrWhiteSpace($imageModelPrimary) -and $imageModelPrimary -match '^(?<provider>[^/]+)/(?<model>.+)$') {
    $providerId = $Matches['provider']
    $modelId = $Matches['model']
    $providerConfig = $cfg.models.providers.$providerId
    $providerModel = @($providerConfig.models | Where-Object { [string]$_.id -eq $modelId }) | Select-Object -First 1
    if ($providerModel -and @($providerModel.input) -contains 'image') {
        $imageModelCapabilityDeclared = $true
    }
}
Add-TelegramCheck $checks 'image-model-capability-declared-or-skipped' $imageModelCapabilityDeclared ("primary={0}" -f $(if ([string]::IsNullOrWhiteSpace($imageModelPrimary)) { 'not configured' } else { $imageModelPrimary }))

$result = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('o')
    checks = @($checks)
    passed = (@($checks | Where-Object { -not $_.passed }).Count -eq 0)
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
} else {
    $result
}
