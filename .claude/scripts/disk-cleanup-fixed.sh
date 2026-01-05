#!/bin/bash
# Fixed disk cleanup script - Dec 11, 2025
# Fixes: Broken syntax in original script

USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

if [ "$USAGE" -gt 70 ]; then
    # Only prune dangling images (not -a which removes all unused)
    # This is safer - won't remove images if containers temporarily stop
    docker image prune -f 2>/dev/null

    # Clean up prometheus query log
    truncate -s 0 /var/lib/docker/volumes/monitoring_prometheus-data/_data/query.log 2>/dev/null

    # Vacuum journal logs
    journalctl --vacuum-size=100M 2>/dev/null

    # Truncate large log files
    find /var/log -name "*.log" -size +50M -exec truncate -s 0 {} \;

    echo "$(date): Cleanup done, was ${USAGE}%" >> /var/log/disk-cleanup.log
fi
