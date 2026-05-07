param(
    [string]$ConfigPath,
    [switch]$SkipTelegramNetwork,
    [switch]$Json,
    [int]$SubprocessTimeoutSeconds = 90
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
if (-not $ConfigPath) { $ConfigPath = $paths.ConfigPath }

function Add-Check {
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

function Resolve-FirstFileByPattern {
    param(
        [Parameter(Mandatory = $true)][string]$Directory,
        [Parameter(Mandatory = $true)][string]$Filter,
        [string]$RequiredTextPattern
    )

    $files = @(Get-ChildItem -LiteralPath $Directory -File -Filter $Filter -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
    if ($RequiredTextPattern) {
        $files = @($files | Where-Object {
            try {
                (Get-Content -Raw -LiteralPath $_.FullName) -match $RequiredTextPattern
            } catch {
                $false
            }
        })
    }
    return @($files | Select-Object -ExpandProperty FullName -First 1)[0]
}

function ConvertTo-ProcessArgument {
    param([string]$Argument)

    if ($null -eq $Argument) {
        return '""'
    }

    if ($Argument -notmatch '[\s"]') {
        return $Argument
    }

    return '"' + ($Argument -replace '"', '\"') + '"'
}

function ConvertTo-PowerShellLiteral {
    param([string]$Value)

    if ($null -eq $Value) {
        return "''"
    }

    return "'" + ($Value -replace "'", "''") + "'"
}

function ConvertTo-PowerShellInvocationArgument {
    param([string]$Value)

    if ($Value -match '^-[A-Za-z][A-Za-z0-9_:-]*$') {
        return $Value
    }

    return ConvertTo-PowerShellLiteral $Value
}

function Invoke-OpenClawJsonSubprocess {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [string[]]$Arguments = @(),
        [int]$TimeoutSeconds = 90
    )

    $wrapperPath = [System.IO.Path]::ChangeExtension([System.IO.Path]::GetTempFileName(), '.ps1')
    $stdoutPath = [System.IO.Path]::GetTempFileName()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    $process = [System.Diagnostics.Process]::new()

    try {
        $scriptLiteral = ConvertTo-PowerShellLiteral $ScriptPath
        $stdoutLiteral = ConvertTo-PowerShellLiteral $stdoutPath
        $stderrLiteral = ConvertTo-PowerShellLiteral $stderrPath
        $argumentText = ($Arguments | ForEach-Object { ConvertTo-PowerShellInvocationArgument $_ }) -join ' '
        $wrapper = @"
`$ErrorActionPreference = 'Stop'
try {
    & $scriptLiteral $argumentText > $stdoutLiteral 2> $stderrLiteral
    if (`$global:LASTEXITCODE -is [int]) {
        exit `$global:LASTEXITCODE
    }
    exit 0
} catch {
    (`$_ | Out-String) | Out-File -LiteralPath $stderrLiteral -Append
    exit 1
}
"@
        Set-Content -LiteralPath $wrapperPath -Value $wrapper -Encoding UTF8

        $process.StartInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $process.StartInfo.FileName = 'powershell.exe'
        $process.StartInfo.Arguments = ('-NoProfile -ExecutionPolicy Bypass -File {0}' -f (ConvertTo-ProcessArgument $wrapperPath))
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true

        [void]$process.Start()
        $completed = $process.WaitForExit([Math]::Max(1, $TimeoutSeconds) * 1000)

        if (-not $completed) {
            try { $process.Kill() } catch {}
            try { $process.WaitForExit(1000) } catch {}
        }

        $stdoutText = if (Test-Path -LiteralPath $stdoutPath) { Get-Content -Raw -LiteralPath $stdoutPath } else { '' }
        $stderrText = if (Test-Path -LiteralPath $stderrPath) { Get-Content -Raw -LiteralPath $stderrPath } else { '' }
        $exitCode = if ($completed -and $process.HasExited) { $process.ExitCode } else { $null }
        $json = $null
        $errorText = $null

        if (-not $completed) {
            $errorText = "Timed out after $TimeoutSeconds seconds"
        } elseif ($exitCode -ne 0) {
            $errorText = "Exited with code $exitCode"
        } else {
            try {
                $json = $stdoutText | ConvertFrom-Json
            } catch {
                $errorText = "Invalid JSON output: $($_.Exception.Message)"
            }
        }

        if ($stderrText) {
            $trimmedError = $stderrText.Trim()
            if ($errorText) {
                $errorText = "$errorText; stderr=$trimmedError"
            } else {
                $errorText = "stderr=$trimmedError"
            }
        }

        [pscustomobject]@{
            timedOut = -not $completed
            exitCode = $exitCode
            output = $stdoutText
            error = $errorText
            json = $json
        }
    } finally {
        if ($process) {
            $process.Dispose()
        }
        Remove-Item -LiteralPath $wrapperPath, $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

$checks = [System.Collections.Generic.List[object]]::new()
$cfg = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
$truthResult = Invoke-OpenClawJsonSubprocess -ScriptPath (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawCurrentTruth.ps1') -Arguments @('-ConfigPath', $ConfigPath) -TimeoutSeconds $SubprocessTimeoutSeconds
$truth = if ($truthResult.json) { $truthResult.json } else { [pscustomobject]@{} }
$truthStatus = if ($truthResult.error) { "truth subprocess: $($truthResult.error)" } else { $null }

Add-Check $checks 'config-json-valid' $true "Parsed $ConfigPath"
Add-Check $checks 'active-config-path' ((Resolve-Path -LiteralPath $ConfigPath).Path -eq (Resolve-Path -LiteralPath $paths.ConfigPath).Path) $ConfigPath
Add-Check $checks 'authority-passed' ((-not $truthStatus) -and [bool]$truth.authorityPassed) "$(if ($truthStatus) { $truthStatus } else { "authorityFailedChecks=$(@($truth.authorityFailedChecks).Count)" })"
Add-Check $checks 'tcp-liveness' ((-not $truthStatus) -and [bool]$truth.tcpLiveness) "$(if ($truthStatus) { $truthStatus } else { "127.0.0.1:$($truth.port)" })"
Add-Check $checks 'single-tray-manager' ((-not $truthStatus) -and $truth.managerCount -eq 1) "$(if ($truthStatus) { $truthStatus } else { "managerCount=$($truth.managerCount) pids=$($truth.managerPids -join ',')" })"
Add-Check $checks 'single-gateway-node' ((-not $truthStatus) -and $truth.gatewayCount -eq 1) "$(if ($truthStatus) { $truthStatus } else { "gatewayCount=$($truth.gatewayCount) pids=$($truth.gatewayPids -join ',')" })"
Add-Check $checks 'tray-owned-gateway' ((-not $truthStatus) -and [bool]$truth.trayOwnedGateway) "$(if ($truthStatus) { $truthStatus } else { "trayOwnedGateway=$($truth.trayOwnedGateway)" })"
Add-Check $checks 'scheduled-gateway-disabled' ((-not $truthStatus) -and -not [bool]$truth.scheduledGatewayTaskEnabled) "$(if ($truthStatus) { $truthStatus } else { "scheduledGatewayTaskEnabled=$($truth.scheduledGatewayTaskEnabled)" })"

$protectedDisabled = @()
$legacyNewDisabled = $false
if (Test-Path $paths.SlashStatePath) {
    $slashState = Get-Content -Raw -LiteralPath $paths.SlashStatePath | ConvertFrom-Json
    $protectedDisabled = @($slashState.disabledCommands | Where-Object { $_ -in @('nnew','all','claw','slash','reset','session_reset','sessions_reset','start','until_done','verification_loop','strategic_compact') })
    $legacyNewDisabled = @($slashState.disabledCommands) -contains 'new'
}
Add-Check $checks 'protected-slash-not-disabled' ($protectedDisabled.Count -eq 0) "protectedDisabled=$($protectedDisabled -join ',')"
$catalogHasLegacyNew = $false
if (Test-Path $paths.CommandCatalogPath) {
    $catalog = Get-Content -Raw -LiteralPath $paths.CommandCatalogPath | ConvertFrom-Json
    $catalogHasLegacyNew = @($catalog.entries | Where-Object { $_.command -eq 'new' }).Count -gt 0
}
Add-Check $checks 'legacy-new-slash-not-shadowing-nnew' ($legacyNewDisabled -and -not $catalogHasLegacyNew) "legacyNewDisabled=$legacyNewDisabled catalogHasNew=$catalogHasLegacyNew"

$heartbeatPrompts = @($cfg.agents.list | ForEach-Object { [string]$_.heartbeat.prompt })
$activeProgressPromptOk = @($heartbeatPrompts | Where-Object { $_ -notmatch 'active work' -or $_ -notmatch '30 seconds' }).Count -eq 0
Add-Check $checks 'active-progress-heartbeat-prompts' $activeProgressPromptOk "agents=$(@($cfg.agents.list).Count)"

$clawdbotHeartbeatRuntimePath = Join-Path $paths.RepoRoot 'npm-global\node_modules\clawdbot\dist\auto-reply\heartbeat.js'
$clawdbotHeartbeatRuntime = if (Test-Path $clawdbotHeartbeatRuntimePath) { Get-Content -Raw -LiteralPath $clawdbotHeartbeatRuntimePath } else { '' }
Add-Check $checks 'clawdbot-heartbeat-runtime-present' ((Test-Path $clawdbotHeartbeatRuntimePath) -and $clawdbotHeartbeatRuntime -match 'DEFAULT_HEARTBEAT_EVERY' -and $clawdbotHeartbeatRuntime -match 'DEFAULT_HEARTBEAT_ACK_MAX_CHARS') $clawdbotHeartbeatRuntimePath

$openClawHeartbeatRuntimePath = Resolve-FirstFileByPattern -Directory (Join-Path $paths.RuntimeRoot 'dist') -Filter 'heartbeat-*.js' -RequiredTextPattern 'const HEARTBEAT_PROMPT'
$openClawHeartbeatRuntime = if (Test-Path $openClawHeartbeatRuntimePath) { Get-Content -Raw -LiteralPath $openClawHeartbeatRuntimePath } else { '' }
Add-Check $checks 'openclaw-heartbeat-runtime-present' ((Test-Path $openClawHeartbeatRuntimePath) -and $openClawHeartbeatRuntime -match 'HEARTBEAT_PROMPT' -and $openClawHeartbeatRuntime -match 'DEFAULT_HEARTBEAT_ACK_MAX_CHARS') $openClawHeartbeatRuntimePath

$sessionsToolPath = Resolve-FirstFileByPattern -Directory (Join-Path $paths.RuntimeRoot 'dist') -Filter 'openclaw-tools-*.js' -RequiredTextPattern 'sourceTool:\s*"sessions_send"'
$sessionsTool = if (Test-Path $sessionsToolPath) { Get-Content -Raw -LiteralPath $sessionsToolPath } else { '' }
$sessionsOwnerRefs = [regex]::Matches($sessionsTool, 'senderIsOwner').Count
Add-Check $checks 'sessions-send-propagates-owner' ($sessionsTool -match 'senderIsOwner:\s*options\?\.senderIsOwner\s*\?\?\s*void 0' -and $sessionsOwnerRefs -ge 5 -and $sessionsTool -match 'sourceTool:\s*"sessions_send"') $sessionsToolPath

$telegramSendPath = Resolve-FirstFileByPattern -Directory (Join-Path $paths.RuntimeRoot 'dist\extensions\telegram') -Filter 'send-*.js' -RequiredTextPattern 'isTelegramRateLimitError'
$telegramSend = if (Test-Path $telegramSendPath) { Get-Content -Raw -LiteralPath $telegramSendPath } else { '' }
Add-Check $checks 'telegram-send-resilience-present' ($telegramSend -match 'requestWithDiag' -and $telegramSend -match 'sendChatAction' -and $telegramSend -match 'isTelegramRateLimitError') $telegramSendPath

$workspaceHeartbeatFiles = @($paths.WorkspaceRoots | ForEach-Object { Join-Path $_ 'HEARTBEAT.md' })
$heartbeatFilesOk = @($workspaceHeartbeatFiles | Where-Object { -not (Test-Path $_) }).Count -eq 0
Add-Check $checks 'workspace-heartbeat-files' $heartbeatFilesOk ($workspaceHeartbeatFiles -join '; ')

$evidenceResult = Invoke-OpenClawJsonSubprocess -ScriptPath (Join-Path $paths.RepoRoot 'scripts\Get-OpenClawLatestEvidence.ps1') -Arguments @('-RecentFiles', '4', '-TailBytes', '4096') -TimeoutSeconds $SubprocessTimeoutSeconds
$evidence = if ($evidenceResult.json) { $evidenceResult.json } else { [pscustomobject]@{} }
$evidenceDetail = if ($evidenceResult.error) { "evidence subprocess: $($evidenceResult.error)" } else { "sessions=$(@($evidence.sessions).Count) logs=$(@($evidence.gatewayLogs).Count) tasks=$(@($evidence.taskFiles).Count)" }
Add-Check $checks 'evidence-recovery-bounded' (($null -ne $evidence.generatedAt) -and -not $evidenceResult.error) $evidenceDetail

$menuPriority = if (Test-Path $paths.MenuPriorityPath) { Get-Content -Raw -LiteralPath $paths.MenuPriorityPath | ConvertFrom-Json } else { $null }
Add-Check $checks 'menu-priority-has-core-commands' ($menuPriority -and @('nnew','slash','all','claw','todos_sub' | Where-Object { $_ -notin @($menuPriority.commands) }).Count -eq 0) $paths.MenuPriorityPath

$result = [pscustomobject]@{
    generatedAt = (Get-Date).ToString('o')
    configPath = (Resolve-Path -LiteralPath $ConfigPath).Path
    skippedTelegramNetwork = [bool]$SkipTelegramNetwork
    checks = @($checks)
    passed = (@($checks | Where-Object { -not $_.passed }).Count -eq 0)
}

if ($Json) {
    $result | ConvertTo-Json -Depth 8
} else {
    $result
}
