param(
    [string]$ConfigPath = "$PSScriptRoot\rcc-config.json",
    [switch]$Once,
    [int]$IdleSeconds = 1,
    [switch]$TestMode
)

$ErrorActionPreference = 'Continue'
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
. (Join-Path $PSScriptRoot 'RemoteCommandCenter.Protocol.ps1')
New-Item -ItemType Directory -Force -Path $config.StateDir, $config.LogDir | Out-Null
$log = Join-Path $config.LogDir 'agent.log'
$actionStatusDir = Join-Path $config.StateDir 'action-status'
$relayCursorDir = Join-Path $config.StateDir 'relay-cursors'
New-Item -ItemType Directory -Force -Path $actionStatusDir | Out-Null
$null = New-Item -ItemType Directory -Force -Path $relayCursorDir
$script:relayCursors = @{}
$script:relayBaselines = @{}
$createdNew = $false
$mutexName = if ($TestMode) {
    "Local\RemoteCommandCenterAgentTest_$([guid]::NewGuid().ToString('N'))"
} else {
    'Global\RemoteCommandCenterAgent'
}
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$createdNew)
if (-not $createdNew) {
    Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] Agent duplicate ignored." -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'))
    exit 0
}

function Write-AgentLog { param([string]$Message) Add-Content -LiteralPath $log -Encoding UTF8 -Value ("[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'), $Message) }

function Get-RelayBaseInfo {
    param([Parameter(Mandatory = $true)][string]$Base)
    $normalizedBase = $Base.Trim().TrimEnd('/')
    if ([string]::IsNullOrWhiteSpace($normalizedBase)) { throw 'Relay base is empty.' }
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalizedBase))
    } finally {
        $sha.Dispose()
    }
    $hash = ([BitConverter]::ToString($hashBytes)).Replace('-', '').ToLowerInvariant()
    return [pscustomobject]@{
        Base = $normalizedBase
        Hash = $hash
        Path = (Join-Path $relayCursorDir ($hash + '.json'))
    }
}

function Test-RelayCursorValue {
    param([string]$Cursor)
    return (-not [string]::IsNullOrWhiteSpace($Cursor)) -and
        $Cursor.Length -le 2048 -and
        ($Cursor -notmatch '[\x00-\x1f\x7f]')
}

function Write-RelayCursor {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$BaseHash,
        [Parameter(Mandatory = $true)][string]$Cursor,
        [Parameter(Mandatory = $true)][long]$BaselineTime
    )
    if (-not (Test-RelayCursorValue -Cursor $Cursor) -or $BaselineTime -lt 0) { throw 'Relay cursor value is invalid.' }
    $record = [ordered]@{ version = 1; baseHash = $BaseHash; cursor = $Cursor; baselineTime = $BaselineTime }
    $json = $record | ConvertTo-Json -Compress
    $tempPath = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    $backupPath = "$tempPath.bak"
    try {
        [IO.File]::WriteAllText($tempPath, $json, (New-Object Text.UTF8Encoding($false)))
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            [IO.File]::Replace($tempPath, $Path, $backupPath)
        } else {
            [IO.File]::Move($tempPath, $Path)
        }
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
            Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
        }
    } finally {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) {
            Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) {
            Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue
        }
    }
}

