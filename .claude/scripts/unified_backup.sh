#!/bin/bash
# FIXED: Unified External DB Backup Script
BACKUP_DIR="/opt/tovplay_backups/external_db"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/external_db_$TIMESTAMP.sql"
export PGPASSWORD="CaptainForgotCreatureBreak"
/usr/bin/pg_dump -h 45.148.28.196 -U "raz@tovtech.org" -d TovPlay --no-password > "$BACKUP_FILE" 2>/tmp/backup_error.log
if [ $? -eq 0 ] && [ -s "$BACKUP_FILE" ]; then
    echo "$(date): Backup successful - $BACKUP_FILE" >> /var/log/db_backup.log
    find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete
else
    echo "$(date): Backup FAILED!" >> /var/log/db_backup.log
fi
