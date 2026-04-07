#!/usr/bin/env pwsh
# OpenClaw Status — comprehensive health check
# Updated 2026-03-31 with startup optimization findings

param(
    [switch]$Json,
    [switch]$Quick
)

$ErrorActionPreference = 'SilentlyContinue'
$statusFile = "C:\Users\micha\.openclaw\status-output.txt"
$results = @{}

# --- 1. Process check ---
$nodeProcs = Get-Process -Name "node" -ErrorAction SilentlyContinue
$results.nodeProcesses = if ($nodeProcs) { $nodeProcs.Count } else { 0 }
$results.nodeUptime = if ($nodeProcs) {
    $oldest = $nodeProcs | Sort-Object StartTime | Select-Object -First 1
    [math]::Round(((Get-Date) - $oldest.StartTime).TotalMinutes, 1)
} else { 0 }

# --- 2. Gateway port check (18789 default) ---
$gwPort = 18789
$gwConn = Get-NetTCPConnection -LocalPort $gwPort -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Listen' }
$results.gatewayListening = [bool]$gwConn
$results.gatewayPID = if ($gwConn) { $gwConn.OwningProcess } else { $null }

# --- 3. Task Scheduler tasks ---
$tasks = Get-ScheduledTask -TaskName "openclaw*" -ErrorAction SilentlyContinue
$results.scheduledTasks = if ($tasks) {
    $tasks | ForEach-Object { @{ name = $_.TaskName; state = $_.State.ToString() } }
} else { @() }

# --- 4. Config file check ---
$configPath = "C:\Users\micha\.openclaw\openclaw.config.json5"
$results.configExists = Test-Path $configPath

# --- 5. Startup VBS/BAT check ---
$results.startupFiles = @{
    clawdBotVbs = Test-Path "C:\Users\micha\.openclaw\scripts\ClawdBot_Startup.vbs"
    gatewaySilentVbs = Test-Path "C:\Users\micha\.openclaw\scripts\gateway-silent.vbs"
    restartScript = Test-Path "C:\Users\micha\.openclaw\scripts\openclaw-restart.ps1"
    startupFixes = Test-Path "C:\Users\micha\.openclaw\scripts\startup-fixes.ps1"
    killTelegram = Test-Path "C:\Users\micha\.openclaw\scripts\kill-telegram-conflicts.ps1"
}

# --- 6. Protected task lock check ---
$lockFile = "C:\Users\micha\.openclaw\task-protector-lock.json"
$results.taskProtected = $false
if (Test-Path $lockFile) {
    try {
        $lockData = Get-Content $lockFile -Raw | ConvertFrom-Json
        $now = Get-Date
        if ($lockData.locks) {
            foreach ($lock in $lockData.locks) {
                if ($lock.active -and $lock.deadline -and ([datetime]$lock.deadline -gt $now)) {
                    $results.taskProtected = $true
                    $results.protectedTask = $lock.task
                    break
                }
            }
        }
    } catch {}
}

# --- 7. Full openclaw status (skip if -Quick) ---
if (-not $Quick) {
    $statusOutput = & openclaw status 2>&1 | Where-Object { $_ -notmatch '^\[' }
    $results.statusOutput = ($statusOutput | Out-String).Trim()
}

# --- Output ---
if ($Json) {
    $results | ConvertTo-Json -Depth 4 | Out-File $statusFile -Encoding UTF8
    $results | ConvertTo-Json -Depth 4
} else {
    Write-Host "`n=== OPENCLAW STATUS ===" -ForegroundColor Cyan
    Write-Host ""

    # Processes
    if ($results.nodeProcesses -gt 0) {
        Write-Host "  Node processes: $($results.nodeProcesses) (uptime: $($results.nodeUptime) min)" -ForegroundColor Green
    } else {
        Write-Host "  Node processes: NONE RUNNING" -ForegroundColor Red
    }

    # Gateway
    if ($results.gatewayListening) {
        Write-Host "  Gateway:        LISTENING on :$gwPort (PID $($results.gatewayPID))" -ForegroundColor Green
    } else {
        Write-Host "  Gateway:        NOT LISTENING on :$gwPort" -ForegroundColor Red
    }

    # Config
    Write-Host "  Config:         $(if ($results.configExists) { 'Found' } else { 'MISSING' })" -ForegroundColor $(if ($results.configExists) { 'Green' } else { 'Red' })

    # Task lock
    if ($results.taskProtected) {
        Write-Host "  Protected task: $($results.protectedTask)" -ForegroundColor Yellow
    }

    # Scheduled tasks
    Write-Host ""
    Write-Host "  Scheduled Tasks:" -ForegroundColor Gray
    foreach ($t in $results.scheduledTasks) {
        $color = if ($t.state -eq 'Ready') { 'Green' } else { 'Yellow' }
        Write-Host "    $($t.name): $($t.state)" -ForegroundColor $color
    }
    if ($results.scheduledTasks.Count -eq 0) {
        Write-Host "    (none found)" -ForegroundColor Gray
    }

    # Startup files
    Write-Host ""
    Write-Host "  Startup Files:" -ForegroundColor Gray
    foreach ($key in $results.startupFiles.Keys) {
        $exists = $results.startupFiles[$key]
        Write-Host "    ${key}: $(if ($exists) { 'OK' } else { 'MISSING' })" -ForegroundColor $(if ($exists) { 'Green' } else { 'Red' })
    }

    # Full status output
    if ($results.statusOutput) {
        Write-Host ""
        Write-Host "  Channel Status:" -ForegroundColor Gray
        $results.statusOutput -split "`n" | ForEach-Object { Write-Host "    $_" }
    }

    Write-Host ""
    Write-Host "========================`n" -ForegroundColor Cyan

    # Also save to file
    $results | ConvertTo-Json -Depth 4 | Out-File $statusFile -Encoding UTF8
    Write-Host "Saved to: $statusFile" -ForegroundColor Gray
}
