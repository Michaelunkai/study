#!/usr/bin/env pwsh
# OpenClaw Complete Restart Script
# Kills all processes, clears conflicts, and starts fresh

param(
    [switch]$NoStart,
    [switch]$Force
)

$ErrorActionPreference = 'SilentlyContinue'

# Check for active protected tasks before restarting
$lockFile = "$env:USERPROFILE\.openclaw\task-protector-lock.json"
if ((Test-Path $lockFile) -and -not $Force) {
    try {
        $data = Get-Content $lockFile -Raw | ConvertFrom-Json
        $now = Get-Date
        $activeTask = $null
        # Multi-lock format
        if ($data.locks) {
            foreach ($lock in $data.locks) {
                if ($lock.active -and $lock.deadline -and ([datetime]$lock.deadline -gt $now)) {
                    $activeTask = $lock.task
                    break
                }
            }
        }
        # Legacy single-lock format
        if (-not $activeTask -and $data.active -and $data.deadline -and ([datetime]$data.deadline -gt $now)) {
            $activeTask = $data.task
        }
        if ($activeTask) {
            Write-Host "`n⚠️  RESTART BLOCKED — A protected task is running!" -ForegroundColor Red
            Write-Host "   Task: $activeTask" -ForegroundColor Yellow
            Write-Host "   Use /stop first, or run with -Force to override." -ForegroundColor Yellow
            exit 1
        }
    } catch {}
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "   OPENCLAW COMPLETE RESTART" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

# Step 1: Kill all node/OpenClaw processes
Write-Host "[1/5] Stopping all OpenClaw/Node processes..." -ForegroundColor Yellow
$nodeProcs = Get-Process -Name "node" -ErrorAction SilentlyContinue
if ($nodeProcs) {
    foreach ($proc in $nodeProcs) {
        try {
            Stop-Process -Id $proc.Id -Force
            Write-Host "  Killed: PID $($proc.Id)" -ForegroundColor Green
        } catch {}
    }
    Start-Sleep -Seconds 3
    Write-Host "  All processes terminated" -ForegroundColor Green
} else {
    Write-Host "  No processes running" -ForegroundColor Gray
}

# Step 2: Run startup fixes
Write-Host "`n[2/5] Running startup fixes..." -ForegroundColor Yellow
$fixScript = "$env:USERPROFILE\.openclaw\scripts\startup-fixes.ps1"
if (Test-Path $fixScript) {
    & $fixScript
} else {
    Write-Host "  Warning: startup-fixes.ps1 not found" -ForegroundColor Red
}

# Step 3: Clear Telegram conflicts
Write-Host "`n[3/5] Clearing Telegram bot conflicts..." -ForegroundColor Yellow
$telegramScript = "$env:USERPROFILE\.openclaw\scripts\kill-telegram-conflicts.ps1"
if (Test-Path $telegramScript) {
    & $telegramScript
} else {
    Write-Host "  Warning: kill-telegram-conflicts.ps1 not found" -ForegroundColor Red
}

# Step 4: Verify OpenClaw binary
Write-Host "`n[4/5] Locating OpenClaw..." -ForegroundColor Yellow
$openclawPaths = @(
    "C:\Users\micha\.openclaw\openclaw.exe",
    "C:\Users\micha\.openclaw\bin\openclaw.exe",
    "$env:USERPROFILE\.openclaw\openclaw.exe",
    "$env:USERPROFILE\.openclaw\bin\openclaw.exe",
    "openclaw.exe"  # Try PATH
)

$openclawExe = $null
foreach ($path in $openclawPaths) {
    if (Test-Path $path -ErrorAction SilentlyContinue) {
        $openclawExe = $path
        break
    }
}

if ($openclawExe) {
    Write-Host "  Found: $openclawExe" -ForegroundColor Green
} else {
    Write-Host "  OpenClaw executable not found!" -ForegroundColor Red
    Write-Host "  Searched paths:" -ForegroundColor Gray
    foreach ($path in $openclawPaths) {
        Write-Host "    - $path" -ForegroundColor Gray
    }
}

# Step 5: Start OpenClaw (unless -NoStart)
if ($NoStart) {
    Write-Host "`n[5/5] Skipping OpenClaw start (-NoStart flag)" -ForegroundColor Gray
} else {
    Write-Host "`n[5/5] Starting OpenClaw..." -ForegroundColor Yellow
    if ($openclawExe) {
        try {
            Start-Process -FilePath $openclawExe -WorkingDirectory "$env:USERPROFILE\.openclaw" -NoNewWindow
            Start-Sleep -Seconds 2
            Write-Host "  OpenClaw started successfully!" -ForegroundColor Green
        } catch {
            Write-Host "  Failed to start: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "  Cannot start - executable not found" -ForegroundColor Red
    }
}

Write-Host "`n======================================" -ForegroundColor Cyan
Write-Host "   RESTART COMPLETE" -ForegroundColor Cyan
Write-Host "======================================`n" -ForegroundColor Cyan

exit 0
