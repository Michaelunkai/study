#Requires -Version 5
# CLU - Claude Code Real-Time Subscription Usage (Pure PowerShell)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   CLAUDE CODE - SUBSCRIPTION USAGE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# --- Get OAuth token ---
$token = $env:CLAUDE_CODE_OAUTH_TOKEN
if (-not $token) { $token = $env:ANTHROPIC_OAUTH_TOKEN }

# Fallback: read from credentials file
if (-not $token) {
    $credPath = Join-Path $env:USERPROFILE ".claude\.credentials.json"
    if (Test-Path $credPath) {
        try {
            $cred = Get-Content $credPath -Raw | ConvertFrom-Json
            if ($cred.claudeAiOauth.accessToken) {
                $token = $cred.claudeAiOauth.accessToken
            }
        } catch { }
    }
}

if (-not $token) {
    Write-Host "  (!) No OAuth token found." -ForegroundColor Red
    Write-Host "      Run clu from inside a Claude Code session," -ForegroundColor Yellow
    Write-Host "      or ensure CLAUDE_CODE_OAUTH_TOKEN is set." -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# --- Make minimal API call to get rate limit headers ---
$body = @{
    model      = 'claude-haiku-4-5-20251001'
    max_tokens = 1
    messages   = @(@{ role = 'user'; content = 'hi' })
} | ConvertTo-Json -Depth 3

$headers = @{
    'Authorization'   = "Bearer $token"
    'anthropic-version' = '2023-06-01'
    'content-type'    = 'application/json'
    'anthropic-beta'  = 'oauth-2025-04-20'
}

$respHeaders = $null
$apiError = $null

try {
    $resp = Invoke-WebRequest -Uri 'https://api.anthropic.com/v1/messages' `
        -Method Post -Headers $headers -Body $body -UseBasicParsing -TimeoutSec 15
    $respHeaders = $resp.Headers
} catch {
    $ex = $_.Exception
    if ($ex.Response) {
        # Even on 429/error, headers contain rate limit info
        $respHeaders = @{}
        foreach ($key in $ex.Response.Headers.AllKeys) {
            $respHeaders[$key] = $ex.Response.Headers[$key]
        }
        $statusCode = [int]$ex.Response.StatusCode
        if ($statusCode -eq 401) {
            $apiError = "Authentication failed. Token may be expired."
        }
    } else {
        $apiError = "Request failed: $($ex.Message)"
    }
}

if ($apiError -and -not $respHeaders) {
    Write-Host "  (!) $apiError" -ForegroundColor Red
    Write-Host ""
    exit 1
}

# --- Parse rate limit headers ---
# Build case-insensitive lookup
$h = @{}
if ($respHeaders) {
    foreach ($key in $respHeaders.Keys) {
        $h[$key.ToLower()] = $respHeaders[$key]
    }
}

$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

$limits = @(
    @{ key = '5h';  name = '5-Hour Window' }
    @{ key = '7d';  name = '7-Day Window' }
)

$hasData = $false

foreach ($lim in $limits) {
    $prefix = "anthropic-ratelimit-unified-$($lim.key)"
    $utilRaw = $h["${prefix}-utilization"]
    $resetRaw = $h["${prefix}-reset"]
    $statusRaw = $h["${prefix}-status"]

    if ($null -eq $utilRaw -and $null -eq $resetRaw) { continue }
    $hasData = $true

    $pct = 0
    if ($utilRaw) { $pct = [Math]::Round([double]$utilRaw * 100) }

    # Build progress bar
    $barLen = 30
    $filled = [Math]::Floor(($pct / 100) * $barLen)
    $bar = ""
    for ($i = 0; $i -lt $barLen; $i++) {
        if ($i -lt $filled) { $bar += "#" } else { $bar += "-" }
    }

    # Calculate reset time
    $resetInfo = ""
    if ($resetRaw) {
        $resetTs = [double]$resetRaw
        $diff = $resetTs - $now
        if ($diff -gt 0) {
            $days = [Math]::Floor($diff / 86400)
            $hrs  = [Math]::Floor(($diff % 86400) / 3600)
            $mins = [Math]::Floor(($diff % 3600) / 60)
            if ($days -gt 0) {
                $resetInfo = "  resets in ${days}d ${hrs}h"
            } elseif ($hrs -gt 0) {
                $resetInfo = "  resets in ${hrs}h ${mins}m"
            } else {
                $resetInfo = "  resets in ${mins}m"
            }
        } else {
            $resetInfo = "  resets now"
        }
    }

    $line = "  {0,-18} [{1}] {2,3}%{3}" -f $lim.name, $bar, $pct, $resetInfo

    if ($pct -ge 90) {
        Write-Host $line -ForegroundColor Red
    } elseif ($pct -ge 70) {
        Write-Host $line -ForegroundColor Yellow
    } elseif ($pct -ge 40) {
        Write-Host $line -ForegroundColor DarkYellow
    } else {
        Write-Host $line -ForegroundColor Green
    }
}

if (-not $hasData) {
    Write-Host "  No rate limit data available" -ForegroundColor DarkGray
}

# Overall status
Write-Host ""
$overallStatus = $h['anthropic-ratelimit-unified-status']
if ($overallStatus -eq 'rejected') {
    Write-Host "  STATUS: RATE LIMITED" -ForegroundColor Red
} elseif ($overallStatus) {
    Write-Host "  STATUS: $overallStatus" -ForegroundColor Green
}

# Overage info
$overageStatus = $h['anthropic-ratelimit-unified-overage-status']
$overageReason = $h['anthropic-ratelimit-unified-overage-disabled-reason']
if ($overageStatus -eq 'rejected' -and $overageReason) {
    $reason = $overageReason -replace '_', ' '
    Write-Host "  Extra Usage: disabled ($reason)" -ForegroundColor DarkGray
} elseif ($overageStatus -eq 'allowed') {
    Write-Host "  Extra Usage: enabled" -ForegroundColor Cyan
}

# Fallback
$fallback = $h['anthropic-ratelimit-unified-fallback-percentage']
if ($fallback) {
    $fbPct = [Math]::Round([double]$fallback * 100)
    Write-Host "  Fallback: ${fbPct}% of requests may use fallback model" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
