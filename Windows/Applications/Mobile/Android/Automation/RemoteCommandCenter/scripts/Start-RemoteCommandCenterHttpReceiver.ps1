param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [int]$Port = 8777,
    [string]$ListenHost = '+',
    [string]$MutexName = 'Global\RemoteCommandCenterHttpReceiver',
    [switch]$TestMode
)

$ErrorActionPreference = 'Continue'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.StateDir, $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'http-listener.log'
$queueDir = Join-Path $config.StateDir 'local-queue'
$actionStatusDir = Join-Path $config.StateDir 'action-status'
New-Item -ItemType Directory -Force -Path $queueDir, $actionStatusDir | Out-Null
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, $MutexName, [ref]$createdNew)
if (-not $createdNew) {
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] HTTP receiver duplicate ignored." -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'))
    exit 0
}

function Write-HttpLog { param([string]$Message) Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message) }
function ConvertTo-Base64Url { param([byte[]]$Bytes) [Convert]::ToBase64String($Bytes).TrimEnd('=').Replace('+','-').Replace('/','_') }
function Get-HmacSignature {
    param([string]$Text,[string]$Key)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = [Text.Encoding]::UTF8.GetBytes($Key)
    ConvertTo-Base64Url $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))
}
function Test-Command {
    param($Command)
    if ($Command.type -ne 'rcc') { return $false }
    if ([string]$Command.confirm -ne 'REMOTE_COMMAND_CENTER_EXECUTE') { return $false }
    $createdAt = [int64]$Command.createdAt
    if ([Math]::Abs(([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $createdAt)) -gt [int]$config.AllowedSkewSeconds) { return $false }
    $dryText = ([string]$Command.dryRun).ToLowerInvariant()
    $canonical = "rcc|$($Command.createdAt)|$($Command.nonce)|$dryText|$($Command.action)|$($Command.confirm)"
    (Get-HmacSignature -Text $canonical -Key $config.SharedKey) -eq [string]$Command.signature
}
function Get-ActionStatusPath {
    param([string]$Nonce)
    $safeNonce = $Nonce -replace '[^A-Za-z0-9_-]', '_'
    Join-Path $actionStatusDir "$safeNonce.json"
}
function Get-DispatchClaimPath {
    param([string]$Nonce)
    $safeNonce = $Nonce -replace '[^A-Za-z0-9_-]', '_'
    Join-Path $actionStatusDir "$safeNonce.dispatch"
}
function Claim-ActionDispatch {
    param([string]$Nonce)
    $path = Get-DispatchClaimPath -Nonce $Nonce
    try {
        $stream = [IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        $stream.Dispose()
        return $path
    } catch [IO.IOException] {
        return $null
    }
}
function Read-ActionStatus {
    param([string]$Nonce)
    if ([string]::IsNullOrWhiteSpace($Nonce)) { return $null }
    $path = Get-ActionStatusPath -Nonce $Nonce
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { return Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } catch { return $null }
}
function New-AcceptedActionStatus {
    param($Command)
    $path = Get-ActionStatusPath -Nonce ([string]$Command.nonce)
    $record = [ordered]@{
        ok = $true
        nonce = [string]$Command.nonce
        action = [string]$Command.action
        state = 'accepted'
        exitCode = 0
        message = 'accepted'
        updatedUtc = [DateTimeOffset]::UtcNow.ToString('o')
    }
    $json = $record | ConvertTo-Json -Compress
    try {
        $stream = [IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        try {
            $bytes = [Text.Encoding]::UTF8.GetBytes($json)
            $stream.Write($bytes, 0, $bytes.Length)
        } finally {
            $stream.Dispose()
        }
        return $record
    } catch [IO.IOException] {
        return $null
    }
}
function Invoke-CommandBody {
    param([string]$Body)
    $command = $Body | ConvertFrom-Json
    if (-not (Test-Command -Command $command)) { return @{ ok=$false; message='rejected' } }
    $existing = Read-ActionStatus -Nonce ([string]$command.nonce)
    if ($existing) {
        Write-HttpLog "Duplicate command ignored action=$($command.action) nonce=$($command.nonce) state=$($existing.state)"
        return @{
            ok = $true
            message = 'duplicate'
            duplicate = $true
            nonce = [string]$command.nonce
            actionStatus = $existing
        }
    }
    $accepted = New-AcceptedActionStatus -Command $command
    if (-not $accepted) {
        $existing = Read-ActionStatus -Nonce ([string]$command.nonce)
        return @{
            ok = $true
            message = 'duplicate'
            duplicate = $true
            nonce = [string]$command.nonce
            actionStatus = $existing
        }
    }
    $dispatchClaim = Claim-ActionDispatch -Nonce ([string]$command.nonce)
    if (-not $dispatchClaim) {
        $existing = Read-ActionStatus -Nonce ([string]$command.nonce)
        return @{
            ok = $true
            message = 'duplicate'
            duplicate = $true
            nonce = [string]$command.nonce
            actionStatus = $existing
        }
    }
    $invoke = Join-Path $PSScriptRoot 'Invoke-RemoteCommandCenterTrackedAction.ps1'
    $args = @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        $invoke,
        '-Action',
        [string]$command.action,
        '-Nonce',
        [string]$command.nonce,
        '-ConfigPath',
        $ConfigPath
    )
    if ([bool]$command.dryRun) { $args += '-ProofOnly' }
    try {
        Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $args -WindowStyle Hidden | Out-Null
        Write-HttpLog "Started command immediately action=$($command.action) nonce=$($command.nonce)"
        return @{ ok=$true; message='started'; nonce=[string]$command.nonce; actionStatus=$accepted }
    } catch {
        # ALLOW_DESTRUCTIVE: this removes only the failed zero-byte dispatch
        # claim so the fallback queue can safely acquire it.
        Remove-Item -LiteralPath $dispatchClaim -Force -ErrorAction SilentlyContinue
        Write-HttpLog "Immediate command start failed action=$($command.action) nonce=$($command.nonce) error=$($_.Exception.Message); queueing fallback"
    }
    $safeNonce = ([string]$command.nonce -replace '[^A-Za-z0-9_-]', '_')
    $path = Join-Path $queueDir ("{0}-{1}.json" -f ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()), $safeNonce)
    Set-Content -LiteralPath $path -Encoding UTF8 -Value $Body
    & "$env:SystemRoot\System32\schtasks.exe" /Run /TN 'RemoteCommandCenterAgentKick' 2>$null | Out-Null
    & "$env:SystemRoot\System32\schtasks.exe" /Run /TN 'RemoteCommandCenterAgentLogon' 2>$null | Out-Null
    Write-HttpLog "Queued command action=$($command.action) nonce=$($command.nonce) path=$path"
    @{ ok=$true; message='queued'; nonce=[string]$command.nonce; actionStatus=$accepted }
}
function Get-StatusBody {
    param([string]$Nonce)
    $body = [ordered]@{
        ok = $true
        state = 'ready'
        machine = $env:COMPUTERNAME
        utc = [DateTimeOffset]::UtcNow.ToString('o')
    }
    if (-not [string]::IsNullOrWhiteSpace($Nonce)) {
        $body.actionStatus = Read-ActionStatus -Nonce $Nonce
    }
    $body | ConvertTo-Json -Depth 6 -Compress
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://$ListenHost`:$Port/rcc/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-HttpLog "HTTP receiver started prefix=$prefix"
while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $response = $context.Response
        $response.ContentType = 'application/json; charset=utf-8'
        $path = $context.Request.Url.AbsolutePath
        $method = $context.Request.HttpMethod
        $stopAfterResponse = $false
        if ($path -eq '/rcc/status' -and $method -in @('GET','POST')) {
            $response.StatusCode = 200
            $out = Get-StatusBody -Nonce ([string]$context.Request.QueryString['nonce'])
        } elseif ($method -eq 'POST' -and $path -eq '/rcc/action') {
            $reader = New-Object IO.StreamReader($context.Request.InputStream, [Text.Encoding]::UTF8)
            $result = Invoke-CommandBody -Body $reader.ReadToEnd()
            $response.StatusCode = if ($result.ok) { 202 } else { 403 }
            $out = $result | ConvertTo-Json -Compress
        } elseif ($TestMode -and $method -eq 'POST' -and $path -eq '/rcc/test-stop') {
            $response.StatusCode = 200
            $out = '{"ok":true,"message":"test receiver stopping"}'
            $stopAfterResponse = $true
        } else {
            $response.StatusCode = 404
            $out = '{"ok":false,"message":"not found"}'
        }
        $bytes = [Text.Encoding]::UTF8.GetBytes($out)
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.OutputStream.Close()
        if ($stopAfterResponse) { $listener.Stop() }
    } catch {
        Write-HttpLog "Listener failed: $($_.Exception.Message)"
        Start-Sleep -Milliseconds 250
    }
}
try { $mutex.ReleaseMutex() | Out-Null } catch {}
$mutex.Dispose()
