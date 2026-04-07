# Chrome CDP Status Checker
# Shows both Chrome profile processes, ports, and tab counts
# Usage: powershell -NoProfile -File chrome-cdp-status.ps1

function Get-CDPStatus {
    param([int]$Port, [string]$Account, [string]$ProfileDir)

    $status = [PSCustomObject]@{
        Port    = $Port
        Account = $Account
        Profile = $ProfileDir
        PID     = $null
        Tabs    = 0
        Status  = "NOT RUNNING"
        Browser = $null
    }

    # Check if port is listening
    $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) {
        $status.PID = $conn.OwningProcess
        $status.Status = "PORT OPEN"
    }

    # Try CDP endpoint
    try {
        $ver = Invoke-WebRequest -Uri "http://localhost:$Port/json/version" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        $verObj = $ver.Content | ConvertFrom-Json
        $status.Browser = $verObj.Browser
        $status.Status = "CDP ACTIVE"

        $tabs = Invoke-WebRequest -Uri "http://localhost:$Port/json" -TimeoutSec 2 -UseBasicParsing -ErrorAction Stop
        $tabList = $tabs.Content | ConvertFrom-Json
        $status.Tabs = ($tabList | Where-Object { $_.type -eq "page" }).Count
    } catch {}

    return $status
}

Write-Output ""
Write-Output "========================================="
Write-Output " Chrome Dual CDP Status"
Write-Output " $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "========================================="
Write-Output ""

$p1 = Get-CDPStatus -Port 9222 -Account "michaelovsky55@gmail.com" -ProfileDir "Profile 1"
$p2 = Get-CDPStatus -Port 9223 -Account "michaelovsky22@gmail.com" -ProfileDir "Profile 2"

foreach ($p in @($p1, $p2)) {
    $icon = if ($p.Status -eq "CDP ACTIVE") { "[OK]" } elseif ($p.Status -eq "PORT OPEN") { "[PORT]" } else { "[OFF]" }
    Write-Output "$icon  Port $($p.Port) | $($p.Account) | $($p.Profile)"
    Write-Output "     Status : $($p.Status)"
    if ($p.PID) { Write-Output "     PID    : $($p.PID)" }
    if ($p.Browser) { Write-Output "     Browser: $($p.Browser)" }
    if ($p.Status -eq "CDP ACTIVE") { Write-Output "     Tabs   : $($p.Tabs) page(s)" }
    Write-Output ""
}

# Check Chrome processes total
$chromeProcs = Get-Process -Name chrome -ErrorAction SilentlyContinue
Write-Output "Chrome processes total: $($chromeProcs.Count)"

# Check PID log
$pidLog = "C:\Users\micha\.claude\workspace\chrome-pids.txt"
if (Test-Path $pidLog) {
    Write-Output ""
    Write-Output "--- Last launch log ($pidLog) ---"
    Get-Content $pidLog
}

Write-Output ""
Write-Output "To launch both profiles: pwsh -File 'C:\Users\micha\.claude\scripts\chrome-dual-profile-launch.ps1'"
