#!/bin/bash
# ============================================================
# DB GUARDIAN - Real-time Database Protection Monitor
# Runs every minute, alerts immediately on any issues
# ============================================================

export PGPASSWORD="CaptainForgotCreatureBreak"
DB_HOST="45.148.28.196"
DB_USER="raz@tovtech.org"
DB_NAME="TovPlay"
ALERT_FILE="/var/log/db_guardian_alerts.log"
STATE_FILE="/opt/tovplay_backups/.guardian_state"
LOG_FILE="/var/log/db_guardian.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

alert() {
    local message="$1"
    local severity="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$severity] $message" >> "$ALERT_FILE"
    log "ALERT: $message"

    # Could add Slack webhook here:
    # curl -X POST -H 'Content-type: application/json' \
    #     --data "{\"text\":\"DB ALERT: $message\"}" \
    #     https://hooks.slack.com/services/YOUR/WEBHOOK/URL
}

# 1. CHECK DATABASE EXISTS
if ! psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
    alert "CRITICAL: Database $DB_NAME does not exist or is not accessible!" "CRITICAL"
    exit 1
fi

# 2. GET CURRENT ROW COUNTS
CURRENT_USERS=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c 'SELECT COUNT(*) FROM "User"' 2>/dev/null | tr -d ' ')
CURRENT_GAMES=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c 'SELECT COUNT(*) FROM "Game"' 2>/dev/null | tr -d ' ')
CURRENT_PROFILES=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c 'SELECT COUNT(*) FROM "UserProfile"' 2>/dev/null | tr -d ' ')

# 3. CHECK FOR RECENT DELETIONS IN AUDIT LOG
RECENT_DELETIONS=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM \"DeleteAuditLog\" WHERE deleted_at > NOW() - INTERVAL '5 minutes'" 2>/dev/null | tr -d ' ')

if [ "$RECENT_DELETIONS" -gt 0 ] 2>/dev/null; then
    alert "$RECENT_DELETIONS records deleted in last 5 minutes! Check DeleteAuditLog" "HIGH"
fi

# 4. COMPARE WITH PREVIOUS STATE
if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"

    # Check if user count decreased
    if [ "$CURRENT_USERS" -lt "${PREV_USERS:-0}" ] 2>/dev/null; then
        DIFF=$((PREV_USERS - CURRENT_USERS))
        alert "User count DECREASED by $DIFF (was $PREV_USERS, now $CURRENT_USERS)" "CRITICAL"
    fi

    # Check if game count decreased
    if [ "$CURRENT_GAMES" -lt "${PREV_GAMES:-0}" ] 2>/dev/null; then
        DIFF=$((PREV_GAMES - CURRENT_GAMES))
        alert "Game count DECREASED by $DIFF (was $PREV_GAMES, now $CURRENT_GAMES)" "HIGH"
    fi

    # Check if profile count decreased
    if [ "$CURRENT_PROFILES" -lt "${PREV_PROFILES:-0}" ] 2>/dev/null; then
        DIFF=$((PREV_PROFILES - CURRENT_PROFILES))
        alert "Profile count DECREASED by $DIFF (was $PREV_PROFILES, now $CURRENT_PROFILES)" "HIGH"
    fi
fi

# 5. SAVE CURRENT STATE
cat > "$STATE_FILE" << EOF
PREV_USERS=$CURRENT_USERS
PREV_GAMES=$CURRENT_GAMES
PREV_PROFILES=$CURRENT_PROFILES
LAST_CHECK=$(date '+%Y-%m-%d %H:%M:%S')
EOF

# 6. LOG NORMAL STATUS (every 10 minutes only to reduce noise)
MINUTE=$(date +%M)
if [ $((MINUTE % 10)) -eq 0 ]; then
    log "OK: Users=$CURRENT_USERS Games=$CURRENT_GAMES Profiles=$CURRENT_PROFILES"
fi
