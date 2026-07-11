param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [switch]$Once,
    [int]$IdleSeconds = 1
)

$ErrorActionPreference = 'Continue'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path $config.StateDir, $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'agent.log'
$actionStatusDir = Join-Path $config.StateDir 'action-status'
New-Item -ItemType Directory -Force -Path $actionStatusDir | Out-Null
$relayStartedAt = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Global\RemoteCommandCenterAgent', [ref]$createdNew)
if (-not $createdNew) {
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] Agent duplicate ignored." -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'))
    exit 0
}

function Write-AgentLog { param([string]$Message) Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message) }

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
    $createdAt = [int64]$Command.createdAt
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ([Math]::Abs($now - $createdAt) -gt [int]$config.AllowedSkewSeconds) { return $false }
    if ([string]$Command.confirm -ne 'REMOTE_COMMAND_CENTER_EXECUTE') { return $false }
    $dryText = ([string]$Command.dryRun).ToLowerInvariant()
    $canonical = "rcc|$($Command.createdAt)|$($Command.nonce)|$dryText|$($Command.action)|$($Command.confirm)"
    (Get-HmacSignature -Text $canonical -Key $config.SharedKey) -eq [string]$Command.signature
}

function Get-NoncePath {
    param([string]$Nonce, [string]$Extension)
    $safeNonce = $Nonce -replace '[^A-Za-z0-9_-]', '_'
    Join-Path $actionStatusDir "$safeNonce.$Extension"
}

function Read-ActionStatus {
    param([string]$Nonce)
    $path = Get-NoncePath -Nonce $Nonce -Extension 'json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } catch { $null }
}

function New-AcceptedActionStatus {
    param($Command)
    $path = Get-NoncePath -Nonce ([string]$Command.nonce) -Extension 'json'
    $record = [ordered]@{
        ok = $true
        nonce = [string]$Command.nonce
        action = [string]$Command.action
        state = 'accepted'
        exitCode = 0
        message = 'accepted'
        updatedUtc = [DateTimeOffset]::UtcNow.ToString('o')
    }
    try {
        $stream = [IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        try {
            $bytes = [Text.Encoding]::UTF8.GetBytes(($record | ConvertTo-Json -Compress))
            $stream.Write($bytes, 0, $bytes.Length)
        } finally {
            $stream.Dispose()
        }
        return $record
    } catch [IO.IOException] {
        return $null
    }
}

function Claim-ActionDispatch {
    param([string]$Nonce)
    $path = Get-NoncePath -Nonce $Nonce -Extension 'dispatch'
    try {
        $stream = [IO.File]::Open($path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
        $stream.Dispose()
        return $path
    } catch [IO.IOException] {
        return $null
    }
}

function Handle-CommandJson {
    param([string]$Body)
    $command = $Body | ConvertFrom-Json
    if (-not (Test-Command -Command $command)) { Write-AgentLog 'Rejected command'; return $false }
    $nonce = [string]$command.nonce
    $status = Read-ActionStatus -Nonce $nonce
    if (-not $status) {
        $status = New-AcceptedActionStatus -Command $command
        if (-not $status) { $status = Read-ActionStatus -Nonce $nonce }
    }
    if (-not $status -or [string]$status.action -ne [string]$command.action) {
        Write-AgentLog "Rejected nonce collision action=$($command.action) nonce=$nonce"
        return $false
    }
    if ([string]$status.state -notin @('accepted')) { return $false }
    $dispatchClaim = Claim-ActionDispatch -Nonce $nonce
    if (-not $dispatchClaim) { return $false }
    $invoke = Join-Path $PSScriptRoot 'Invoke-RemoteCommandCenterTrackedAction.ps1'
    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$invoke,'-Action',[string]$command.action,'-Nonce',$nonce,'-ConfigPath',$ConfigPath)
    if ([bool]$command.dryRun) { $args += '-ProofOnly' }
    try {
        Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $args -WindowStyle Hidden | Out-Null
        Write-AgentLog "Accepted command action=$($command.action) nonce=$nonce"
        return $true
    } catch {
        # ALLOW_DESTRUCTIVE: this removes only the failed, zero-byte dispatch
        # claim under StateDir so the durable queued command can retry.
        Remove-Item -LiteralPath $dispatchClaim -Force -ErrorAction SilentlyContinue
        Write-AgentLog "Command dispatch failed action=$($command.action) nonce=$nonce error=$($_.Exception.Message)"
        return $false
    }
}

function Handle-LocalQueue {
    $queueDir = Join-Path $config.StateDir 'local-queue'
    New-Item -ItemType Directory -Force -Path $queueDir | Out-Null
    $file = Get-ChildItem -LiteralPath $queueDir -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -First 1
    if (-not $file) { return $false }
    $body = Get-Content -LiteralPath $file.FullName -Raw
    $handled = Handle-CommandJson -Body $body
    if ($handled) {
        # ALLOW_DESTRUCTIVE: delete only this verified project queue file after
        # its tracked action process has been successfully started.
        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
    }
    return $handled
}

function Handle-RelayPoll {
    $topic = [string]$config.CommandTopic
    foreach ($base in @($config.RelayBases)) {
        $url = ('{0}/{1}/json?poll=1&since={2}' -f ([string]$base).TrimEnd('/'), $topic, $relayStartedAt)
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
            $content = $response.Content
            if ($content -is [byte[]]) {
                $content = [Text.Encoding]::UTF8.GetString($content)
            }
            $lines = @([string]$content -split "`r?`n" | Where-Object { $_.Trim() })
            foreach ($line in $lines) {
                try {
                    $event = $line | ConvertFrom-Json
                    if ([string]$event.event -ne 'message') { continue }
                    if ([int64]$event.time -lt $relayStartedAt) { continue }
                    if ([string]::IsNullOrWhiteSpace([string]$event.message)) { continue }
                    if (Handle-CommandJson -Body ([string]$event.message)) { return $true }
                } catch {
                    Write-AgentLog "Relay message parse failed base=$base error=$($_.Exception.Message)"
                }
            }
        } catch {
            Write-AgentLog "Relay poll failed base=$base error=$($_.Exception.Message)"
        }
    }
    return $false
}

Write-AgentLog "Agent started topic=$($config.CommandTopic)"
do {
    $handled = Handle-LocalQueue
    if (-not $handled) { $handled = Handle-RelayPoll }
    if ($Once) { break }
    if (-not $handled) { Start-Sleep -Seconds $IdleSeconds }
} while ($true)
Write-AgentLog 'Agent stopped'
try { $mutex.ReleaseMutex() | Out-Null } catch {}
$mutex.Dispose()
