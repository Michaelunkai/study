$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$receiver = Join-Path $projectRoot 'scripts\Start-RemoteCommandCenterHttpReceiver.ps1'
$sandbox = Join-Path $env:TEMP ("rcc-receiver-test-" + [guid]::NewGuid().ToString('N'))
$stateDir = Join-Path $sandbox 'state'
$logDir = Join-Path $sandbox 'logs'
$configPath = Join-Path $sandbox 'rcc-config.json'
$port = Get-Random -Minimum 19000 -Maximum 24000
$sharedKey = 'integration-test-only-key'
$mutexName = "Local\RemoteCommandCenterHttpReceiverTest_$([guid]::NewGuid().ToString('N'))"
. (Join-Path $projectRoot 'scripts\RemoteCommandCenter.Protocol.ps1')

New-Item -ItemType Directory -Force -Path $stateDir, $logDir | Out-Null
[ordered]@{
    StateDir = $stateDir
    LogDir = $logDir
    SharedKey = $sharedKey
    AllowedSkewSeconds = 120
} | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding UTF8

function ConvertTo-Base64Url {
    param([byte[]]$Bytes)
    [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

function Get-Signature {
    param([string]$Text, [string]$Key)
    $hmac = New-Object Security.Cryptography.HMACSHA256
    try {
        $hmac.Key = [Text.Encoding]::UTF8.GetBytes($Key)
        ConvertTo-Base64Url $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
    } finally {
        $hmac.Dispose()
    }
}

$arguments = @(
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', $receiver,
    '-ConfigPath', $configPath,
    '-Port', $port,
    '-ListenHost', '127.0.0.1',
    '-MutexName', $mutexName,
    '-TestMode'
)
$process = Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -ArgumentList $arguments -WindowStyle Hidden -PassThru

$statusUri = "http://127.0.0.1:$port/rcc/status"
$deadline = [DateTime]::UtcNow.AddSeconds(30)
do {
    Start-Sleep -Milliseconds 100
    if ($process.HasExited) {
        $listenerLog = Join-Path $logDir 'http-listener.log'
        $listenerTail = if (Test-Path -LiteralPath $listenerLog) {
            (Get-Content -LiteralPath $listenerLog -Tail 20) -join ' | '
        } else {
            '<missing>'
        }
        throw "Isolated receiver exited during startup. exit=$($process.ExitCode) log=$listenerTail"
    }
    try {
        $ready = Invoke-RestMethod -Method Get -Uri $statusUri -TimeoutSec 1
    } catch {
        $ready = $null
    }
} while (-not $ready.ok -and [DateTime]::UtcNow -lt $deadline)
if (-not $ready.ok) {
    $listenerLog = Join-Path $logDir 'http-listener.log'
    $listenerTail = if (Test-Path -LiteralPath $listenerLog) {
        (Get-Content -LiteralPath $listenerLog -Tail 20) -join ' | '
    } else {
        '<missing>'
    }
    throw "Isolated receiver did not become ready. pid=$($process.Id) port=$port log=$listenerTail"
}
trap {
    $integrationError = $_
    try { Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/test-stop" -ContentType 'application/json' -Body '{}' -TimeoutSec 2 | Out-Null } catch { }
    try { $process.WaitForExit(5000) | Out-Null } catch { }
    throw $integrationError
}
if ($ready.PSObject.Properties.Name -contains 'machine' -or $ready.PSObject.Properties.Name -contains 'utc') {
    throw 'Unauthenticated readiness response disclosed host identity or time metadata.'
}

$nonce = [guid]::NewGuid().ToString('N')
$createdAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$action = 'restart_codex'
$confirm = 'REMOTE_COMMAND_CENTER_EXECUTE'
$canonical = "rcc|$createdAt|$nonce|true|$action|$confirm"
$body = [ordered]@{
    type = 'rcc'
    createdAt = $createdAt
    nonce = $nonce
    dryRun = $true
    action = $action
    confirm = $confirm
    signature = Get-Signature -Text $canonical -Key $sharedKey
} | ConvertTo-Json -Compress

try {
    Invoke-RestMethod -Method Get -Uri "$statusUri`?nonce=$nonce" -TimeoutSec 2 -ErrorAction Stop | Out-Null
    throw 'Unauthenticated action-status query was accepted.'
} catch {
    if ([int]$_.Exception.Response.StatusCode -ne 403) { throw }
}

$unknownAction = 'unsupported_action'
$unknownNonce = [guid]::NewGuid().ToString('N')
$unknownCanonical = "rcc|$createdAt|$unknownNonce|true|$unknownAction|$confirm"
$unknownBody = [ordered]@{
    type = 'rcc'; createdAt = $createdAt; nonce = $unknownNonce; dryRun = $true
    action = $unknownAction; confirm = $confirm
    signature = Get-Signature -Text $unknownCanonical -Key $sharedKey
} | ConvertTo-Json -Compress
try {
    Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $unknownBody -TimeoutSec 2 -ErrorAction Stop | Out-Null
    throw 'A validly signed unknown action was accepted.'
} catch {
    if ([int]$_.Exception.Response.StatusCode -ne 403) { throw }
}

$chunkedRequest = [System.Net.HttpWebRequest]::Create("http://127.0.0.1:$port/rcc/action")
$chunkedRequest.Method = 'POST'
$chunkedRequest.ContentType = 'application/json'
$chunkedRequest.SendChunked = $true
$chunkedRequest.AllowWriteStreamBuffering = $false
$chunkedStream = $chunkedRequest.GetRequestStream()
try {
    $oversizedChunkedBody = [Text.Encoding]::UTF8.GetBytes(('x' * 65537))
    $chunkedStream.Write($oversizedChunkedBody, 0, $oversizedChunkedBody.Length)
} finally {
    $chunkedStream.Dispose()
}
$chunkedStatusCode = 0
try {
    $chunkedResponse = $chunkedRequest.GetResponse()
    try { $chunkedStatusCode = [int]$chunkedResponse.StatusCode } finally { $chunkedResponse.Close() }
} catch [System.Net.WebException] {
    if ($_.Exception.Response) {
        $chunkedStatusCode = [int]$_.Exception.Response.StatusCode
        $_.Exception.Response.Close()
    } else {
        throw
    }
}
if ($chunkedStatusCode -ne 413) { throw "Oversized chunked request was not rejected with HTTP 413; status=$chunkedStatusCode" }

$requestCommand = $body | ConvertFrom-Json
$requestHash = Get-RccRequestFingerprint -Command $requestCommand
$statusPath = Join-Path (Join-Path $stateDir 'action-status') "$nonce.json"
$recoveredAccepted = New-RccActionStatus -Nonce $nonce -Action $action -RequestHash $requestHash -State 'accepted' -SharedKey $sharedKey -Message 'accepted'
Write-RccActionStatusFile -Path $statusPath -Record $recoveredAccepted | Out-Null
$claimPath = Join-Path (Join-Path $stateDir 'action-status') "$nonce.dispatch"
if (Test-Path -LiteralPath $claimPath) { throw 'Recovery test unexpectedly started with an existing dispatch claim.' }
$first = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $body
$second = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $body
if (-not $first.ok -or $first.message -ne 'started') { throw 'First action was not started.' }
if (-not $second.ok -or -not $second.duplicate -or $second.message -ne 'duplicate') {
    throw 'Second action with the same nonce was not deduplicated.'
}

$claimedNonce = [guid]::NewGuid().ToString('N')
$claimedCanonical = "rcc|$createdAt|$claimedNonce|true|$action|$confirm"
$claimedBody = [ordered]@{
    type = 'rcc'; createdAt = $createdAt; nonce = $claimedNonce; dryRun = $true
    action = $action; confirm = $confirm
    signature = Get-Signature -Text $claimedCanonical -Key $sharedKey
} | ConvertTo-Json -Compress
$claimedCommand = $claimedBody | ConvertFrom-Json
$claimedRequestHash = Get-RccRequestFingerprint -Command $claimedCommand
$claimedStatusPath = Join-Path (Join-Path $stateDir 'action-status') "$claimedNonce.json"
$claimedRecord = New-RccActionStatus -Nonce $claimedNonce -Action $action -RequestHash $claimedRequestHash -State 'accepted' -SharedKey $sharedKey -Message 'accepted'
Write-RccActionStatusFile -Path $claimedStatusPath -Record $claimedRecord | Out-Null
$claimedDispatchPath = Join-Path (Join-Path $stateDir 'action-status') "$claimedNonce.dispatch"
[IO.File]::WriteAllText($claimedDispatchPath, '')
$claimedDuplicate = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $claimedBody
if (-not $claimedDuplicate.ok -or -not $claimedDuplicate.duplicate -or $claimedDuplicate.message -ne 'duplicate') {
    throw 'A pre-existing dispatch claim was not kept at-most-once.'
}

$collisionAction = 'explorer_refresh_gpu'
$collisionCanonical = "rcc|$createdAt|$nonce|true|$collisionAction|$confirm"
$collisionBody = [ordered]@{
    type = 'rcc'; createdAt = $createdAt; nonce = $nonce; dryRun = $true
    action = $collisionAction; confirm = $confirm
    signature = Get-Signature -Text $collisionCanonical -Key $sharedKey
} | ConvertTo-Json -Compress
try {
    Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $collisionBody -TimeoutSec 2 -ErrorAction Stop | Out-Null
    throw 'A different signed command reused an existing nonce.'
} catch {
    if ([int]$_.Exception.Response.StatusCode -ne 409) { throw }
}

$deadline = [DateTime]::UtcNow.AddSeconds(30)
do {
    Start-Sleep -Milliseconds 150
    $proof = Get-RccStatusQueryProof -Nonce $nonce -SharedKey $sharedKey
    $status = Invoke-RestMethod -Method Get -Uri "$statusUri`?nonce=$nonce&proof=$proof" -TimeoutSec 2
} while ($status.actionStatus.state -in @('accepted', 'running') -and [DateTime]::UtcNow -lt $deadline)

if ($status.actionStatus.state -ne 'completed') {
    throw "Tracked action did not complete successfully. state=$($status.actionStatus.state) message=$($status.actionStatus.message)"
}
$statusRecord = $status.actionStatus
$statusCanonical = "rcc-status|$($statusRecord.nonce)|$($statusRecord.action)|$($statusRecord.requestHash)|$($statusRecord.state)|$($statusRecord.exitCode)|$($statusRecord.updatedUtc)|$($statusRecord.message)"
if ($statusRecord.signature -ne (Get-Signature -Text $statusCanonical -Key $sharedKey)) {
    throw 'Action status HMAC did not verify.'
}
$terminalNonce = [guid]::NewGuid().ToString('N')
$terminalCommand = 'Write-Output "' + [char]0x05E9 + [char]0x05DC + [char]0x05D5 + [char]0x05DD + ' ' + [char]::ConvertFromUtf32(0x1F319) + '"'
$terminalEncoded = ConvertTo-Base64Url -Bytes ([Text.Encoding]::UTF8.GetBytes($terminalCommand))
$terminalAction = "terminal_line:$terminalEncoded"
$terminalCanonical = "rcc|$createdAt|$terminalNonce|true|$terminalAction|$confirm"
$terminalBody = [ordered]@{
    type = 'rcc'; createdAt = $createdAt; nonce = $terminalNonce; dryRun = $true
    action = $terminalAction; confirm = $confirm
    signature = Get-Signature -Text $terminalCanonical -Key $sharedKey
} | ConvertTo-Json -Compress
$terminalAccepted = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $terminalBody
if (-not $terminalAccepted.ok -or $terminalAccepted.message -ne 'started') { throw 'Unicode terminal proof action was not accepted.' }
$terminalDuplicate = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $terminalBody
if (-not $terminalDuplicate.ok -or -not $terminalDuplicate.duplicate -or $terminalDuplicate.message -ne 'duplicate') {
    throw 'The sanitized terminal status did not preserve same-nonce deduplication.'
}
$terminalDeadline = [DateTime]::UtcNow.AddSeconds(30)
do {
    Start-Sleep -Milliseconds 150
    $terminalProof = Get-RccStatusQueryProof -Nonce $terminalNonce -SharedKey $sharedKey
    $terminalStatus = Invoke-RestMethod -Method Get -Uri "$statusUri`?nonce=$terminalNonce&proof=$terminalProof" -TimeoutSec 2
} while ($terminalStatus.actionStatus.state -in @('accepted', 'running') -and [DateTime]::UtcNow -lt $terminalDeadline)
if ($terminalStatus.actionStatus.state -ne 'completed') {
    throw "Unicode terminal proof action did not complete: $($terminalStatus.actionStatus.state)"
}
$terminalStatusRecord = $terminalStatus.actionStatus
$terminalStatusCanonical = "rcc-status|$($terminalStatusRecord.nonce)|$($terminalStatusRecord.action)|$($terminalStatusRecord.requestHash)|$($terminalStatusRecord.state)|$($terminalStatusRecord.exitCode)|$($terminalStatusRecord.updatedUtc)|$($terminalStatusRecord.message)"
if ($terminalStatusRecord.signature -ne (Get-Signature -Text $terminalStatusCanonical -Key $sharedKey)) {
    throw 'Unicode terminal proof status HMAC did not verify.'
}
$terminalRequest = $terminalBody | ConvertFrom-Json
$expectedTerminalHash = Get-RccRequestFingerprint -Command $terminalRequest
if ($terminalStatusRecord.action -cne 'terminal_line' -or $terminalStatusRecord.requestHash -cne $expectedTerminalHash) {
    throw 'Signed terminal status retained the command payload or failed to bind its request hash.'
}
$terminalRunRoot = Join-Path $stateDir 'terminal-runs'
if (Test-Path -LiteralPath $terminalRunRoot -PathType Container) {
    $proofArtifacts = @(Get-ChildItem -LiteralPath $terminalRunRoot -Force)
    if ($proofArtifacts.Count -ne 0) { throw 'Proof-only terminal handling persisted command, bootstrap, result, or runner artifacts.' }
}
$roundTrippedCommand = ConvertFrom-RccBase64Url -Text $terminalEncoded
if ($roundTrippedCommand -cne $terminalCommand) { throw 'UTF-8 terminal input did not round-trip through the strict protocol decoder.' }

$powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$runnerFile = Join-Path $projectRoot 'scripts\Invoke-RemoteCommandCenterTerminalRunner.ps1'
if (-not (Test-Path -LiteralPath $runnerFile -PathType Leaf)) { throw 'Checked-in terminal runner is missing.' }
$directRunnerRoot = Join-Path $sandbox 'terminal-runner-test'
New-Item -ItemType Directory -Force -Path $directRunnerRoot | Out-Null
$unicodeOutputPath = Join-Path $directRunnerRoot 'unicode-output.txt'
$escapedOutputPath = $unicodeOutputPath.Replace("'", "''")
$unicodeText = [char]0x05E9 + [char]0x05DC + [char]0x05D5 + [char]0x05DD + ' ' + [char]::ConvertFromUtf32(0x1F319)
$escapedUnicodeText = $unicodeText.Replace("'", "''")
$runnerCommand = "[System.IO.File]::WriteAllText('$escapedOutputPath', '$escapedUnicodeText', [Text.Encoding]::UTF8)"
$unicodeCommandPath = Join-Path $directRunnerRoot 'unicode-command.txt'
$unicodeResultPath = Join-Path $directRunnerRoot 'unicode-result.json'
$unicodeLogPath = Join-Path $directRunnerRoot 'unicode-runner.log'
$unicodeRunnerNonce = [guid]::NewGuid().ToString('N')
Set-Content -LiteralPath $unicodeCommandPath -Encoding UTF8 -NoNewline -Value $runnerCommand
$unicodeDeadline = [DateTimeOffset]::UtcNow.AddSeconds(30).ToString('o')
& $powershellPath -NoProfile -ExecutionPolicy Bypass -File $runnerFile -CommandFile $unicodeCommandPath -LogFile $unicodeLogPath -CompletionNonce $unicodeRunnerNonce -ResultFile $unicodeResultPath -ResultDeadlineUtc $unicodeDeadline
$runnerExitCode = $LASTEXITCODE
if ($runnerExitCode -ne 0) { throw "Isolated terminal runner exited with code $runnerExitCode." }
$runnerRecord = Get-Content -LiteralPath $unicodeResultPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($runnerRecord.type -ne 'rcc-terminal-result' -or $runnerRecord.nonce -ne $unicodeRunnerNonce -or $runnerRecord.state -ne 'completed' -or [int]$runnerRecord.exitCode -ne 0) {
    throw 'Isolated terminal runner did not publish a matching successful completion result.'
}
if (Test-Path -LiteralPath $unicodeCommandPath -PathType Leaf) { throw 'Terminal runner did not delete the command file before invocation.' }
$actualUnicodeText = Get-Content -LiteralPath $unicodeOutputPath -Raw -Encoding UTF8
if ($actualUnicodeText -cne $unicodeText) { throw 'The static runner did not execute the exact Unicode command text.' }
$runnerLogText = Get-Content -LiteralPath $unicodeLogPath -Raw -Encoding UTF8
if ($runnerLogText -notmatch 'COMMAND_RETURNED exitCode=0' -or $runnerLogText.Contains($runnerCommand) -or $runnerLogText.Contains($unicodeText)) {
    throw 'Terminal runner did not log safe, observable completion without command contents.'
}

$bootstrapCommandPath = Join-Path $directRunnerRoot 'bootstrap-command.txt'
$bootstrapFilePath = Join-Path $directRunnerRoot 'bootstrap.ps1'
$bootstrapOutputPath = Join-Path $directRunnerRoot 'bootstrap-output.txt'
$bootstrapResultPath = Join-Path $directRunnerRoot 'bootstrap-result.json'
$bootstrapLogPath = Join-Path $directRunnerRoot 'bootstrap-runner.log'
$bootstrapNonce = [guid]::NewGuid().ToString('N')
$escapedBootstrapOutputPath = $bootstrapOutputPath.Replace("'", "''")
Set-Content -LiteralPath $bootstrapFilePath -Encoding UTF8 -NoNewline -Value '$global:RccTerminalBootstrapProof = "bootstrap-ok"'
Set-Content -LiteralPath $bootstrapCommandPath -Encoding UTF8 -NoNewline -Value "[System.IO.File]::WriteAllText('$escapedBootstrapOutputPath', `$global:RccTerminalBootstrapProof, [Text.Encoding]::UTF8)"
$bootstrapDeadline = [DateTimeOffset]::UtcNow.AddSeconds(30).ToString('o')
& $powershellPath -NoProfile -ExecutionPolicy Bypass -File $runnerFile -CommandFile $bootstrapCommandPath -BootstrapFile $bootstrapFilePath -LogFile $bootstrapLogPath -CompletionNonce $bootstrapNonce -ResultFile $bootstrapResultPath -ResultDeadlineUtc $bootstrapDeadline
if ($LASTEXITCODE -ne 0) { throw 'Bootstrap terminal runner exited unexpectedly.' }
$bootstrapRecord = Get-Content -LiteralPath $bootstrapResultPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($bootstrapRecord.nonce -ne $bootstrapNonce -or $bootstrapRecord.state -ne 'completed' -or (Get-Content -LiteralPath $bootstrapOutputPath -Raw -Encoding UTF8) -cne 'bootstrap-ok') {
    throw 'The terminal runner did not load the bootstrap before executing the command.'
}
if ((Test-Path -LiteralPath $bootstrapCommandPath -PathType Leaf) -or (Test-Path -LiteralPath $bootstrapFilePath -PathType Leaf)) {
    throw 'The terminal runner retained command or bootstrap text after execution.'
}

$failedTerminalNonce = [guid]::NewGuid().ToString('N')
$failedCommandPath = Join-Path $directRunnerRoot 'controlled-failure-command.txt'
$failedResultPath = Join-Path $directRunnerRoot "result-$failedTerminalNonce.json"
$failedRunnerLogPath = Join-Path $directRunnerRoot 'controlled-failure-runner.log'
$failedCommandText = "throw 'controlled terminal runner failure'"
Set-Content -LiteralPath $failedCommandPath -Encoding UTF8 -NoNewline -Value $failedCommandText
$failedDeadline = [DateTimeOffset]::UtcNow.AddSeconds(30).ToString('o')
& $powershellPath -NoProfile -ExecutionPolicy Bypass -File $runnerFile -CommandFile $failedCommandPath -LogFile $failedRunnerLogPath -CompletionNonce $failedTerminalNonce -ResultFile $failedResultPath -ResultDeadlineUtc $failedDeadline
$failedRunnerExitCode = $LASTEXITCODE
if ($failedRunnerExitCode -ne 0) { throw "Controlled failure runner exited unexpectedly with code $failedRunnerExitCode." }
$failedRunnerRecord = Get-Content -LiteralPath $failedResultPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($failedRunnerRecord.nonce -ne $failedTerminalNonce -or $failedRunnerRecord.state -ne 'failed' -or [int]$failedRunnerRecord.exitCode -ne 1) {
    throw 'A PowerShell error was not reported as a failed terminal completion.'
}
if (Test-Path -LiteralPath $failedCommandPath -PathType Leaf) { throw 'Terminal runner retained a failed command file.' }
$failedRunnerLogText = Get-Content -LiteralPath $failedRunnerLogPath -Raw -Encoding UTF8
if ($failedRunnerLogText.Contains($failedCommandText) -or $failedRunnerLogText.Contains('controlled terminal runner failure')) {
    throw 'Terminal runner logs persisted the user command or raw error text.'
}

$expiredCommandPath = Join-Path $directRunnerRoot 'expired-deadline-command.txt'
$expiredResultPath = Join-Path $directRunnerRoot 'expired-deadline-result.json'
$expiredRunnerLogPath = Join-Path $directRunnerRoot 'expired-deadline-runner.log'
Set-Content -LiteralPath $expiredCommandPath -Encoding UTF8 -NoNewline -Value "Write-Output 'expired result deadline test'"
$expiredDeadline = [DateTimeOffset]::UtcNow.AddSeconds(-1).ToString('o')
& $powershellPath -NoProfile -ExecutionPolicy Bypass -File $runnerFile -CommandFile $expiredCommandPath -LogFile $expiredRunnerLogPath -CompletionNonce ([guid]::NewGuid().ToString('N')) -ResultFile $expiredResultPath -ResultDeadlineUtc $expiredDeadline
if ($LASTEXITCODE -ne 0) { throw 'Expired-deadline runner exited unexpectedly.' }
if ((Test-Path -LiteralPath $expiredResultPath -PathType Leaf) -or (Test-Path -LiteralPath $expiredCommandPath -PathType Leaf)) {
    throw 'Expired terminal runner left a late result marker or command file.'
}
if ((Get-Content -LiteralPath $expiredRunnerLogPath -Raw -Encoding UTF8) -notmatch 'RESULT_SUPPRESSED after-wait-deadline=True') {
    throw 'Expired terminal runner did not suppress its late completion marker.'
}

$failedDispatchNonce = [guid]::NewGuid().ToString('N')
$failedDispatchAction = "terminal_line:$terminalEncoded"
$failedDispatchCanonical = "rcc|$createdAt|$failedDispatchNonce|true|$failedDispatchAction|$confirm"
$failedDispatchBody = [ordered]@{
    type = 'rcc'; createdAt = $createdAt; nonce = $failedDispatchNonce; dryRun = $true
    action = $failedDispatchAction; confirm = $confirm
    signature = Get-Signature -Text $failedDispatchCanonical -Key $sharedKey
} | ConvertTo-Json -Compress
Set-Content -LiteralPath (Join-Path $stateDir 'test-force-terminal-dispatch-failure.flag') -Value 'test-only' -Encoding ASCII
$failedDispatch = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $failedDispatchBody
if ($failedDispatch.message -ne 'unconfirmed' -or $failedDispatch.actionStatus.state -ne 'unconfirmed') {
    throw 'A failed terminal launch was not reported as unconfirmed.'
}
$failedDispatchProof = Get-RccStatusQueryProof -Nonce $failedDispatchNonce -SharedKey $sharedKey
$failedDispatchUri = '{0}?nonce={1}&proof={2}' -f $statusUri, $failedDispatchNonce, $failedDispatchProof
$failedDispatchStatus = Invoke-RestMethod -Method Get -Uri $failedDispatchUri -TimeoutSec 2
$failedDispatchRecord = $failedDispatchStatus.actionStatus
$failedDispatchStatusCanonical = "rcc-status|$($failedDispatchRecord.nonce)|$($failedDispatchRecord.action)|$($failedDispatchRecord.requestHash)|$($failedDispatchRecord.state)|$($failedDispatchRecord.exitCode)|$($failedDispatchRecord.updatedUtc)|$($failedDispatchRecord.message)"
$failedDispatchRequest = $failedDispatchBody | ConvertFrom-Json
if ($failedDispatchRecord.action -cne 'terminal_line' -or $failedDispatchRecord.requestHash -cne (Get-RccRequestFingerprint -Command $failedDispatchRequest) -or $failedDispatchRecord.signature -ne (Get-Signature -Text $failedDispatchStatusCanonical -Key $sharedKey)) {
    throw 'Failed terminal dispatch status was not safely labeled, request-bound, and HMAC-signed.'
}
$failedDispatchDuplicate = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $failedDispatchBody
if (-not $failedDispatchDuplicate.duplicate -or $failedDispatchDuplicate.actionStatus.state -ne 'unconfirmed') {
    throw 'A failed terminal dispatch was not deduplicated against its recorded unconfirmed status.'
}
$queueFiles = @(Get-ChildItem -LiteralPath (Join-Path $stateDir 'local-queue') -Filter '*.json' -ErrorAction SilentlyContinue)
if ($queueFiles.Count -ne 0) { throw 'Failed terminal dispatch persisted the encoded command in the fallback queue.' }

$logText = (Get-ChildItem -LiteralPath $logDir -File | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 }) -join [Environment]::NewLine
if ($logText.Contains($terminalCommand) -or $logText.Contains($terminalEncoded) -or $logText -notmatch 'PROOF_ONLY active; fresh elevated terminal tab was not opened and command was not persisted or executed') {
    throw 'Proof-only terminal test either logged command contents or did not confirm it avoided persistence and execution.'
}
if ($logText -notmatch 'Terminal dispatch failed action=terminal_line .*command body was not persisted to the fallback queue') {
    throw 'Failed terminal dispatch did not record its payload-free fallback decision.'
}
$statusFiles = @(Get-ChildItem -LiteralPath (Join-Path $stateDir 'action-status') -Filter '*.json')
if ($statusFiles.Count -ne 4) { throw "Expected exactly four action status files, found $($statusFiles.Count)." }

Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/test-stop" -ContentType 'application/json' -Body '{}' | Out-Null
$process.WaitForExit(5000) | Out-Null
'REMOTE_COMMAND_CENTER_RECEIVER_INTEGRATION_TESTS_PASS'
