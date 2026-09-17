function Get-RccHmacSignature {
    param([Parameter(Mandatory = $true)][string]$Text, [Parameter(Mandatory = $true)][string]$Key)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    try {
        $hmac.Key = [Text.Encoding]::UTF8.GetBytes($Key)
        [Convert]::ToBase64String($hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    } finally {
        $hmac.Dispose()
    }
}

function Test-RccFixedTimeText {
    param([string]$Expected, [string]$Actual)
    if ($null -eq $Expected -or $null -eq $Actual -or $Expected.Length -ne $Actual.Length) { return $false }
    $difference = 0
    for ($index = 0; $index -lt $Expected.Length; $index++) {
        $difference = $difference -bor (([int][char]$Expected[$index]) -bxor ([int][char]$Actual[$index]))
    }
    return ($difference -eq 0)
}

function Get-RccCommandCanonical {
    param([Parameter(Mandatory = $true)]$Command)
    $dryText = ([string]$Command.dryRun).ToLowerInvariant()
    return "rcc|$($Command.createdAt)|$($Command.nonce)|$dryText|$($Command.action)|$($Command.confirm)"
}

function Test-RccAction {
    param([Parameter(Mandatory = $true)][string]$Action)

    $literalActions = @(
        'hibernate_pc', 'hibernate_toggle', 'open_stremio_tv', 'open_stremio',
        'sleep_pc', 'sleep_toggle', 'wake_pc', 'wake_controlled_sleep',
        'explorer_refresh_gpu', 'force_reboot_now', 'moonlight_prepare', 'moonlight_toggle',
        'night_mode_toggle', 'open_admin_terminal', 'open_wand_wemod', 'reboot_to_bios',
        'refresh_gpu', 'refresh2_logoff', 'restart_codex', 'restart_explorer', 'shutdown_pc',
        'toggle_openspeedy', 'toggle_qbittorrent', 'tv_force_reboot', 'tv_home', 'tv_mute',
        'tv_power_toggle', 'tv_volume_down', 'tv_volume_up', 'wake_settings_repair', 'youtube_tizen'
    )
    if ($literalActions -ccontains $Action) { return $true }

    if ($Action -cmatch '^tv_set_volume:([0-9]{1,3})$') {
        $volume = 0
        return [int]::TryParse($Matches[1], [ref]$volume) -and $volume -ge 0 -and $volume -le 100
    }

    if ($Action -cmatch '^terminal_line:([A-Za-z0-9_-]{2,16384})$') {
        try {
            if (($Matches[1].Length % 4) -eq 1) { return $false }
            $encoded = $Matches[1].Replace('-', '+').Replace('_', '/')
            switch ($encoded.Length % 4) {
                2 { $encoded += '==' }
                3 { $encoded += '=' }
            }
            $bytes = [Convert]::FromBase64String($encoded)
            if ($bytes.Length -gt 8192) { return $false }
            $strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
            [void]$strictUtf8.GetString($bytes)
            return $true
        } catch {
            return $false
        }
    }

    return $false
}

function ConvertFrom-RccBase64Url {
    param([Parameter(Mandatory = $true)][string]$Text)
    if ($Text -cnotmatch '^[A-Za-z0-9_-]{2,16384}$' -or ($Text.Length % 4) -eq 1) {
        throw 'Invalid base64url terminal payload.'
    }
    $base64 = $Text.Replace('-', '+').Replace('_', '/')
    switch ($base64.Length % 4) {
        2 { $base64 += '==' }
        3 { $base64 += '=' }
    }
    $bytes = [Convert]::FromBase64String($base64)
    if ($bytes.Length -gt 8192) { throw 'Terminal payload exceeds the UTF-8 byte limit.' }
    $strictUtf8 = New-Object Text.UTF8Encoding($false, $true)
    return $strictUtf8.GetString($bytes)
}

function Test-RccCommand {
    param([Parameter(Mandatory = $true)]$Command, [Parameter(Mandatory = $true)]$Config)
    try {
        if ([string]$Command.type -cne 'rcc') { return $false }
        if ([string]$Command.confirm -cne 'REMOTE_COMMAND_CENTER_EXECUTE') { return $false }
        if ($Command.dryRun -isnot [bool]) { return $false }
        $nonce = [string]$Command.nonce
        if ($nonce -cnotmatch '^[A-Za-z0-9_-]{16,128}$') { return $false }
        $action = [string]$Command.action
        if (-not (Test-RccAction -Action $action)) { return $false }

        $createdAt = 0L
        if (-not [long]::TryParse([string]$Command.createdAt, [ref]$createdAt)) { return $false }
        $allowedSkew = 120
        if ($null -ne $Config.AllowedSkewSeconds) { $allowedSkew = [Math]::Max(30, [Math]::Min(600, [int]$Config.AllowedSkewSeconds)) }
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        if ([Math]::Abs($now - $createdAt) -gt $allowedSkew) { return $false }

        $key = [string]$Config.SharedKey
        if ([string]::IsNullOrWhiteSpace($key)) { return $false }
        $expected = Get-RccHmacSignature -Text (Get-RccCommandCanonical -Command $Command) -Key $key
        return Test-RccFixedTimeText -Expected $expected -Actual ([string]$Command.signature)
    } catch {
        return $false
    }
}

function Get-RccRequestFingerprint {
    param([Parameter(Mandatory = $true)]$Command)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes((Get-RccCommandCanonical -Command $Command)))
        return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    } finally {
        $sha.Dispose()
    }
}

