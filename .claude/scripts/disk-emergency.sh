#!/bin/bash
# Emergency disk cleanup - aggressive mode
LOG=/var/log/disk-cleanup.log
echo "$(date '+%Y-%m-%d %H:%M:%S'): EMERGENCY CLEANUP TRIGGERED" >> $LOG

# Aggressive cleanup
docker system prune -af --volumes 2>/dev/null
truncate -s 0 /var/lib/docker/volumes/monitoring_prometheus-data/_data/query.log 2>/dev/null
journalctl --vacuum-size=50M 2>/dev/null
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null
find /var/log -type f -name "*.gz" -delete 2>/dev/null
find /tmp -type f -mtime +1 -delete 2>/dev/null
apt-get clean 2>/dev/null

USAGE=$(df / --output=pcent | tail -1 | tr -dc '0-9')
echo "$(date '+%Y-%m-%d %H:%M:%S'): Emergency cleanup done. Now ${USAGE}%" >> $LOG
