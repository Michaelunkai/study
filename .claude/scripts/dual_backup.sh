#!/bin/bash
# ============================================================
# DUAL DATABASE BACKUP SCRIPT
# Backs up BOTH Local Docker AND External PostgreSQL
# Runs every 4 hours via cron
# ============================================================

BACKUP_DIR="/opt/tovplay_backups"
DATE=$(date +%Y%m%d_%H%M%S)
EXTERNAL_HOST="45.148.28.196"
EXTERNAL_USER="raz@tovtech.org"
EXTERNAL_PASS="CaptainForgotCreatureBreak"
EXTERNAL_DB="TovPlay"

mkdir -p $BACKUP_DIR/local
mkdir -p $BACKUP_DIR/external

echo "$(date): Starting dual backup..."

# 1. Backup LOCAL Docker postgres
echo "$(date): Backing up LOCAL Docker postgres..."
docker exec tovplay-postgres-production pg_dump -U tovplay -d TovPlay --no-owner --no-acl > "$BACKUP_DIR/local/backup_local_$DATE.sql" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "$(date): LOCAL backup SUCCESS: backup_local_$DATE.sql"
    docker exec tovplay-postgres-production psql -U tovplay -d TovPlay -c "INSERT INTO \"BackupLog\" (backup_type, backup_location, status) VALUES ('local_auto', '/opt/tovplay_backups/local/backup_local_$DATE.sql', 'success');" 2>/dev/null
else
    echo "$(date): LOCAL backup FAILED!"
fi

# 2. Backup EXTERNAL postgres (45.148.28.196)
echo "$(date): Backing up EXTERNAL postgres..."
export PGPASSWORD="$EXTERNAL_PASS"
pg_dump -h $EXTERNAL_HOST -U "$EXTERNAL_USER" -d $EXTERNAL_DB --no-owner --no-acl > "$BACKUP_DIR/external/backup_external_$DATE.sql" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "$(date): EXTERNAL backup SUCCESS: backup_external_$DATE.sql"
    psql -h $EXTERNAL_HOST -U "$EXTERNAL_USER" -d $EXTERNAL_DB -c "INSERT INTO \"BackupLog\" (backup_type, backup_location, status) VALUES ('external_auto', '/opt/tovplay_backups/external/backup_external_$DATE.sql', 'success');" 2>/dev/null
else
    echo "$(date): EXTERNAL backup FAILED!"
fi

# 3. Cleanup old backups (keep last 30 of each)
echo "$(date): Cleaning up old backups..."
cd $BACKUP_DIR/local && ls -t backup_local_*.sql 2>/dev/null | tail -n +31 | xargs -r rm --
cd $BACKUP_DIR/external && ls -t backup_external_*.sql 2>/dev/null | tail -n +31 | xargs -r rm --

# 4. Verify row counts match
echo "$(date): Verifying database sync..."
LOCAL_COUNT=$(docker exec tovplay-postgres-production psql -U tovplay -d TovPlay -t -c "SELECT COUNT(*) FROM \"User\";" 2>/dev/null | tr -d ' ')
EXTERNAL_COUNT=$(psql -h $EXTERNAL_HOST -U "$EXTERNAL_USER" -d $EXTERNAL_DB -t -c "SELECT COUNT(*) FROM \"User\";" 2>/dev/null | tr -d ' ')

if [ "$LOCAL_COUNT" != "$EXTERNAL_COUNT" ]; then
    echo "$(date): WARNING! Database sync mismatch! Local=$LOCAL_COUNT External=$EXTERNAL_COUNT"
else
    echo "$(date): Databases in sync: $LOCAL_COUNT users"
fi

echo "$(date): Dual backup completed!"
