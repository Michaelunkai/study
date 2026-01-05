# Real-Time Database Sync Setup (Dec 3, 2025)

## Problem Solved
Two separate PostgreSQL databases were causing data inconsistency:
- **Local Docker DB** (`postgres:5432`) - Used by Backend
- **External DB** (`45.148.28.196:5432`) - Used by Dashboard

Today at 07:50, the external DB was wiped. The sync mechanism didn't exist.

## Solution Implemented

### Sync Architecture
```
Local Docker DB (Backend)
    ↓ (pg_dump every 30 seconds)
Real-time Sync Service
    ↓ (pg_restore)
External DB (Dashboard, Backups)
```

### Components

#### 1. Real-Time Sync Script
**Location:** `/opt/db_realtime_sync.sh`
**Frequency:** Every 30 seconds
**Functions:**
- Compares checksums of both databases
- If mismatch: dumps local, restores to external
- Verifies sync succeeded

**Usage:**
```bash
/opt/db_realtime_sync.sh monitor   # Run continuously (systemd service)
/opt/db_realtime_sync.sh once      # Run single sync (cron job)
/opt/db_realtime_sync.sh check     # Just check if in sync
```

#### 2. Systemd Service
**File:** `/etc/systemd/system/db-realtime-sync.service`
**Status:** ✅ Active (running)
**Auto-restart:** Yes, every 10 seconds if fails
**Logs:** See `systemctl status db-realtime-sync`

#### 3. Cron Redundancy
**File:** `/etc/cron.d/db_realtime_sync`
**Frequency:** Every 5 minutes
**Purpose:** Backup sync in case systemd service fails

#### 4. Monitoring & Alerts
**File:** `/opt/db_sync_monitor.sh`
**Frequency:** Every 2 minutes
**Checks:**
- Service is running
- No recent errors in logs
- Sync happened within last 2 minutes
**Alert Log:** `/var/log/db_sync_alerts.log`

### Existing Protection (Still Active)
- **Ultimate DB Protection** - Detects if User count < 5, auto-restores (`/opt/ultimate_db_protection.sh`)
- **Backup Script** - Every 4 hours to `/opt/tovplay_backups/auto/`
- **10-Minute Backups** - To `/opt/tovplay_backups/auto/` (keep 20%, delete 80% every 5 days)

## Verification

✅ Sync service running
✅ Databases in sync
✅ Local DB: 22 users
✅ External DB: 22 users
✅ Cron jobs configured
✅ Monitoring active

## Logs to Monitor

```bash
# Real-time sync logs
tail -f /var/log/db_realtime_sync.log

# Sync alerts
tail -f /var/log/db_sync_alerts.log

# Ultimate protection logs
tail -f /var/log/ultimate_db_protection.log

# Service status
systemctl status db-realtime-sync
```

## What Happens If External DB Gets Wiped Again

**Timeline:**
- T=0s: External DB rows drop below 5
- T≤2s: Ultimate DB Protection detects (checks every 2s)
- T≤2s: Auto-restore from latest backup
- T=30s: Real-time sync verifies data matches local
- T=5m: Cron sync runs as redundancy

**Result:** Maximum 2-second downtime, full data recovery

## Testing

To test sync manually:
```bash
# Check current sync status
/opt/db_realtime_sync.sh check

# Force immediate sync
/opt/db_realtime_sync.sh once

# View logs
tail -20 /var/log/db_realtime_sync.log
```

## Future Improvements
- [ ] Implement bidirectional sync (external → local fallback)
- [ ] Add database replication (WAL streaming)
- [ ] Implement connection pooling for better performance
- [ ] Add metrics to Prometheus for monitoring
