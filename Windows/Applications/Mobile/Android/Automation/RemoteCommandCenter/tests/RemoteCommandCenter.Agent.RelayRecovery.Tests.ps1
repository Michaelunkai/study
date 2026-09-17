$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$agent = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterAgent.ps1'
$sandbox = Join-Path $env:TEMP ("rcc-agent-relay-test-" + [guid]::NewGuid().ToString('N'))
$stateDir = Join-Path $sandbox 'state'
$logDir = Join-Path $sandbox 'logs'
$configPath = Join-Path $sandbox 'rcc-config.json'
$requestLog = Join-Path $sandbox 'relay-requests.txt'
$stopPath = Join-Path $sandbox 'stop-relay.flag'
$port = Get-Random -Minimum 24001 -Maximum 29000
$relayBase = "http://127.0.0.1:$port"
$topic = 'rcc-test'
$sharedKey = 'agent-relay-test-key'
$relayJob = $null
$agentProcesses = New-Object 'System.Collections.Generic.List[System.Diagnostics.Process]'

. (Join-Path $projectRoot 'scripts\RemoteCommandCenter.Protocol.ps1')
New-Item -ItemType Directory -Force -Path $stateDir, $logDir | Out-Null
[ordered]@{
    StateDir = $stateDir
    LogDir = $logDir
    SharedKey = $sharedKey
    AllowedSkewSeconds = 120
    RelayBases = @($relayBase)
    CommandTopic = $topic
    StatusTopic = 'rcc-test-status'
} | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $configPath -Encoding UTF8

$nonce = [guid]::NewGuid().ToString('N')
$createdAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + 30
$action = 'restart_codex'
$confirm = 'REMOTE_COMMAND_CENTER_EXECUTE'
$canonical = "rcc|$createdAt|$nonce|true|$action|$confirm"
$signature = Get-RccHmacSignature -Text $canonical -Key $sharedKey
$commandBody = [ordered]@{
    type = 'rcc'
    createdAt = $createdAt
    nonce = $nonce
    dryRun = $true
    action = $action
    confirm = $confirm
    signature = $signature
} | ConvertTo-Json -Compress
$eventId = "evt-$nonce"
$event = [ordered]@{
    event = 'message'
    id = $eventId
    time = $createdAt
    message = $commandBody
} | ConvertTo-Json -Compress
$staleNonce = [guid]::NewGuid().ToString('N')
$staleCreatedAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - 1
$staleAction = 'shutdown_pc'
$staleCanonical = "rcc|$staleCreatedAt|$staleNonce|true|$staleAction|$confirm"
$staleBody = [ordered]@{
    type = 'rcc'; createdAt = $staleCreatedAt; nonce = $staleNonce; dryRun = $true
    action = $staleAction; confirm = $confirm
    signature = Get-RccHmacSignature -Text $staleCanonical -Key $sharedKey
} | ConvertTo-Json -Compress
$staleEvent = [ordered]@{
    event = 'message'
    id = "evt-stale-$staleNonce"
    time = $staleCreatedAt
    message = $staleBody
} | ConvertTo-Json -Compress
$eventBatch = $staleEvent + "`n" + $event

