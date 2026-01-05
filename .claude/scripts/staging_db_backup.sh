#!/bin/bash
# Fixed TovPlay backup script - NO --clean --if-exists flags!
# This prevents accidental data loss when restoring from backup
export PGPASSWORD=CaptainForgotCreatureBreak
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=/opt/tovplay_backups
mkdir -p "$BACKUP_DIR"

pg_dump -h 45.148.28.196 -p 5432 -U raz@tovtech.org -d TovPlay > "$BACKUP_DIR/tovplay_$TIMESTAMP.sql" 2>/dev/null

if [ $? -eq 0 ] && [ -s "$BACKUP_DIR/tovplay_$TIMESTAMP.sql" ]; then
    echo "[$(date)] Backup SUCCESS: tovplay_$TIMESTAMP.sql" >> /var/log/db_backup.log
else
    echo "[$(date)] Backup FAILED" >> /var/log/db_backup.log
fi

# Keep last 7 days of backups
find "$BACKUP_DIR" -name "tovplay_*.sql" -mtime +7 -delete 2>/dev/null
