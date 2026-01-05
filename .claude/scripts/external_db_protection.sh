#!/bin/bash

# 🚨 EXTERNAL DATABASE PROTECTION SYSTEM
# Monitors external PostgreSQL and auto-restores if database is missing
# Deployed to: /opt/external_db_protection.sh
# Cron: */5 * * * * /opt/external_db_protection.sh (Every 5 minutes)

set +e  # Don't exit on errors, log them instead

LOG_FILE="/var/log/external_db_protection.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
BACKUP_DIR="/opt/tovplay_backups/external"
DB_HOST="45.148.28.196"
DB_USER="raz@tovtech.org"
DB_PASSWORD="CaptainForgotCreatureBreak"
DB_NAME="TovPlay"

echo "[${TIMESTAMP}] Starting external database protection check..." >> "$LOG_FILE"

# ════════════════════════════════════════════════════════════════════════════════
# FUNCTION 1: Check if database exists
# ════════════════════════════════════════════════════════════════════════════════

check_database_exists() {
    export PGPASSWORD="$DB_PASSWORD"

    # Check if database exists
    DB_EXISTS=$(psql -h "$DB_HOST" -U "$DB_USER" -lqt 2>/dev/null | cut -d'|' -f1 | grep -w "$DB_NAME")

    if [ -z "$DB_EXISTS" ]; then
        echo "[${TIMESTAMP}] ❌ ALERT: Database '$DB_NAME' NOT FOUND!" >> "$LOG_FILE"
        return 1  # Database missing
    else
        echo "[${TIMESTAMP}] ✅ Database '$DB_NAME' exists" >> "$LOG_FILE"
        return 0  # Database exists
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# FUNCTION 2: Check if we can connect to external database
# ════════════════════════════════════════════════════════════════════════════════

check_connectivity() {
    export PGPASSWORD="$DB_PASSWORD"

    # Try to connect
    timeout 10 psql -h "$DB_HOST" -U "$DB_USER" -c "SELECT 1" >/dev/null 2>&1

    if [ $? -ne 0 ]; then
        echo "[${TIMESTAMP}] ❌ ALERT: Cannot connect to external database at $DB_HOST:5432" >> "$LOG_FILE"
        return 1
    else
        echo "[${TIMESTAMP}] ✅ External database is reachable" >> "$LOG_FILE"
        return 0
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# FUNCTION 3: Get table count to verify data integrity
# ════════════════════════════════════════════════════════════════════════════════

check_data_integrity() {
    export PGPASSWORD="$DB_PASSWORD"

    TABLE_COUNT=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -tc "
        SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = 'public'
    " 2>/dev/null | tr -d ' ')

    if [ -z "$TABLE_COUNT" ] || [ "$TABLE_COUNT" = "0" ]; then
        echo "[${TIMESTAMP}] ❌ WARNING: No tables found in database (possible data loss)" >> "$LOG_FILE"
        return 1
    else
        echo "[${TIMESTAMP}] ✅ Database has $TABLE_COUNT tables" >> "$LOG_FILE"
        return 0
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# FUNCTION 4: Restore database from backup
# ════════════════════════════════════════════════════════════════════════════════

restore_database() {
    export PGPASSWORD="$DB_PASSWORD"

    echo "[${TIMESTAMP}] 🚨 CRITICAL: Initiating database restoration..." >> "$LOG_FILE"

    # Find latest backup
    LATEST_BACKUP=$(find "$BACKUP_DIR" -name "*.sql" -type f 2>/dev/null | sort | tail -1)

    if [ -z "$LATEST_BACKUP" ]; then
        echo "[${TIMESTAMP}] ❌ FATAL: No backup found at $BACKUP_DIR" >> "$LOG_FILE"
        echo "[${TIMESTAMP}] Cannot restore without backup!" >> "$LOG_FILE"

        # Try to use local Docker backup as fallback
        echo "[${TIMESTAMP}] Attempting to use local Docker database as recovery source..." >> "$LOG_FILE"
        docker exec tovplay-postgres-production pg_dump -U tovplay -d TovPlay 2>/dev/null > /tmp/docker_backup.sql
        LATEST_BACKUP="/tmp/docker_backup.sql"
    fi

    if [ ! -f "$LATEST_BACKUP" ]; then
        echo "[${TIMESTAMP}] ❌ FATAL: Cannot find any backup source" >> "$LOG_FILE"
        return 1
    fi

    echo "[${TIMESTAMP}] Using backup: $LATEST_BACKUP" >> "$LOG_FILE"

    # Step 1: Create database if missing
    echo "[${TIMESTAMP}] Step 1: Creating database if missing..." >> "$LOG_FILE"
    psql -h "$DB_HOST" -U "$DB_USER" -c "CREATE DATABASE \"$DB_NAME\";" 2>>/"$LOG_FILE"
    sleep 2

    # Step 2: Restore from backup
    echo "[${TIMESTAMP}] Step 2: Restoring database from backup..." >> "$LOG_FILE"

    if timeout 120 psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$LATEST_BACKUP" >> "$LOG_FILE" 2>&1; then
        echo "[${TIMESTAMP}] ✅ Restoration completed successfully" >> "$LOG_FILE"
        return 0
    else
        echo "[${TIMESTAMP}] ❌ Restoration failed or timed out" >> "$LOG_FILE"
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# FUNCTION 5: Verify restoration success
# ════════════════════════════════════════════════════════════════════════════════

verify_restoration() {
    export PGPASSWORD="$DB_PASSWORD"

    sleep 5  # Wait for restore to settle

    # Check tables again
    TABLE_COUNT=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -tc "
        SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = 'public'
    " 2>/dev/null | tr -d ' ')

    # Check data
    USER_COUNT=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -tc "
        SELECT COUNT(*) FROM \"User\"
    " 2>/dev/null | tr -d ' ')

    if [ -n "$TABLE_COUNT" ] && [ "$TABLE_COUNT" -gt "0" ]; then
        echo "[${TIMESTAMP}] ✅ Verification: $TABLE_COUNT tables, $USER_COUNT users" >> "$LOG_FILE"
        return 0
    else
        echo "[${TIMESTAMP}] ❌ Verification failed: No tables found after restore" >> "$LOG_FILE"
        return 1
    fi
}

# ════════════════════════════════════════════════════════════════════════════════
# MAIN LOGIC
# ════════════════════════════════════════════════════════════════════════════════

echo "" >> "$LOG_FILE"
echo "════════════════════════════════════════════════════════════════════════════════" >> "$LOG_FILE"

# Check 1: Can we reach external database?
if ! check_connectivity; then
    echo "[${TIMESTAMP}] Cannot reach external database - skipping this check" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    exit 0
fi

# Check 2: Does the database exist?
if ! check_database_exists; then
    echo "[${TIMESTAMP}] Database missing - INITIATING AUTO-RESTORE!" >> "$LOG_FILE"

    if restore_database; then
        echo "[${TIMESTAMP}] Restore completed - verifying..." >> "$LOG_FILE"

        if verify_restoration; then
            echo "[${TIMESTAMP}] 🎉 DATABASE SUCCESSFULLY RESTORED!" >> "$LOG_FILE"

            # Send alert (if alert system exists)
            if command -v mail &> /dev/null; then
                echo "External database was missing and has been automatically restored from backup." | \
                mail -s "ALERT: Database Auto-Restored at $(date)" admin@tovplay.org 2>/dev/null || true
            fi
        else
            echo "[${TIMESTAMP}] Restoration verification failed - manual intervention required" >> "$LOG_FILE"
        fi
    else
        echo "[${TIMESTAMP}] Database restoration FAILED - manual intervention required immediately!" >> "$LOG_FILE"
    fi

    echo "" >> "$LOG_FILE"
    exit 1
fi

# Check 3: Verify data integrity
if ! check_data_integrity; then
    echo "[${TIMESTAMP}] Data integrity issue detected - possible corruption" >> "$LOG_FILE"
fi

echo "[${TIMESTAMP}] ✅ All checks passed - external database is healthy" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"
exit 0
