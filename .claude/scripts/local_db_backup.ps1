# TovPlay Database Local Backup Script
# Run this via Windows Task Scheduler every 4 hours
# Backs up external database to F:\backup\tovplay\DB\

$BackupDir = "F:\backup\tovplay\DB"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = "$BackupDir\tovplay_$Timestamp.sql"
$LogFile = "$BackupDir\backup.log"

# Create backup directory if not exists
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

# Log function
function Log-Message {
    param($Message)
    $LogEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): $Message"
    Add-Content -Path $LogFile -Value $LogEntry
    Write-Host $LogEntry
}

Log-Message "Starting backup..."

# Run pg_dump via WSL
try {
    $result = wsl -d ubuntu bash -c "export PGPASSWORD='CaptainForgotCreatureBreak'; /usr/bin/pg_dump -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay --no-password" 2>&1

    if ($result -and $result.Length -gt 1000) {
        $result | Out-File -FilePath $BackupFile -Encoding utf8
        $Size = (Get-Item $BackupFile).Length / 1KB
        Log-Message "SUCCESS: Backup saved to $BackupFile ($([math]::Round($Size, 2)) KB)"

        # Keep only last 30 backups
        Get-ChildItem -Path $BackupDir -Filter "tovplay_*.sql" |
            Sort-Object CreationTime -Descending |
            Select-Object -Skip 30 |
            Remove-Item -Force
        Log-Message "Cleanup complete"
    } else {
        Log-Message "FAILED: Backup was empty or too small"
    }
} catch {
    Log-Message "ERROR: $($_.Exception.Message)"
}