function Read-RelayCursor {
    param([Parameter(Mandatory = $true)]$RelayBaseInfo)
    $path = [string]$RelayBaseInfo.Path
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $baselineTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $baseline = $baselineTime.ToString([Globalization.CultureInfo]::InvariantCulture)
        Write-RelayCursor -Path $path -BaseHash ([string]$RelayBaseInfo.Hash) -Cursor $baseline -BaselineTime $baselineTime
        return [pscustomobject]@{ Cursor = $baseline; BaselineTime = $baselineTime }
    }
    try {
        $raw = [IO.File]::ReadAllText($path)
        if ($raw.Length -gt 4096) { throw 'oversize' }
        $record = $raw | ConvertFrom-Json -ErrorAction Stop
        $cursor = [string]$record.cursor
        $baselineTime = 0L
        if ([int]$record.version -ne 1 -or [string]$record.baseHash -cne [string]$RelayBaseInfo.Hash -or
            -not (Test-RelayCursorValue -Cursor $cursor) -or
            -not [long]::TryParse([string]$record.baselineTime, [Globalization.NumberStyles]::Integer,
                [Globalization.CultureInfo]::InvariantCulture, [ref]$baselineTime) -or $baselineTime -lt 0) {
            throw 'invalid record'
        }
        return [pscustomobject]@{ Cursor = $cursor; BaselineTime = $baselineTime }
    } catch {
        throw 'Relay cursor state is corrupt; refusing to poll.'
    }
}

function Get-RelayEventCursor {
    param($Event)
    $eventId = [string]$Event.id
    if (Test-RelayCursorValue -Cursor $eventId) { return $eventId }
    $eventTime = 0L
    if ([long]::TryParse([string]$Event.time, [Globalization.NumberStyles]::Integer,
            [Globalization.CultureInfo]::InvariantCulture, [ref]$eventTime) -and $eventTime -ge 0) {
        return $eventTime.ToString([Globalization.CultureInfo]::InvariantCulture)
    }
    return $null
}

function Commit-RelayCursor {
    param([Parameter(Mandatory = $true)][string]$Base, [Parameter(Mandatory = $true)][string]$Cursor)
    $info = Get-RelayBaseInfo -Base $Base
    $baselineTime = [long]$script:relayBaselines[[string]$info.Base]
    Write-RelayCursor -Path ([string]$info.Path) -BaseHash ([string]$info.Hash) -Cursor $Cursor -BaselineTime $baselineTime
    $script:relayCursors[[string]$info.Base] = $Cursor
}

function Invoke-TestCrashIfRequested {
    param([Parameter(Mandatory = $true)][ValidateSet('after-accepted', 'after-dispatch')][string]$Point)
    if (-not $TestMode) { return }
    $marker = Join-Path $config.StateDir ("test-agent-crash-{0}.flag" -f $Point)
    if (Test-Path -LiteralPath $marker -PathType Leaf) {
        Remove-Item -LiteralPath $marker -Force -ErrorAction SilentlyContinue
        Write-AgentLog ("Test-mode simulated process interruption point={0}." -f $Point)
        if ($Point -eq 'after-accepted') { exit 97 }
        exit 98
    }
}

function Test-Command {
    param($Command)
    Test-RccCommand -Command $Command -Config $config
}

function Get-NoncePath {
    param([string]$Nonce, [string]$Extension)
    Join-Path $actionStatusDir "$Nonce.$Extension"
}

function Read-ActionStatus {
    param([string]$Nonce)
    $path = Get-NoncePath -Nonce $Nonce -Extension 'json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    try { Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } catch { $null }
}

