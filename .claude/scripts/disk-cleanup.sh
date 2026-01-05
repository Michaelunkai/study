#!/bin/bash
# Disk Auto-Cleanup Script - Runs every hour
# Prevents disk from filling up and crashing PostgreSQL

THRESHOLD=70
LOG=/var/log/disk-cleanup.log

# Get disk usage percentage
USAGE=$(df / --output=pcent | tail -1 | tr -dc '0-9')

if [ "$USAGE" -gt "$THRESHOLD" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Disk at ${USAGE}%, starting cleanup..." >> $LOG

    # 1. Prune unused Docker resources
    docker system prune -af 2>/dev/null

    # 2. Truncate Prometheus query log (main culprit)
    truncate -s 0 /var/lib/docker/volumes/monitoring_prometheus-data/_data/query.log 2>/dev/null

    # 3. Clean journal logs
    journalctl --vacuum-size=100M 2>/dev/null

    # 4. Truncate large log files
    find /var/log -type f -name "*.log" -size +50M -exec truncate -s 0 {} \; 2>/dev/null
    find /var/log -type f -name "*.log.*" -mtime +7 -delete 2>/dev/null

    # 5. Clean old Docker volumes
    find /var/lib/docker/volumes -name "query.log" -size +100M -exec truncate -s 0 {} \; 2>/dev/null

    # 6. Clean apt cache
    apt-get clean 2>/dev/null

    NEWUSAGE=$(df / --output=pcent | tail -1 | tr -dc '0-9')
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Cleanup done. Was ${USAGE}%, now ${NEWUSAGE}%" >> $LOG
else
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Disk at ${USAGE}%, OK" >> $LOG
fi
