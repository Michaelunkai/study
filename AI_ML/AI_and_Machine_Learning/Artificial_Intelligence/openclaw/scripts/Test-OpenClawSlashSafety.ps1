param(
    [string]$ConfigPath,
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
if (-not $ConfigPath) { $ConfigPath = $paths.ConfigPath }

$setScript = Join-Path $paths.RepoRoot 'scripts\telegram-global\Set-OpenClawSlashCommand.ps1'
$protectedBlocked = $false
$protectedError = $null
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$protectedOutput = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $setScript -Action delete -CommandName new -ConfigPath $ConfigPath -SkipMenuSync 2>&1)
$childExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
$protectedError = ($protectedOutput | Out-String).Trim()
$protectedBlocked = ($childExitCode -ne 0 -and $protectedError -match 'Protected OpenClaw infrastructure command')

$slashState = if (Test-Path $paths.SlashStatePath) { Get-Content -Raw -LiteralPath $paths.SlashStatePath | ConvertFrom-Json } else { [pscustomobject]@{ disabledCommands = @() } }
$protectedNames = @('new','nnew','all','claw','slash','reset','session_reset','sessions_reset','start','until_done','verification_loop','strategic_compact')
$protectedDisabled = @($slashState.disabledCommands | Where-Object { $_ -in $protectedNames })

$cfg = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
$customCommands = @($cfg.channels.telegram.customCommands | ForEach-Object { [string]$_.command })
$coreMenuPriority = @()
if (Test-Path $paths.MenuPriorityPath) {
    $coreMenuPriority = @((Get-Content -Raw -LiteralPath $paths.MenuPriorityPath | ConvertFrom-Json).commands)
}

$rollbackProbeCommand = ('zzrollbackprobe{0}' -f (Get-Date -Format 'HHmmss'))
$rollbackProbeBody = @"
---
description: Rollback probe
disable-model-invocation: true
---
# Rollback probe
"@
$rollbackProbeBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($rollbackProbeBody))
$rollbackProbeGeneratedDir = Join-Path $paths.GeneratedCustomCommandsRoot $rollbackProbeCommand
$rollbackProbeWorkspaceDirs = @($paths.WorkspaceRoots | ForEach-Object { Join-Path (Join-Path $_ '.codex\skills\custom-commands') $rollbackProbeCommand })
$cfgBeforeRollbackProbe = Get-Content -Raw -LiteralPath $ConfigPath
$rollbackProbeBlocked = $false
$rollbackProbeClean = $false
$rollbackProbeError = $null
$badMenuPath = 'Z:\openclaw-rollback-probe\menu-priority.json'
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$rollbackOutput = @(& powershell -NoProfile -ExecutionPolicy Bypass -File $setScript -Action add -CommandName $rollbackProbeCommand -Description 'Rollback probe' -SkillBodyBase64 $rollbackProbeBase64 -ConfigPath $ConfigPath -MenuPriorityPath $badMenuPath -SkipMenuSync 2>&1)
$rollbackExitCode = $LASTEXITCODE
$ErrorActionPreference = $previousErrorActionPreference
$rollbackProbeError = ($rollbackOutput | Out-String).Trim()
$rollbackProbeBlocked = ($rollbackExitCode -ne 0)
$cfgAfterRollbackProbe = Get-Content -Raw -LiteralPath $ConfigPath
$cfgAfterRollbackProbeJson = $cfgAfterRollbackProbe | ConvertFrom-Json
$rollbackProbeConfigClean = (@($cfgAfterRollbackProbeJson.channels.telegram.customCommands | Where-Object { [string]$_.command -eq $rollbackProbeCommand }).Count -eq 0)
$rollbackProbeGeneratedClean = -not (Test-Path -LiteralPath $rollbackProbeGeneratedDir)
$rollbackProbeWorkspaceClean = (@($rollbackProbeWorkspaceDirs | Where-Object { Test-Path -LiteralPath $_ }).Count -eq 0)
$rollbackProbeConfigRestored = ($cfgAfterRollbackProbe -eq $cfgBeforeRollbackProbe)
$rollbackProbeClean = ($rollbackProbeBlocked -and $rollbackProbeConfigClean -and $rollbackProbeGeneratedClean -and $rollbackProbeWorkspaceClean -and $rollbackProbeConfigRestored)

$result = [pscustomobject]@{
    protectedMutationBlocked = $protectedBlocked
    protectedMutationError = $protectedError
    rollbackProbeBlocked = $rollbackProbeBlocked
    rollbackProbeClean = $rollbackProbeClean
    rollbackProbeError = $rollbackProbeError
    protectedDisabled = $protectedDisabled
    corePriorityPresent = (@('nnew','slash','all','claw','todos_sub') | Where-Object { $_ -notin $coreMenuPriority }).Count -eq 0
    customCommandCount = $customCommands.Count
    menuPriorityCount = $coreMenuPriority.Count
    typedDispatchIndependentOfMenuVisibility = ($customCommands.Count -gt 100)
    protectedMatrix = $protectedNames
    passed = ($protectedBlocked -and $rollbackProbeClean -and $protectedDisabled.Count -eq 0)
}

if ($Json) { $result | ConvertTo-Json -Depth 6 } else { $result }
