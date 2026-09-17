param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [int]$Port = 8777,
    [string]$ListenHost = '+',
    [string]$MutexName = 'Global\RemoteCommandCenterHttpReceiver',
    [switch]$TestMode
)

$ErrorActionPreference = 'Continue'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
. (Join-Path $PSScriptRoot 'RemoteCommandCenter.Protocol.ps1')
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
function Test-Command {
    param($Command)
    Test-RccCommand -Command $Command -Config $config
}
function Read-BoundedRequestBody {
    param([IO.Stream]$Stream, [int]$MaximumBytes = 65536)
    $memory = New-Object IO.MemoryStream
    try {
        [byte[]]$buffer = New-Object byte[] 8192
        while (($read = $Stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if (($memory.Length + $read) -gt $MaximumBytes) {
                return [pscustomobject]@{ TooLarge = $true; Body = $null }
            }
            $memory.Write($buffer, 0, $read)
        }
        return [pscustomobject]@{
            TooLarge = $false
            Body = [Text.Encoding]::UTF8.GetString($memory.ToArray())
        }
    } finally {
        $memory.Dispose()
    }
}
function Get-ActionStatusPath {
    param([string]$Nonce)
    Join-Path $actionStatusDir "$Nonce.json"
}
function Get-DispatchClaimPath {
    param([string]$Nonce)
    Join-Path $actionStatusDir "$Nonce.dispatch"
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
    param($Command, [string]$RequestHash)
    $path = Get-ActionStatusPath -Nonce ([string]$Command.nonce)
    $record = New-RccActionStatus -Nonce ([string]$Command.nonce) -Action ([string]$Command.action) -RequestHash $RequestHash -State 'accepted' -SharedKey ([string]$config.SharedKey) -Message 'accepted'
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
    try { $command = $Body | ConvertFrom-Json -ErrorAction Stop } catch { return @{ ok=$false; badRequest=$true; message='invalid_json' } }
    if (-not (Test-Command -Command $command)) { return @{ ok=$false; message='rejected' } }
    $requestHash = Get-RccRequestFingerprint -Command $command
    $statusAction = Get-RccStatusAction -Action ([string]$command.action)
    $existing = Read-ActionStatus -Nonce ([string]$command.nonce)
    $accepted = $existing
    if ($existing) {
        if ([string]$existing.action -cne $statusAction -or [string]$existing.requestHash -cne $requestHash) {
            Write-HttpLog "Rejected nonce collision action=$statusAction nonce=$($command.nonce)"
            return @{ ok=$false; conflict=$true; message='nonce_conflict'; nonce=[string]$command.nonce }
        }
        $dispatchClaimPath = Get-DispatchClaimPath -Nonce ([string]$command.nonce)
        if ([string]$existing.state -cne 'accepted' -or (Test-Path -LiteralPath $dispatchClaimPath -PathType Leaf)) {
            Write-HttpLog "Duplicate command ignored action=$statusAction nonce=$($command.nonce) state=$($existing.state)"
            return @{
                ok = $true
                message = 'duplicate'
                duplicate = $true
                nonce = [string]$command.nonce
                actionStatus = $existing
            }
        }
        Write-HttpLog "Recovering accepted command without dispatch claim action=$statusAction nonce=$($command.nonce)"
    } else {
        $accepted = New-AcceptedActionStatus -Command $command -RequestHash $requestHash
        if (-not $accepted) {
            $existing = Read-ActionStatus -Nonce ([string]$command.nonce)
            if ($existing -and ([string]$existing.action -cne $statusAction -or [string]$existing.requestHash -cne $requestHash)) {
                return @{ ok=$false; conflict=$true; message='nonce_conflict'; nonce=[string]$command.nonce }
            }
            if (-not $existing -or [string]$existing.state -cne 'accepted' -or
                (Test-Path -LiteralPath (Get-DispatchClaimPath -Nonce ([string]$command.nonce)) -PathType Leaf)) {
                return @{
                    ok = $true
                    message = 'duplicate'
                    duplicate = $true
                    nonce = [string]$command.nonce
                    actionStatus = $existing
                }
            }
            $accepted = $existing
            Write-HttpLog "Recovering concurrent accepted command without dispatch claim action=$statusAction nonce=$($command.nonce)"
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
        $ConfigPath,
        '-RequestHash',
        $requestHash
    )
    if ([bool]$command.dryRun) { $args += '-ProofOnly' }
    try {
        $forceTerminalDispatchFailure = Join-Path $config.StateDir 'test-force-terminal-dispatch-failure.flag'
        if ($TestMode -and $statusAction -ceq 'terminal_line' -and (Test-Path -LiteralPath $forceTerminalDispatchFailure -PathType Leaf)) {
            Remove-Item -LiteralPath $forceTerminalDispatchFailure -Force -ErrorAction SilentlyContinue
            throw 'Forced isolated terminal dispatch failure.'
        }
        Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $args -WindowStyle Hidden | Out-Null
        Write-HttpLog "Started command immediately action=$statusAction nonce=$($command.nonce)"
        return @{ ok=$true; message='started'; nonce=[string]$command.nonce; actionStatus=$accepted }
    } catch {
        # ALLOW_DESTRUCTIVE: this removes only the failed zero-byte dispatch
        # claim so the fallback queue can safely acquire it.
        Remove-Item -LiteralPath $dispatchClaim -Force -ErrorAction SilentlyContinue
        if ($statusAction -ceq 'terminal_line') {
            Write-HttpLog "Terminal dispatch failed action=terminal_line nonce=$($command.nonce); command body was not persisted to the fallback queue."
            $unconfirmed = New-RccActionStatus -Nonce ([string]$command.nonce) -Action ([string]$command.action) -RequestHash $requestHash -State 'unconfirmed' -SharedKey ([string]$config.SharedKey) -ExitCode 124 -Message 'Terminal dispatch failed; execution is unconfirmed and the request body was not persisted to the fallback queue.'
            Write-RccActionStatusFile -Path (Get-ActionStatusPath -Nonce ([string]$command.nonce)) -Record $unconfirmed | Out-Null
            Publish-RccActionStatus -Record $unconfirmed -Config $config | Out-Null
            return @{ ok=$true; message='unconfirmed'; nonce=[string]$command.nonce; actionStatus=$unconfirmed }
        }
        Write-HttpLog "Immediate command start failed action=$statusAction nonce=$($command.nonce) error=$($_.Exception.Message); queueing fallback"
    }
    $safeNonce = ([string]$command.nonce -replace '[^A-Za-z0-9_-]', '_')
    $path = Join-Path $queueDir ("{0}-{1}.json" -f ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()), $safeNonce)
    Set-Content -LiteralPath $path -Encoding UTF8 -Value $Body
    & "$env:SystemRoot\System32\schtasks.exe" /Run /TN 'RemoteCommandCenterAgentKick' 2>$null | Out-Null
    & "$env:SystemRoot\System32\schtasks.exe" /Run /TN 'RemoteCommandCenterAgentLogon' 2>$null | Out-Null
    Write-HttpLog "Queued command action=$statusAction nonce=$($command.nonce) path=$path"
    @{ ok=$true; message='queued'; nonce=[string]$command.nonce; actionStatus=$accepted }
}
function Get-StatusBody {
    param([string]$Nonce, [string]$Proof)
    if (-not [string]::IsNullOrWhiteSpace($Nonce) -and -not (Test-RccStatusQueryProof -Nonce $Nonce -Proof $Proof -SharedKey ([string]$config.SharedKey))) {
        return [ordered]@{ __forbidden = $true }
    }
    $body = [ordered]@{
        ok = $true
        state = 'ready'
    }
    if (-not [string]::IsNullOrWhiteSpace($Nonce)) {
        $body.actionStatus = Read-ActionStatus -Nonce $Nonce
    }
    return $body
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
            $statusBody = Get-StatusBody -Nonce ([string]$context.Request.QueryString['nonce']) -Proof ([string]$context.Request.QueryString['proof'])
            if ($statusBody.__forbidden) {
                $response.StatusCode = 403
                $out = '{"ok":false,"state":"forbidden"}'
            } else {
                $response.StatusCode = 200
                $out = $statusBody | ConvertTo-Json -Depth 6 -Compress
            }
        } elseif ($method -eq 'POST' -and $path -eq '/rcc/action') {
            if ($context.Request.ContentLength64 -gt 65536) {
                $response.StatusCode = 413
                $out = '{"ok":false,"message":"request_too_large"}'
            } else {
                $bodyRead = Read-BoundedRequestBody -Stream $context.Request.InputStream -MaximumBytes 65536
                if ($bodyRead.TooLarge) {
                    $response.StatusCode = 413
                    $out = '{"ok":false,"message":"request_too_large"}'
                } else {
                    $result = Invoke-CommandBody -Body $bodyRead.Body
                    $response.StatusCode = if ($result.badRequest) { 400 } elseif ($result.conflict) { 409 } elseif ($result.ok) { 202 } else { 403 }
                    $out = $result | ConvertTo-Json -Compress
                }
            }
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
