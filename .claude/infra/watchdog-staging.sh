#!/bin/bash
LOG=/var/log/tovplay/watchdog.log
mkdir -p /var/log/tovplay
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> $LOG; }
CONTAINERS="tovplay-backend-staging"
log "Watchdog started"
while true; do
  for c in $CONTAINERS; do
    status=$(docker inspect --format='{{.State.Status}}' $c 2>/dev/null)
    if [ "$status" != "running" ]; then
      log "Container $c is $status, starting..."
      docker start $c 2>/dev/null || true
    fi
  done
  sleep 30
done
