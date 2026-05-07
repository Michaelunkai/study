param(
    [string]$ConfigPath,
    [int]$Port = 18789,
    [int]$TcpTimeoutMs = 1500
)

$ErrorActionPreference = 'Stop'
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
if (-not $ConfigPath) { $ConfigPath = $paths.ConfigPath }
$authority = powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $paths.RepoRoot 'scripts\Test-OpenClawAuthority.ps1') -Json | ConvertFrom-Json

function Test-TcpPort {
    param([string]$HostName, [int]$PortNumber, [int]$TimeoutMs)
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $async = $client.BeginConnect($HostName, $PortNumber, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            return $false
        }
        $client.EndConnect($async)
        return $true
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Get-ListeningPids {
    param([int]$LocalPort)
    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
        return @(
            Get-NetTCPConnection -State Listen -LocalPort $LocalPort -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty OwningProcess -Unique
        )
    }
    return @(
        netstat -ano | Select-String (":$LocalPort\s+.*LISTENING") |
            ForEach-Object { ($_ -split '\s+')[-1] } |
            Where-Object { $_ -match '^\d+$' } |
            Select-Object -Unique
    )
}

$cfg = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
$managerExe = $paths.TrayManagerExe
$runtimeScript = $paths.RuntimeDistEntrypoint
$managers = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -eq 'ClawdBotManager.exe' -and $_.ExecutablePath -eq $managerExe
})
$gateways = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -eq 'node.exe' -and $_.CommandLine -match [regex]::Escape($runtimeScript) -and $_.CommandLine -match ('gateway run --port {0}' -f [regex]::Escape([string]$Port))
})
$listenerPids = @(Get-ListeningPids -LocalPort $Port | ForEach-Object { [int]$_ })
$scheduledTask = $null
try {
    $scheduledTask = schtasks.exe /Query /TN 'OpenClaw Gateway' /FO LIST 2>$null
} catch {
    $scheduledTask = $null
}
$gatewayTaskEnabled = if ($scheduledTask) {
    $taskText = $scheduledTask -join "`n"
    -not (
        $taskText -match '(?im)^\s*Scheduled Task State:\s*Disabled\s*$' -or
        $taskText -match '(?im)^\s*Status:\s*Disabled\s*$'
    )
} else {
    $false
}

[pscustomobject]@{
    generatedAt = (Get-Date).ToString('o')
    configPath = (Resolve-Path -LiteralPath $ConfigPath).Path
    stateRoot = $paths.StateRoot
    authorityGenerationId = $paths.AuthorityGenerationId
    runtimeGenerationId = $paths.RuntimeGenerationId
    authorityPassed = [bool]$authority.passed
    authorityFailedChecks = @($authority.checks | Where-Object { -not $_.passed })
    port = $Port
    tcpLiveness = Test-TcpPort -HostName '127.0.0.1' -PortNumber $Port -TimeoutMs $TcpTimeoutMs
    managerCount = $managers.Count
    managerPids = @($managers | ForEach-Object { [int]$_.ProcessId })
    gatewayCount = $gateways.Count
    gatewayPids = @($gateways | ForEach-Object { [int]$_.ProcessId })
    listenerPids = $listenerPids
    trayOwnedGateway = ($managers.Count -eq 1 -and $gateways.Count -eq 1 -and $gateways[0].ParentProcessId -eq $managers[0].ProcessId)
    scheduledGatewayTaskEnabled = $gatewayTaskEnabled
    permissionPosture = [pscustomobject]@{
        toolsProfile = [string]$cfg.tools.profile
        execAsk = [string]$cfg.tools.exec.ask
        elevatedEnabled = [bool]$cfg.tools.elevated.enabled
        browserEnabled = [bool]$cfg.browser.enabled
        browserEvaluateEnabled = [bool]$cfg.browser.evaluateEnabled
        browserDriver = [string]$cfg.browser.profiles.user.driver
        browserAttachOnly = [bool]$cfg.browser.profiles.user.attachOnly
        crossContextAllow = [bool]$cfg.tools.message.allowCrossContextSend
        crossContextWithinProvider = [bool]$cfg.tools.message.crossContext.allowWithinProvider
        crossContextAcrossProviders = [bool]$cfg.tools.message.crossContext.allowAcrossProviders
        agents = @($cfg.agents.list | ForEach-Object {
            [pscustomobject]@{
                id = $_.id
                profile = [string]$_.tools.profile
                elevatedEnabled = [bool]$_.tools.elevated.enabled
                telegramAllowFrom = @($_.tools.elevated.allowFrom.telegram)
            }
        })
    }
    configAgents = @($cfg.agents.list | ForEach-Object {
        [pscustomobject]@{
            id = $_.id
            accountId = $_.heartbeat.accountId
            workspace = $_.workspace
            heartbeatEvery = $_.heartbeat.every
        }
    })
} | ConvertTo-Json -Depth 8
