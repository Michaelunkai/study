#!/bin/bash
# Ultimate DB Protection Script
MODE=$1
export PGPASSWORD="CaptainForgotCreatureBreak"
DB_HOST="45.148.28.196"
DB_USER="raz@tovtech.org"
DB_NAME="TovPlay"
BACKUP_DIR="/opt/tovplay_backups/protection"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

case "$MODE" in
    backup)
        BACKUP_FILE="$BACKUP_DIR/protection_$TIMESTAMP.sql"
        if /usr/bin/pg_dump -h $DB_HOST -U "$DB_USER" -d $DB_NAME --no-password > "$BACKUP_FILE" 2>/dev/null; then
            SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
            echo "$(date): Protection backup: $SIZE" >> /var/log/db_protection.log
        fi
        ;;
    cleanup)
        find "$BACKUP_DIR" -name "protection_*.sql" -mtime +5 -delete
        echo "$(date): Cleaned old protection backups" >> /var/log/db_protection.log
        ;;
esac
