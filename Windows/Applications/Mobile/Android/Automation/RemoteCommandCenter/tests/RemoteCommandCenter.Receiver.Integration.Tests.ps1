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

$first = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $body
$second = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/action" -ContentType 'application/json' -Body $body
if (-not $first.ok -or $first.message -ne 'started') { throw 'First action was not started.' }
if (-not $second.ok -or -not $second.duplicate -or $second.message -ne 'duplicate') {
    throw 'Second action with the same nonce was not deduplicated.'
}

$deadline = [DateTime]::UtcNow.AddSeconds(30)
do {
    Start-Sleep -Milliseconds 150
    $status = Invoke-RestMethod -Method Get -Uri "$statusUri`?nonce=$nonce" -TimeoutSec 2
} while ($status.actionStatus.state -in @('accepted', 'running') -and [DateTime]::UtcNow -lt $deadline)

if ($status.actionStatus.state -ne 'completed') {
    throw "Tracked action did not complete successfully. state=$($status.actionStatus.state) message=$($status.actionStatus.message)"
}
$statusFiles = @(Get-ChildItem -LiteralPath (Join-Path $stateDir 'action-status') -Filter '*.json')
if ($statusFiles.Count -ne 1) { throw "Expected exactly one action status file, found $($statusFiles.Count)." }

Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$port/rcc/test-stop" -ContentType 'application/json' -Body '{}' | Out-Null
$process.WaitForExit(5000) | Out-Null
'REMOTE_COMMAND_CENTER_RECEIVER_INTEGRATION_TESTS_PASS'
