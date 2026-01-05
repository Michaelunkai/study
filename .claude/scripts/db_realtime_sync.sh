#!/bin/bash
# Database existence check
export PGPASSWORD="CaptainForgotCreatureBreak"
LOG_DATE=$(date "+%Y-%m-%d %H:%M:%S")
if psql -h 45.148.28.196 -U "raz@tovtech.org" -d TovPlay -c "SELECT 1" > /dev/null 2>&1; then
    echo "[$LOG_DATE] DB OK" >> /var/log/db_realtime_sync.log
else
    echo "[$LOG_DATE] CRITICAL: DATABASE NOT ACCESSIBLE!" >> /var/log/db_alerts.log
fi