function New-AcceptedActionStatus {
    param($Command, [string]$RequestHash)
    $path = Get-NoncePath -Nonce ([string]$Command.nonce) -Extension 'json'
    $record = New-RccActionStatus -Nonce ([string]$Command.nonce) -Action ([string]$Command.action) -RequestHash $RequestHash -State 'accepted' -SharedKey ([string]$config.SharedKey) -Message 'accepted'
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
    try { $command = $Body | ConvertFrom-Json -ErrorAction Stop } catch { Write-AgentLog 'Skipped malformed command'; return 'skipped' }
    if (-not (Test-Command -Command $command)) { Write-AgentLog 'Skipped rejected or expired command'; return 'skipped' }
    $nonce = [string]$command.nonce
    $requestHash = Get-RccRequestFingerprint -Command $command
    $statusAction = Get-RccStatusAction -Action ([string]$command.action)
    $status = Read-ActionStatus -Nonce $nonce
    if (-not $status) {
        $status = New-AcceptedActionStatus -Command $command -RequestHash $requestHash
        if (-not $status) { $status = Read-ActionStatus -Nonce $nonce }
    }
    if (-not $status -or [string]$status.action -cne $statusAction -or [string]$status.requestHash -cne $requestHash) {
        Write-AgentLog "Rejected nonce collision action=$statusAction nonce=$nonce"
        return 'skipped'
    }
    if ([string]$status.state -cne 'accepted') { return 'skipped' }
    Invoke-TestCrashIfRequested -Point 'after-accepted'
    $dispatchClaim = Claim-ActionDispatch -Nonce $nonce
    if (-not $dispatchClaim) {
        $claimPath = Get-NoncePath -Nonce $nonce -Extension 'dispatch'
        if (Test-Path -LiteralPath $claimPath -PathType Leaf) { return 'skipped' }
        return 'retry'
    }
    $invoke = Join-Path $PSScriptRoot 'Invoke-RemoteCommandCenterTrackedAction.ps1'
    $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$invoke,'-Action',[string]$command.action,'-Nonce',$nonce,'-ConfigPath',$ConfigPath,'-RequestHash',$requestHash)
    if ([bool]$command.dryRun) { $args += '-ProofOnly' }
    try {
        Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $args -WindowStyle Hidden | Out-Null
        Write-AgentLog "Accepted command action=$statusAction nonce=$nonce"
        return 'handled'
    } catch {
        if ($statusAction -ceq 'terminal_line') {
            Write-AgentLog "Terminal dispatch failed action=terminal_line nonce=$nonce; command body was not copied into local storage."
            $statusPath = Get-NoncePath -Nonce $nonce -Extension 'json'
            $unconfirmed = New-RccActionStatus -Nonce $nonce -Action ([string]$command.action) -RequestHash $requestHash -State 'unconfirmed' -SharedKey ([string]$config.SharedKey) -ExitCode 124 -Message 'Terminal dispatch failed; execution is unconfirmed.'
            $statusWritten = Write-RccActionStatusFile -Path $statusPath -Record $unconfirmed
            Publish-RccActionStatus -Record $unconfirmed -Config $config | Out-Null
            if ($statusWritten) { return 'skipped' }
            return 'retry'
        }
        # ALLOW_DESTRUCTIVE: remove only this invocation's claim after the
        # process launch call threw, allowing the signed relay event to retry.
        Remove-Item -LiteralPath $dispatchClaim -Force -ErrorAction SilentlyContinue
        Write-AgentLog "Command dispatch failed action=$statusAction nonce=$nonce error=$($_.Exception.Message)"
        return 'retry'
    }
}

function Handle-LocalQueue {
    $queueDir = Join-Path $config.StateDir 'local-queue'
    New-Item -ItemType Directory -Force -Path $queueDir | Out-Null
    $file = Get-ChildItem -LiteralPath $queueDir -Filter '*.json' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -First 1
    if (-not $file) { return $false }
    $body = Get-Content -LiteralPath $file.FullName -Raw
    $outcome = Handle-CommandJson -Body $body
    if ($outcome -in @('handled', 'skipped')) {
        # ALLOW_DESTRUCTIVE: remove only this queue item after dispatch has
        # succeeded or the request has a durable terminal/duplicate disposition.
        Remove-Item -LiteralPath $file.FullName -Force -ErrorAction SilentlyContinue
    }
    return ($outcome -eq 'handled')
}

