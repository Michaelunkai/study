#Requires -RunAsAdministrator
# Daily C: Drive Cleanup Scheduler
# Runs daily cleanup at 3 AM, logs results to file

param(
    [string]$LogPath = "$env:USERPROFILE\.claude\cleanup-logs",
    [bool]$RunNow = $false,
    [bool]$Schedule = $false
)

# Create log directory if it doesn't exist
if (-not (Test-Path $LogPath)) { New-Item -ItemType Directory -Path $LogPath -Force | Out-Null }

$logFile = Join-Path $LogPath "cleanup-$(Get-Date -Format 'yyyy-MM-dd').log"
$todayLog = Join-Path $LogPath "cleanup-today.log"

# Redirect output to log file
$logStream = [System.IO.StreamWriter]::new($logFile, $true)

function LogWrite {
    param([string]$Message, [string]$Color = "White")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMsg = "[$timestamp] $Message"

    Write-Host $logMsg -ForegroundColor $Color
    $logStream.WriteLine($logMsg)
    $logStream.Flush()
}

try {
    LogWrite "========== DAILY CLEANUP START ==========" "Cyan"
    LogWrite "Log: $logFile" "Gray"

    # Show current disk usage before cleanup
    LogWrite "`n[BEFORE] C: Drive Status:" "Yellow"
    $cDrive = Get-Volume -DriveLetter C
    $beforeFree = $cDrive.SizeRemaining
    $beforeFreeGB = [math]::Round($beforeFree / 1GB, 2)
    LogWrite "  Free space: $beforeFreeGB GB" "White"

    # Run the cleanup script
    LogWrite "`n[CLEANUP] Starting aggressive cleanup..." "Yellow"

    $cleanupScript = 'F:\study\Shells\powershell\scripts\misc\ccsizes\ccsizes-cleanup.ps1'
    if (Test-Path $cleanupScript) {
        # Suppress user prompts
        & $cleanupScript -Cleanup -Estimate 2>&1 | ForEach-Object {
            $logStream.WriteLine($_)
            $logStream.Flush()
        }
    } else {
        LogWrite "ERROR: Cleanup script not found at $cleanupScript" "Red"
    }

    # Show disk usage after cleanup
    LogWrite "`n[AFTER] C: Drive Status:" "Green"
    Start-Sleep -Seconds 2
    [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers()

    $cDrive = Get-Volume -DriveLetter C
    $afterFree = $cDrive.SizeRemaining
    $afterFreeGB = [math]::Round($afterFree / 1GB, 2)
    $freedGB = [math]::Round(($afterFree - $beforeFree) / 1GB, 2)

    LogWrite "  Free space: $afterFreeGB GB" "Green"
    if ($freedGB -gt 0) {
        LogWrite "  Freed: +$freedGB GB" "Green"
    }

    LogWrite "`n========== DAILY CLEANUP COMPLETE ==========" "Cyan"

    # Copy to today's log
    Copy-Item $logFile $todayLog -Force

} catch {
    LogWrite "ERROR: $($_.Exception.Message)" "Red"
    LogWrite "$($_.ScriptStackTrace)" "Red"
} finally {
    $logStream.Close()
    $logStream.Dispose()
}

# Schedule daily task if requested
if ($Schedule) {
    LogWrite "`n[SCHEDULER] Registering daily cleanup task..." "Cyan"

    $scriptPath = $MyInvocation.MyCommand.Path
    $taskName = "DailyCleanupCDrive"
    $taskPath = "\Claude Code\$taskName"

    # Create scheduled task
    $trigger = New-ScheduledTaskTrigger -Daily -At 3:00AM
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopIfGoingOnBatteries -AllowStartIfOnBatteries
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

    $existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath "\Claude Code\" -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -TaskPath "\Claude Code\" -Confirm:$false
        LogWrite "  Removed existing task" "Yellow"
    }

    Register-ScheduledTask -TaskName $taskName -TaskPath "\Claude Code\" -Trigger $trigger -Principal $principal -Settings $settings -Action $action -Force
    LogWrite "  Task scheduled to run daily at 3:00 AM" "Green"
}
