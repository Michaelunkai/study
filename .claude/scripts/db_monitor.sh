#!/bin/bash
# ============================================================
# DATABASE INTEGRITY MONITOR
# Runs every 10 minutes - alerts on ANY data deletion
# ============================================================

EXTERNAL_HOST="45.148.28.196"
EXTERNAL_USER="raz@tovtech.org"
EXTERNAL_PASS="CaptainForgotCreatureBreak"
EXTERNAL_DB="TovPlay"
ALERT_FILE="/var/log/db_alerts.log"
STATE_FILE="/opt/tovplay_backups/.row_counts"

export PGPASSWORD="$EXTERNAL_PASS"

# Get current row counts
get_counts() {
    local db_type=$1
    if [ "$db_type" = "local" ]; then
        docker exec tovplay-postgres-production psql -U tovplay -d TovPlay -t -c "
            SELECT 'User:' || COUNT(*) FROM \"User\"
            UNION ALL SELECT 'Game:' || COUNT(*) FROM \"Game\"
            UNION ALL SELECT 'GameRequest:' || COUNT(*) FROM \"GameRequest\"
            UNION ALL SELECT 'ScheduledSession:' || COUNT(*) FROM \"ScheduledSession\"
            UNION ALL SELECT 'UserProfile:' || COUNT(*) FROM \"UserProfile\";
        " 2>/dev/null | tr -d ' ' | sort
    else
        psql -h $EXTERNAL_HOST -U "$EXTERNAL_USER" -d $EXTERNAL_DB -t -c "
            SELECT 'User:' || COUNT(*) FROM \"User\"
            UNION ALL SELECT 'Game:' || COUNT(*) FROM \"Game\"
            UNION ALL SELECT 'GameRequest:' || COUNT(*) FROM \"GameRequest\"
            UNION ALL SELECT 'ScheduledSession:' || COUNT(*) FROM \"ScheduledSession\"
            UNION ALL SELECT 'UserProfile:' || COUNT(*) FROM \"UserProfile\";
        " 2>/dev/null | tr -d ' ' | sort
    fi
}

# Check for deletions in audit log
check_deletions() {
    local db_type=$1
    if [ "$db_type" = "local" ]; then
        docker exec tovplay-postgres-production psql -U tovplay -d TovPlay -t -c "
            SELECT COUNT(*) FROM \"DeleteAuditLog\" WHERE deleted_at > NOW() - INTERVAL '15 minutes';
        " 2>/dev/null | tr -d ' '
    else
        psql -h $EXTERNAL_HOST -U "$EXTERNAL_USER" -d $EXTERNAL_DB -t -c "
            SELECT COUNT(*) FROM \"DeleteAuditLog\" WHERE deleted_at > NOW() - INTERVAL '15 minutes';
        " 2>/dev/null | tr -d ' '
    fi
}

DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Check for recent deletions
LOCAL_DELETIONS=$(check_deletions "local")
EXTERNAL_DELETIONS=$(check_deletions "external")

if [ "$LOCAL_DELETIONS" -gt 0 ] 2>/dev/null; then
    echo "[$DATE] ALERT: $LOCAL_DELETIONS deletions detected in LOCAL database!" >> $ALERT_FILE
    docker exec tovplay-postgres-production psql -U tovplay -d TovPlay -c "SELECT * FROM \"DeleteAuditLog\" WHERE deleted_at > NOW() - INTERVAL '15 minutes';" >> $ALERT_FILE
fi

if [ "$EXTERNAL_DELETIONS" -gt 0 ] 2>/dev/null; then
    echo "[$DATE] ALERT: $EXTERNAL_DELETIONS deletions detected in EXTERNAL database!" >> $ALERT_FILE
    psql -h $EXTERNAL_HOST -U "$EXTERNAL_USER" -d $EXTERNAL_DB -c "SELECT * FROM \"DeleteAuditLog\" WHERE deleted_at > NOW() - INTERVAL '15 minutes';" >> $ALERT_FILE
fi

# Get current counts
LOCAL_COUNTS=$(get_counts "local")
EXTERNAL_COUNTS=$(get_counts "external")

# Compare with previous
if [ -f "$STATE_FILE" ]; then
    PREV_LOCAL=$(grep "^LOCAL:" $STATE_FILE | cut -d: -f2-)
    PREV_EXTERNAL=$(grep "^EXTERNAL:" $STATE_FILE | cut -d: -f2-)

    # Check if User count decreased (CRITICAL!)
    PREV_LOCAL_USERS=$(echo "$PREV_LOCAL" | grep "User:" | cut -d: -f2)
    CURR_LOCAL_USERS=$(echo "$LOCAL_COUNTS" | grep "User:" | cut -d: -f2)
    PREV_EXT_USERS=$(echo "$PREV_EXTERNAL" | grep "User:" | cut -d: -f2)
    CURR_EXT_USERS=$(echo "$EXTERNAL_COUNTS" | grep "User:" | cut -d: -f2)

    if [ "$CURR_LOCAL_USERS" -lt "$PREV_LOCAL_USERS" ] 2>/dev/null; then
        echo "[$DATE] CRITICAL: LOCAL User count DECREASED from $PREV_LOCAL_USERS to $CURR_LOCAL_USERS!" >> $ALERT_FILE
    fi

    if [ "$CURR_EXT_USERS" -lt "$PREV_EXT_USERS" ] 2>/dev/null; then
        echo "[$DATE] CRITICAL: EXTERNAL User count DECREASED from $PREV_EXT_USERS to $CURR_EXT_USERS!" >> $ALERT_FILE
    fi
fi

# Save current state
echo "LOCAL:$LOCAL_COUNTS" > $STATE_FILE
echo "EXTERNAL:$EXTERNAL_COUNTS" >> $STATE_FILE

# Check databases are in sync
LOCAL_USERS=$(echo "$LOCAL_COUNTS" | grep "User:" | cut -d: -f2)
EXT_USERS=$(echo "$EXTERNAL_COUNTS" | grep "User:" | cut -d: -f2)

if [ "$LOCAL_USERS" != "$EXT_USERS" ]; then
    echo "[$DATE] WARNING: Database sync mismatch! Local=$LOCAL_USERS External=$EXT_USERS" >> $ALERT_FILE
fi

echo "[$DATE] Monitor check completed. Local=$LOCAL_USERS External=$EXT_USERS" >> /var/log/db_monitor.log
