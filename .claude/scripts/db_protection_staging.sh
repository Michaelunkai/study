#!/bin/bash
#
# DATABASE PROTECTION SETUP - STAGING SERVER
# Purpose: Mirror production protection on staging
# Location: /home/admin/db_backups/
# Execute: bash /tmp/db_protection_staging.sh
#
# Staging Server: 92.113.144.59
# Password: 3897ysdkjhHH
#

set -e

echo "================================"
echo "DATABASE PROTECTION - STAGING"
echo "================================"
echo ""

# Configuration (same as production for consistency)
DB_HOST="45.148.28.196"
DB_USER="raz@tovtech.org"
DB_NAME="TovPlay"
BACKUP_DIR="/home/admin/db_backups_staging"

export PGPASSWORD="CaptainForgotCreatureBreak"

# ==============================================================================
# PHASE 1: VERIFY DATABASE INTEGRITY
# ==============================================================================
echo "[PHASE 1/5] Verifying database connectivity..."
if psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT version();" > /dev/null 2>&1; then
    echo "✅ Database is ONLINE and ACCESSIBLE"
else
    echo "❌ CRITICAL: Database connection FAILED!"
    exit 1
fi

echo ""
echo "Database Statistics:"
psql -h $DB_HOST -U $DB_USER -d $DB_NAME << SQL
  SELECT
    'Database Size' as metric,
    pg_size_pretty(pg_database_size('$DB_NAME')) as value
  UNION ALL
  SELECT
    'Table Count',
    count(*)::text FROM information_schema.tables WHERE table_schema='public';
SQL

# ==============================================================================
# PHASE 2: SETUP BACKUP INFRASTRUCTURE
# ==============================================================================
echo ""
echo "[PHASE 2/5] Setting up automated backup system..."

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
cd "$BACKUP_DIR"

# Create backup script for staging
cat > backup_staging.sh << 'BACKUP_SCRIPT'
#!/bin/bash
BACKUP_DIR="/home/admin/db_backups_staging"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/TovPlay_staging_backup_$DATE.sql"
export PGPASSWORD="CaptainForgotCreatureBreak"

{
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] === STAGING BACKUP START ==="

  if pg_dump -h 45.148.28.196 -U raz@tovtech.org -d TovPlay > "$BACKUP_FILE" 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Dump completed"

    if gzip "$BACKUP_FILE"; then
      BACKUP_FILE_GZ="$BACKUP_FILE.gz"
      BACKUP_SIZE=$(du -h "$BACKUP_FILE_GZ" | cut -f1)
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Backup compressed: $BACKUP_FILE_GZ ($BACKUP_SIZE)"

      if gzip -t "$BACKUP_FILE_GZ" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Backup integrity verified"
        find "$BACKUP_DIR" -name "TovPlay_staging_backup_*.sql.gz" -mtime +7 -exec rm -f {} \;
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] === STAGING BACKUP COMPLETE ==="
      else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ BACKUP CORRUPTED!"
        exit 1
      fi
    else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ Compression failed"
      exit 1
    fi
  else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ pg_dump failed"
    exit 1
  fi

} >> "$BACKUP_DIR/backup.log" 2>&1

BACKUP_SCRIPT

chmod +x backup_staging.sh
echo "✅ Backup script created: $BACKUP_DIR/backup_staging.sh"

# ==============================================================================
# PHASE 3: CREATE DISASTER RECOVERY PROCEDURES
# ==============================================================================
echo ""
echo "[PHASE 3/5] Creating disaster recovery procedures..."

cat > restore_latest_staging.sh << 'RESTORE_SCRIPT'
#!/bin/bash
BACKUP_DIR="/home/admin/db_backups_staging"
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/TovPlay_staging_backup_*.sql.gz 2>/dev/null | head -1)

if [ ! -f "$LATEST_BACKUP" ]; then
    echo "❌ ERROR: No backup found"
    exit 1
fi

