#!/bin/bash
# TovPlay Database Backup Script
BACKUP_DIR=/home/admin/db_backups
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE=$BACKUP_DIR/tovplay_backup_$TIMESTAMP.sql
export PGPASSWORD=CaptainForgotCreatureBreak
/usr/bin/pg_dump -h 45.148.28.196 -U raz@tovtech.org -d TovPlay --no-password > $BACKUP_FILE
gzip $BACKUP_FILE
find $BACKUP_DIR -name "tovplay_backup_*.sql.gz" -mtime +7 -delete
echo "Backup completed: $BACKUP_FILE.gz"
