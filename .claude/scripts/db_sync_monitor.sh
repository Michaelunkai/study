#!/bin/bash
# FIXED: Monitor DB Sync and Alert on Failures
LOG_FILE=/var/log/db_realtime_sync.log
ALERT_FILE=/var/log/db_sync_alerts.log
LOG_DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Check recent logs for errors
if tail -50 "$LOG_FILE" 2>/dev/null | grep -q "CRITICAL"; then
    ERROR_COUNT=$(tail -50 "$LOG_FILE" 2>/dev/null | grep -c "CRITICAL")
    echo "[$LOG_DATE] WARNING: $ERROR_COUNT critical errors in last 50 lines" >> "$ALERT_FILE"
fi