function Handle-RelayPoll {
    $topic = [string]$config.CommandTopic
    foreach ($base in @($config.RelayBases)) {
        $baseInfo = Get-RelayBaseInfo -Base ([string]$base)
        $baseKey = [string]$baseInfo.Base
        if (-not $script:relayCursors.ContainsKey($baseKey)) {
            Write-AgentLog 'Relay cursor was not initialized; refusing to poll.'
            return $false
        }
        $cursor = [string]$script:relayCursors[$baseKey]
        $url = ('{0}/{1}/json?poll=1&since={2}' -f $baseKey, [Uri]::EscapeDataString($topic), [Uri]::EscapeDataString($cursor))
        try {
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 8 -ErrorAction Stop
            $content = $response.Content
            if ($content -is [byte[]]) {
                $content = [Text.Encoding]::UTF8.GetString($content)
            }
            $lines = @([string]$content -split "`r?`n" | Where-Object { $_.Trim() })
            foreach ($line in $lines) {
                try { $event = $line | ConvertFrom-Json -ErrorAction Stop } catch {
                    Write-AgentLog 'Relay event parse failed; cursor was not advanced.'
                    return $false
                }
                $nextCursor = Get-RelayEventCursor -Event $event
                if ([string]$event.event -cne 'message') {
                    if ($nextCursor) {
                        try { Commit-RelayCursor -Base $baseKey -Cursor $nextCursor } catch {
                            Write-AgentLog 'Relay cursor persistence failed; polling stopped fail-closed.'
                            return $false
                        }
                    }
                    continue
                }
                if (-not $nextCursor) {
                    Write-AgentLog 'Relay message had no usable cursor; cursor was not advanced.'
                    return $false
                }
                $eventTime = 0L
                if ([long]::TryParse([string]$event.time, [Globalization.NumberStyles]::Integer,
                        [Globalization.CultureInfo]::InvariantCulture, [ref]$eventTime) -and
                    $eventTime -ge 0 -and $eventTime -lt [long]$script:relayBaselines[$baseKey]) {
                    try { Commit-RelayCursor -Base $baseKey -Cursor $nextCursor } catch {
                        Write-AgentLog 'Relay cursor persistence failed; polling stopped fail-closed.'
                        return $false
                    }
                    continue
                }
                if ([string]::IsNullOrWhiteSpace([string]$event.message)) {
                    try { Commit-RelayCursor -Base $baseKey -Cursor $nextCursor } catch {
                        Write-AgentLog 'Relay cursor persistence failed; polling stopped fail-closed.'
                        return $false
                    }
                    continue
                }
                $outcome = Handle-CommandJson -Body ([string]$event.message)
                if ($outcome -eq 'retry') {
                    Write-AgentLog 'Relay dispatch remains retryable; cursor was not advanced.'
                    return $false
                }
                if ($outcome -eq 'handled') { Invoke-TestCrashIfRequested -Point 'after-dispatch' }
                try {
                    Commit-RelayCursor -Base $baseKey -Cursor $nextCursor
                } catch {
                    Write-AgentLog 'Relay cursor persistence failed; polling stopped fail-closed.'
                    return $false
                }
                if ($outcome -eq 'handled') { return $true }
            }
        } catch {
            Write-AgentLog 'Relay poll failed; persisted cursor retained.'
        }
    }
    return $false
}

Write-AgentLog 'Agent started.'
try {
    foreach ($configuredBase in @($config.RelayBases)) {
        $baseInfo = Get-RelayBaseInfo -Base ([string]$configuredBase)
        $baseKey = [string]$baseInfo.Base
        if (-not $script:relayCursors.ContainsKey($baseKey)) {
            $cursorState = Read-RelayCursor -RelayBaseInfo $baseInfo
            $script:relayCursors[$baseKey] = [string]$cursorState.Cursor
            $script:relayBaselines[$baseKey] = [long]$cursorState.BaselineTime
        }
    }
} catch {
    Write-AgentLog 'Relay cursor state is invalid or unavailable; agent stopped fail-closed.'
    try { $mutex.ReleaseMutex() | Out-Null } catch {}
    $mutex.Dispose()
    exit 1
}
do {
    $handled = Handle-LocalQueue
    if (-not $handled) { $handled = Handle-RelayPoll }
    if ($Once) { break }
    if (-not $handled) { Start-Sleep -Seconds $IdleSeconds }
} while ($true)
Write-AgentLog 'Agent stopped'
try { $mutex.ReleaseMutex() | Out-Null } catch {}
$mutex.Dispose()
