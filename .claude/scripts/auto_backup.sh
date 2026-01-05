#!/bin/bash
# TovPlay Automated Backup Script
# Runs every 6 hours via cron

BACKUP_DIR="/opt/tovplay_backups"
DB_HOST="45.148.28.196"
DB_USER="raz@tovtech.org"
DB_NAME="TovPlay"
DB_PASS="CaptainForgotCreatureBreak"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

export PGPASSWORD="$DB_PASS"

# Create backup
pg_dump -h $DB_HOST -U "$DB_USER" -d $DB_NAME --no-password > "$BACKUP_DIR/tovplay_backup_$DATE.sql" 2>/dev/null

# Log backup
psql -h $DB_HOST -U "$DB_USER" -d $DB_NAME -c "INSERT INTO \"BackupLog\" (backup_type) VALUES ('auto_6h');" --no-password 2>/dev/null

# Keep only last 20 backups (120 hours = 5 days worth)
cd $BACKUP_DIR
ls -t tovplay_backup_*.sql 2>/dev/null | tail -n +21 | xargs -r rm --

echo "$(date): Backup completed: tovplay_backup_$DATE.sql"
