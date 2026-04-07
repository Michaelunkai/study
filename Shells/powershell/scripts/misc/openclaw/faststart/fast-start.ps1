# fast-start.ps1 — OpenClaw fast-start profile system
# Pre-spawns gateway, warms up connection, optimizes PS environment

param(
    [switch]$Silent
)

function Write-Log {
    param([string]$Msg)
    if (-not $Silent) { Write-Host "[oc-fast] $Msg" -ForegroundColor Cyan }
}

# 1. Set PowerShell execution environment for max speed
try {
    Set-PSReadLineOption -PredictionSource None -ErrorAction SilentlyContinue
    Write-Log "PSReadLine optimized (prediction disabled)"
} catch {
    Write-Log "PSReadLine not available — skipping"
}

# 2. Pre-spawn OpenClaw gateway if not running
$gatewayRunning = $false
try {
    $response = Invoke-WebRequest -Uri "http://localhost:18792/ping" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        $gatewayRunning = $true
        Write-Log "Gateway already running on port 18792"
    }
} catch {
    Write-Log "Gateway not detected — attempting to start..."
}

if (-not $gatewayRunning) {
    # Try to start OpenClaw gateway
    $oclawPaths = @(
        "C:\Users\micha\AppData\Local\Programs\openclaw\OpenClaw.exe",
        "C:\Users\micha\AppData\Local\OpenClaw\OpenClaw.exe",
        "${env:LOCALAPPDATA}\Programs\openclaw\OpenClaw.exe",
        "${env:LOCALAPPDATA}\OpenClaw\OpenClaw.exe"
    )
    
    $started = $false
    foreach ($path in $oclawPaths) {
        if (Test-Path $path) {
            Start-Process $path -WindowStyle Hidden
            Write-Log "Started OpenClaw from: $path"
            $started = $true
            break
        }
    }
    
    if (-not $started) {
        # Try openclaw CLI
        $cliResult = Get-Command "openclaw" -ErrorAction SilentlyContinue
        if ($cliResult) {
            Start-Process "openclaw" -ArgumentList "gateway start" -WindowStyle Hidden
            Write-Log "Started OpenClaw gateway via CLI"
            $started = $true
        }
    }
    
    if ($started) {
        # Wait for gateway to come up (max 10s)
        $attempts = 0
        while ($attempts -lt 10) {
            Start-Sleep -Milliseconds 1000
            try {
                $r = Invoke-WebRequest -Uri "http://localhost:18792/ping" -TimeoutSec 1 -UseBasicParsing -ErrorAction Stop
                if ($r.StatusCode -eq 200) {
                    Write-Log "Gateway is up after $($attempts+1)s"
                    $gatewayRunning = $true
                    break
                }
            } catch { }
            $attempts++
        }
        if (-not $gatewayRunning) {
            Write-Log "WARNING: Gateway did not respond within 10s"
        }
    } else {
        Write-Log "WARNING: Could not find OpenClaw executable"
    }
}

# 3. Warm up connection — send test ping
if ($gatewayRunning) {
    try {
        $ping = Invoke-WebRequest -Uri "http://localhost:18792/ping" -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        Write-Log "Connection warm — gateway ping OK (status: $($ping.StatusCode))"
    } catch {
        Write-Log "Ping failed: $($_.Exception.Message)"
    }
}

# 4. Ensure oc-fast function is in PowerShell profile
$profilePath = "C:\users\micha\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$fastStartScript = "C:\Users\micha\.openclaw\scripts\fast-start.ps1"

$funcBlock = @'

# oc-fast: OpenClaw fast-start (auto-added by fast-start.ps1)
function oc-fast {
    param([switch]$Silent)
    & "C:\Users\micha\.openclaw\scripts\fast-start.ps1" @PSBoundParameters
}
'@

if (Test-Path $profilePath) {
    $profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($profileContent -notmatch "function oc-fast") {
        Add-Content -Path $profilePath -Value $funcBlock
        Write-Log "Added oc-fast function to PS profile"
    } else {
        Write-Log "oc-fast already in PS profile"
    }
} else {
    # Create profile with function
    New-Item -Path $profilePath -ItemType File -Force | Out-Null
    Set-Content -Path $profilePath -Value $funcBlock.TrimStart()
    Write-Log "Created PS profile with oc-fast function"
}

Write-Log "Fast-start complete"
