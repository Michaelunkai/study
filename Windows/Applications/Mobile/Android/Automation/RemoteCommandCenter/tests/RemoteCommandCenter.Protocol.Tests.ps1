$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts\RemoteCommandCenter.Protocol.ps1')

$config = [ordered]@{ SharedKey = 'protocol-test-key'; AllowedSkewSeconds = 120 }
$createdAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

function New-TestCommand {
    param([string]$Action = 'restart_codex', [string]$Nonce = ([guid]::NewGuid().ToString('N')), [long]$Time = $createdAt)
    $command = [ordered]@{
        type = 'rcc'
        createdAt = $Time
        nonce = $Nonce
        dryRun = $true
        action = $Action
        confirm = 'REMOTE_COMMAND_CENTER_EXECUTE'
        signature = ''
    }
    $command.signature = Get-RccHmacSignature -Text (Get-RccCommandCanonical -Command $command) -Key $config.SharedKey
    return [pscustomobject]$command
}

$valid = New-TestCommand
if (-not (Test-RccCommand -Command $valid -Config $config)) { throw 'A correctly signed, current command was rejected.' }

$badSignature = New-TestCommand
$badSignature.signature = 'invalid'
if (Test-RccCommand -Command $badSignature -Config $config) { throw 'A command with an invalid HMAC was accepted.' }

$expired = New-TestCommand -Time ($createdAt - 1000)
if (Test-RccCommand -Command $expired -Config $config) { throw 'An expired command was accepted.' }

$unknown = New-TestCommand -Action 'run_arbitrary_script'
if (Test-RccCommand -Command $unknown -Config $config) { throw 'A validly signed unknown action was accepted.' }

$badNonce = New-TestCommand -Nonce 'bad/nonce'
if (Test-RccCommand -Command $badNonce -Config $config) { throw 'A command with an unsafe nonce was accepted.' }

foreach ($volume in 0, 1, 99, 100) {
    if (-not (Test-RccAction -Action "tv_set_volume:$volume")) { throw "Valid volume boundary $volume was rejected." }
}
foreach ($volume in -1, 101, 999) {
    if (Test-RccAction -Action "tv_set_volume:$volume") { throw "Out-of-range volume $volume was accepted." }
}
if (-not (Test-RccAction -Action 'terminal_line:SGVsbG8')) { throw 'A valid bounded UTF-8 terminal payload was rejected.' }
if (-not (Test-RccAction -Action 'terminal_line:YQ')) { throw 'A valid one-character terminal command was rejected.' }
if (-not (Test-RccAction -Action 'terminal_line:bHM')) { throw 'A valid two-character terminal command was rejected.' }
$unicodeCommand = 'Write-Output "' + [char]0x05E9 + [char]0x05DC + [char]0x05D5 + [char]0x05DD + ' ' + [char]::ConvertFromUtf32(0x1F319) + '"'
$unicodePayload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($unicodeCommand)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
if (-not (Test-RccAction -Action ("terminal_line:$unicodePayload"))) { throw 'A valid Unicode UTF-8 terminal command was rejected.' }
if ((ConvertFrom-RccBase64Url -Text $unicodePayload) -cne $unicodeCommand) { throw 'Strict terminal decoding did not preserve Unicode input.' }
if (Test-RccAction -Action 'terminal_line:A') { throw 'An invalid one-character Base64URL payload was accepted.' }
if (Test-RccAction -Action 'terminal_line:AAAAA') { throw 'An invalid Base64URL length was accepted.' }
if (Test-RccAction -Action 'terminal_line:////') { throw 'Invalid UTF-8 terminal bytes were accepted.' }
foreach ($invalidPayload in 'A', '____') {
    $decodeRejected = $false
    try { ConvertFrom-RccBase64Url -Text $invalidPayload | Out-Null } catch { $decodeRejected = $true }
    if (-not $decodeRejected) { throw "Strict decoder accepted malformed terminal payload '$invalidPayload'." }
}
if (Test-RccAction -Action ('terminal_line:' + ('A' * 16385))) { throw 'An oversized terminal payload was accepted.' }
$oversizedUtf8Payload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('x' * 8193)).TrimEnd('=').Replace('+', '-').Replace('/', '_')
if (Test-RccAction -Action ("terminal_line:$oversizedUtf8Payload")) { throw 'A terminal command over the 8192-byte decoded limit was accepted.' }
$oversizeDecoderRejected = $false
try { ConvertFrom-RccBase64Url -Text $oversizedUtf8Payload | Out-Null } catch { $oversizeDecoderRejected = $true }
if (-not $oversizeDecoderRejected) { throw 'Strict decoder accepted a command over the 8192-byte UTF-8 limit.' }

$requestHash = Get-RccRequestFingerprint -Command $valid
$status = New-RccActionStatus -Nonce $valid.nonce -Action $valid.action -RequestHash $requestHash -State 'completed' -SharedKey $config.SharedKey -Message 'done'
$expectedStatusSignature = Get-RccHmacSignature -Text (Get-RccStatusCanonical -Record $status) -Key $config.SharedKey
if (-not (Test-RccFixedTimeText -Expected $expectedStatusSignature -Actual $status.signature)) { throw 'Signed action status did not verify.' }
$proof = Get-RccStatusQueryProof -Nonce $valid.nonce -SharedKey $config.SharedKey
if (-not (Test-RccStatusQueryProof -Nonce $valid.nonce -Proof $proof -SharedKey $config.SharedKey)) { throw 'Valid status-query proof was rejected.' }
if (Test-RccStatusQueryProof -Nonce $valid.nonce -Proof 'wrong-proof' -SharedKey $config.SharedKey) { throw 'Invalid status-query proof was accepted.' }
$terminalForStatus = New-TestCommand -Action ("terminal_line:$unicodePayload")
$terminalStatus = New-RccActionStatus -Nonce $terminalForStatus.nonce -Action $terminalForStatus.action -RequestHash (Get-RccRequestFingerprint -Command $terminalForStatus) -State 'accepted' -SharedKey $config.SharedKey
if ($terminalStatus.action -cne 'terminal_line' -or $terminalStatus.requestHash -ne (Get-RccRequestFingerprint -Command $terminalForStatus)) {
    throw 'Terminal status must identify the action class without retaining its encoded command.'
}

$tempDir = Join-Path $env:TEMP ('rcc-protocol-test-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    $statusPath = Join-Path $tempDir ($valid.nonce + '.json')
    Write-RccActionStatusFile -Path $statusPath -Record $status | Out-Null
    $first = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
    if ($first.signature -ne $status.signature -or $first.requestHash -ne $requestHash) { throw 'Atomic status write lost signed fields.' }
    $updated = New-RccActionStatus -Nonce $valid.nonce -Action $valid.action -RequestHash $requestHash -State 'failed' -ExitCode 7 -SharedKey $config.SharedKey -Message 'failed'
    Write-RccActionStatusFile -Path $statusPath -Record $updated | Out-Null
    $second = Get-Content -LiteralPath $statusPath -Raw | ConvertFrom-Json
    if ($second.state -ne 'failed' -or $second.exitCode -ne 7) { throw 'Atomic status replacement failed.' }
} finally {
    if (Test-Path -LiteralPath $tempDir) { Remove-Item -LiteralPath $tempDir -Recurse -Force }
}

'REMOTE_COMMAND_CENTER_PROTOCOL_TESTS_PASS'
