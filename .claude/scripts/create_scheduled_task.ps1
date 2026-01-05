# Create scheduled task for TovPlay DB backup
$Action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-ExecutionPolicy Bypass -File "F:\tovplay\.claude\scripts\local_db_backup.ps1"'
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 4)
$Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# Remove existing task if exists
Unregister-ScheduledTask -TaskName 'TovPlay-DB-Backup' -Confirm:$false -ErrorAction SilentlyContinue

# Register new task
Register-ScheduledTask -TaskName 'TovPlay-DB-Backup' -Action $Action -Trigger $Trigger -Settings $Settings -Description 'Backs up TovPlay database every 4 hours' -Force

Write-Host "Scheduled task created: TovPlay-DB-Backup"
Get-ScheduledTask -TaskName 'TovPlay-DB-Backup' | Format-List TaskName, State
