param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'

function Format-ResetTime {
    param([AllowNull()][object]$UnixSeconds)

    if ($null -eq $UnixSeconds) {
        return 'reset time unknown'
    }

    $reset = [DateTimeOffset]::FromUnixTimeSeconds([int64]$UnixSeconds)
    $remaining = $reset - [DateTimeOffset]::UtcNow
    if ($remaining.TotalSeconds -le 0) {
        return 'resets now'
    }

    if ($remaining.TotalDays -ge 1) {
        return 'resets in {0}d {1}h' -f [math]::Floor($remaining.TotalDays), $remaining.Hours
    }

    if ($remaining.TotalHours -ge 1) {
        return 'resets in {0}h {1}m' -f [math]::Floor($remaining.TotalHours), $remaining.Minutes
    }

    return 'resets in {0}m' -f [math]::Max(1, [math]::Ceiling($remaining.TotalMinutes))
}

try {
    $coduCandidates = @(
        'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\cli\codex\codu.ps1',
        'F:\study\repos\ai-ml\AI_and_Machine_Learning\Artificial_Intelligence\cli\codex\codu.ps1'
    )
    $coduPath = @($coduCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)[0]
    if (-not $coduPath) {
        throw 'Codex usage script was not found.'
    }

    $raw = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $coduPath -Json 2>&1
    $exitCode = $LASTEXITCODE
    $text = (($raw | ForEach-Object { [string]$_ }) -join [Environment]::NewLine).Trim()
    if ($exitCode -ne 0) {
        if ([string]::IsNullOrWhiteSpace($text)) {
            $text = "codu exited with code $exitCode"
        }
        throw $text
    }

    $payload = $text | ConvertFrom-Json
    Write-Output 'CODEX - REAL-TIME ACCOUNT USAGE'
    Write-Output ("Fetched: {0}" -f ([string]$payload.fetched_at))

    foreach ($window in @($payload.windows)) {
        $title = [string]$window.title
        $left = [int]$window.left_percent
        $used = [int]$window.used_percent
        Write-Output ('- {0}: left {1}% / used {2}% ({3})' -f $title, $left, $used, (Format-ResetTime -UnixSeconds $window.reset_ts))
    }

    if (-not $payload.windows -or @($payload.windows).Count -eq 0) {
        Write-Output '- No Codex rate-limit windows were returned.'
    }

    exit 0
} catch {
    $message = $_.Exception.Message
    if ([string]::IsNullOrWhiteSpace($message)) {
        $message = [string]$_
    }
    Write-Output ("OpenClaw /clu failed: {0}" -f $message.Trim())
    exit 1
}