echo "=================================================="
echo "⚠️  STAGING DATABASE RESTORE"
echo "=================================================="
echo "Backup: $LATEST_BACKUP"
echo "Size: $(du -h "$LATEST_BACKUP" | cut -f1)"
echo ""
read -p "Type 'RESTORE-CONFIRM' to proceed: " confirm

if [ "$confirm" != "RESTORE-CONFIRM" ]; then
    echo "❌ Restore cancelled"
    exit 0
fi

export PGPASSWORD="CaptainForgotCreatureBreak"
echo "Restoring database..."
gunzip -c "$LATEST_BACKUP" | psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay && echo "✅ Restore completed"

RESTORE_SCRIPT

chmod +x restore_latest_staging.sh
echo "✅ Restore script created: $BACKUP_DIR/restore_latest_staging.sh"

# ==============================================================================
# PHASE 4: SETUP MONITORING
# ==============================================================================
echo ""
echo "[PHASE 4/5] Setting up database protection guard..."

cat > protect_db_staging.sh << 'GUARD_SCRIPT'
#!/bin/bash
BACKUP_DIR="/home/admin/db_backups_staging"
LOG_FILE="$BACKUP_DIR/protection.log"
export PGPASSWORD="CaptainForgotCreatureBreak"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

{
  echo "[$TIMESTAMP] --- STAGING PROTECTION CHECK ---"

  if psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay -c "SELECT 1;" > /dev/null 2>&1; then
    echo "[$TIMESTAMP] ✅ Database connection: OK"
  else
    echo "[$TIMESTAMP] ❌ CRITICAL: Database connection FAILED!"
  fi

  LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/TovPlay_staging_backup_*.sql.gz 2>/dev/null | head -1)
  if [ -f "$LATEST_BACKUP" ]; then
    BACKUP_AGE=$(($(date +%s) - $(stat -c %Y "$LATEST_BACKUP")))
    HOURS_AGO=$((BACKUP_AGE / 3600))
    echo "[$TIMESTAMP] ✅ Latest backup: $HOURS_AGO hours ago"
  else
    echo "[$TIMESTAMP] ❌ CRITICAL: No backups found"
  fi

} >> "$LOG_FILE" 2>&1

GUARD_SCRIPT

chmod +x protect_db_staging.sh
echo "✅ Protection guard created: $BACKUP_DIR/protect_db_staging.sh"

# ==============================================================================
# PHASE 5: SCHEDULE AUTOMATED TASKS
# ==============================================================================
echo ""
echo "[PHASE 5/5] Scheduling automated tasks..."

CRON_BACKUP="0 2 * * * $BACKUP_DIR/backup_staging.sh"  # 2 AM UTC (differs from prod for staggering)
CRON_GUARD="30 * * * * $BACKUP_DIR/protect_db_staging.sh"

(crontab -l 2>/dev/null || true) > /tmp/crontab_temp
if ! grep -q "backup_staging.sh" /tmp/crontab_temp; then
    echo "$CRON_BACKUP" >> /tmp/crontab_temp
    crontab /tmp/crontab_temp
    echo "✅ Added daily backup cron job (2 AM UTC)"
fi

if ! grep -q "protect_db_staging.sh" /tmp/crontab_temp; then
    echo "$CRON_GUARD" >> /tmp/crontab_temp
    crontab /tmp/crontab_temp
    echo "✅ Added hourly protection guard cron job"
fi

rm -f /tmp/crontab_temp

echo ""
echo "Running initial backup..."
bash "$BACKUP_DIR/backup_staging.sh"

LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/TovPlay_staging_backup_*.sql.gz 2>/dev/null | head -1)
if [ -f "$LATEST_BACKUP" ]; then
    BACKUP_SIZE=$(du -h "$LATEST_BACKUP" | cut -f1)
    echo "✅ Initial backup verified: $LATEST_BACKUP ($BACKUP_SIZE)"
fi

echo ""
echo "================================"
echo "✅ STAGING PROTECTION COMPLETE"
echo "================================"
echo ""
echo "Backup Location: $BACKUP_DIR"
echo "Backup Schedule: Daily at 2 AM UTC"
echo "Protection Guard: Hourly checks"
echo ""