try {
    $relayJob = Start-Job -ArgumentList $port, $eventBatch, $eventId, $requestLog, $stopPath -ScriptBlock {
        param($ListenPort, $EventBody, $EventId, $RequestLogPath, $StopFile)
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://127.0.0.1:$ListenPort/")
        $listener.Start()
        try {
            while (-not (Test-Path -LiteralPath $StopFile)) {
                $context = $listener.GetContext()
                try {
                    if ($context.Request.Url.AbsolutePath -eq '/stop') {
                        $responseText = 'stopping'
                    } else {
                        $since = [string]$context.Request.QueryString['since']
                        Add-Content -LiteralPath $RequestLogPath -Encoding UTF8 -Value $since
                        $responseText = if ($since -eq $EventId) { '' } else { $EventBody }
                    }
                    $responseBytes = [Text.Encoding]::UTF8.GetBytes($responseText)
                    $context.Response.StatusCode = 200
                    $context.Response.ContentLength64 = $responseBytes.Length
                    if ($responseBytes.Length -gt 0) { $context.Response.OutputStream.Write($responseBytes, 0, $responseBytes.Length) }
                } finally {
                    $context.Response.Close()
                }
                if ($context.Request.Url.AbsolutePath -eq '/stop') { break }
            }
        } finally {
            $listener.Stop()
            $listener.Close()
        }
    }

    $readyDeadline = [DateTime]::UtcNow.AddSeconds(15)
    do {
        Start-Sleep -Milliseconds 100
        $jobState = (Get-Job -Id $relayJob.Id).State
        if ($jobState -eq 'Failed') { throw 'Isolated relay listener failed to start.' }
        try { Invoke-WebRequest -UseBasicParsing -Uri "$relayBase/health" -TimeoutSec 1 | Out-Null } catch { }
    } while (-not (Test-Path -LiteralPath $requestLog) -and [DateTime]::UtcNow -lt $readyDeadline)

    $crashMarker = Join-Path $stateDir 'test-agent-crash-after-accepted.flag'
    Set-Content -LiteralPath $crashMarker -Value 'test-only' -Encoding ASCII
    $agentArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$agent,'-ConfigPath',$configPath,'-Once','-TestMode')
    $crashProcess = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $agentArgs -WindowStyle Hidden -PassThru
    $agentProcesses.Add($crashProcess)
    if (-not $crashProcess.WaitForExit(20000)) { throw 'Agent did not reach the injected accepted-before-claim crash point.' }
    if ($crashProcess.ExitCode -ne 97) { throw "Agent did not stop at the expected accepted-before-claim test point; exit=$($crashProcess.ExitCode)." }

    $statusDir = Join-Path $stateDir 'action-status'
    $statusPath = Join-Path $statusDir "$nonce.json"
    $claimPath = Join-Path $statusDir "$nonce.dispatch"
    $accepted = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
    if ($accepted.state -ne 'accepted' -or (Test-Path -LiteralPath $claimPath)) {
        throw 'Crash injection did not leave the intended accepted status without a dispatch claim.'
    }
    if (Test-Path -LiteralPath (Join-Path $statusDir "$staleNonce.json")) {
        throw 'Relay replay accepted an event older than the durable first-run baseline.'
    }

    $recoveryProcess = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $agentArgs -WindowStyle Hidden -PassThru
    $agentProcesses.Add($recoveryProcess)
    if (-not $recoveryProcess.WaitForExit(20000)) { throw 'Agent restart did not complete its one-pass relay recovery.' }
    if ($recoveryProcess.ExitCode -ne 0) { throw "Agent restart failed during relay recovery; exit=$($recoveryProcess.ExitCode)." }
    if (-not (Test-Path -LiteralPath $claimPath -PathType Leaf)) { throw 'Restart did not create the dispatch claim for the accepted relay action.' }

    $cursorFiles = @(Get-ChildItem -LiteralPath (Join-Path $stateDir 'relay-cursors') -Filter '*.json' -File)
    if ($cursorFiles.Count -ne 1) { throw "Expected exactly one durable relay cursor record, found $($cursorFiles.Count)." }
    $cursorRecord = Get-Content -LiteralPath $cursorFiles[0].FullName -Raw | ConvertFrom-Json
    if ($cursorRecord.cursor -ne $eventId) { throw 'Recovered event cursor was not durably advanced.' }

    $repeatProcess = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $agentArgs -WindowStyle Hidden -PassThru
    $agentProcesses.Add($repeatProcess)
    if (-not $repeatProcess.WaitForExit(20000)) { throw 'Agent cursor verification pass did not complete.' }
    if ($repeatProcess.ExitCode -ne 0) { throw "Agent cursor verification pass failed; exit=$($repeatProcess.ExitCode)." }
    $acceptedDispatches = @(Select-String -LiteralPath (Join-Path $logDir 'agent.log') -SimpleMatch "Accepted command action=restart_codex nonce=$nonce")
    if ($acceptedDispatches.Count -ne 1) { throw "Relay action dispatch count was not exactly one; count=$($acceptedDispatches.Count)." }

    Invoke-WebRequest -UseBasicParsing -Uri "$relayBase/stop" -TimeoutSec 2 | Out-Null
    Stop-Job -Id $relayJob.Id -ErrorAction SilentlyContinue | Out-Null
    Receive-Job -Id $relayJob.Id -ErrorAction SilentlyContinue | Out-Null
    $relayJob = $null
    'REMOTE_COMMAND_CENTER_AGENT_RELAY_RECOVERY_TESTS_PASS'
} finally {
    foreach ($agentProcess in $agentProcesses) {
        try {
            if (-not $agentProcess.HasExited) {
                $agentProcess.Kill()
                $agentProcess.WaitForExit(5000) | Out-Null
            }
        } catch { }
    }
    if ($relayJob) {
        try { Invoke-WebRequest -UseBasicParsing -Uri "$relayBase/stop" -TimeoutSec 2 | Out-Null } catch { }
        try { Stop-Job -Id $relayJob.Id -ErrorAction SilentlyContinue | Out-Null } catch { }
        try { Remove-Job -Id $relayJob.Id -Force -ErrorAction SilentlyContinue | Out-Null } catch { }
    }
    $tempRoot = [IO.Path]::GetFullPath($env:TEMP).TrimEnd('\') + '\'
    $resolvedSandbox = [IO.Path]::GetFullPath($sandbox)
    if ($resolvedSandbox.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedSandbox).StartsWith('rcc-agent-relay-test-', [StringComparison]::Ordinal)) {
        Remove-Item -LiteralPath $resolvedSandbox -Recurse -Force -ErrorAction SilentlyContinue
    }
}