function Get-RccStatusAction {
    param([Parameter(Mandatory = $true)][string]$Action)
    if ($Action -cmatch '^terminal_line:') { return 'terminal_line' }
    return $Action
}

function Get-RccStatusCanonical {
    param([Parameter(Mandatory = $true)]$Record)
    return "rcc-status|$($Record.nonce)|$($Record.action)|$($Record.requestHash)|$($Record.state)|$($Record.exitCode)|$($Record.updatedUtc)|$($Record.message)"
}

function New-RccActionStatus {
    param(
        [Parameter(Mandatory = $true)][string]$Nonce,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$State,
        [Parameter(Mandatory = $true)][string]$SharedKey,
        [string]$RequestHash = '',
        [int]$ExitCode = 0,
        [string]$Message = ''
    )
    $record = [ordered]@{
        type = 'rcc-status'
        ok = ($State -in @('accepted', 'running', 'completed', 'skipped'))
        nonce = $Nonce
        action = Get-RccStatusAction -Action $Action
        requestHash = $RequestHash
        state = $State
        exitCode = $ExitCode
        message = $Message
        updatedUtc = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds().ToString([Globalization.CultureInfo]::InvariantCulture)
    }
    $record.signature = Get-RccHmacSignature -Text (Get-RccStatusCanonical -Record $record) -Key $SharedKey
    return $record
}

function Get-RccStatusQueryProof {
    param([Parameter(Mandatory = $true)][string]$Nonce, [Parameter(Mandatory = $true)][string]$SharedKey)
    return Get-RccHmacSignature -Text "rcc-status-query|$Nonce" -Key $SharedKey
}

function Test-RccStatusQueryProof {
    param([string]$Nonce, [string]$Proof, [string]$SharedKey)
    if ($Nonce -cnotmatch '^[A-Za-z0-9_-]{16,128}$' -or [string]::IsNullOrWhiteSpace($SharedKey)) { return $false }
    $expected = Get-RccStatusQueryProof -Nonce $Nonce -SharedKey $SharedKey
    return Test-RccFixedTimeText -Expected $expected -Actual $Proof
}

function Publish-RccActionStatus {
    param([Parameter(Mandatory = $true)]$Record, [Parameter(Mandatory = $true)]$Config)
    $topic = [string]$Config.StatusTopic
    if ($topic -cnotmatch '^[A-Za-z0-9_-]{1,128}$') { return $false }
    $body = $Record | ConvertTo-Json -Compress -Depth 6
    foreach ($base in @($Config.RelayBases)) {
        try {
            $uri = ('{0}/{1}' -f ([string]$base).TrimEnd('/'), [Uri]::EscapeDataString($topic))
            $null = Invoke-WebRequest -Uri $uri -Method Post -UseBasicParsing -ContentType 'text/plain; charset=utf-8' -Body $body -TimeoutSec 3 -ErrorAction Stop
            return $true
        } catch {
        }
    }
    return $false
}

function Write-RccActionStatusFile {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)]$Record)
    $tempPath = "$Path.$([guid]::NewGuid().ToString('N')).tmp"
    $backupPath = "$tempPath.bak"
    $json = $Record | ConvertTo-Json -Compress -Depth 6
    try {
        [IO.File]::WriteAllText($tempPath, $json, (New-Object Text.UTF8Encoding($false)))
        if (Test-Path -LiteralPath $Path -PathType Leaf) {
            [IO.File]::Replace($tempPath, $Path, $backupPath)
        } else {
            try {
                [IO.File]::Move($tempPath, $Path)
            } catch [IO.IOException] {
                if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw }
                [IO.File]::Replace($tempPath, $Path, $backupPath)
            }
        }
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) { Remove-Item -LiteralPath $backupPath -Force }
        return $true
    } finally {
        if (Test-Path -LiteralPath $tempPath -PathType Leaf) { Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $backupPath -PathType Leaf) { Remove-Item -LiteralPath $backupPath -Force -ErrorAction SilentlyContinue }
    }
}
