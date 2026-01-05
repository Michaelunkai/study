# DATABASE CRITICAL ISSUE - CONNECTION EXHAUSTION

**Date**: Dec 5, 2025
**Status**: UNRESOLVED - Requires manual intervention
**Impact**: Production and Staging backends cannot connect to database

## Problem

PostgreSQL at 45.148.28.196:5432 (cvmathcher_dev server) is returning:
```
FATAL: sorry, too many clients already
```

This means all connection slots are exhausted. NO new connections possible until:
1. PostgreSQL is restarted to clear idle connections
2. OR max_connections limit is increased
3. OR idle connections are manually killed

## Root Cause

- PostgreSQL `max_connections` limit is too low (likely default 100)
- Applications (production/staging backends, dashboard, audit scripts) are not properly closing connections
- Idle connections accumulate over time
- No connection pooling implemented

## Resolution Steps (REQUIRES ADMIN ACCESS)

### Option 1: Quick Fix - Restart PostgreSQL (via Webdock Terminal)

1. Go to: https://app.webdock.io/en/dash/server/cvmathcher_dev/terminal
2. Login to the terminal
3. Run:
   ```bash
   sudo systemctl restart postgresql
   # OR if dockerized:
   docker restart <postgres-container-name>
   ```
4. Verify: `sudo systemctl status postgresql`

### Option 2: Permanent Fix - Increase max_connections

1. SSH to database server (45.148.28.196)
2. Edit PostgreSQL config:
   ```bash
   sudo nano /etc/postgresql/*/main/postgresql.conf
   # OR if dockerized, find the config volume
   ```
3. Change:
   ```
   max_connections = 100  # CURRENT
   max_connections = 500  # INCREASE TO THIS
   ```
4. Restart PostgreSQL
5. Update backend applications to use connection pooling (see below)

### Option 3: Implement Connection Pooling in Applications

**Production Backend** (`/root/tovplay-backend/src/config/database.py`):
```python
# Add to database.py
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=10,          # Max 10 connections per backend instance
    max_overflow=5,        # Allow 5 extra connections during spike
    pool_pre_ping=True,    # Check connections before use
    pool_recycle=3600,     # Recycle connections every hour
)
```

**Staging Backend** (same path):
```python
# Same configuration as above
```

**Dashboard** (`/opt/tovplay-dashboard/app.py`):
```python
# Reduce connection pool
engine = create_engine(
    DATABASE_URL,
    pool_size=2,           # Dashboard doesn't need many
    max_overflow=3,
    pool_pre_ping=True,
    pool_recycle=3600,
)
```

## Temporary Workaround (If Can't Access DB Server)

Wait 30-60 minutes for idle connections to timeout naturally (if `idle_in_transaction_session_timeout` is configured).

## Files Created for This Issue

- `F:\tovplay\restart_postgres_db.sh` - Script to restart via Webdock API (needs testing)
- This document

## Next Steps

1. User must manually restart PostgreSQL OR grant SSH access to 45.148.28.196
2. After restart, implement connection pooling in all backend applications
3. Set max_connections = 500 in PostgreSQL config
4. Monitor connection usage with `/opt/db_monitor.sh`

## SSH Access Needed

Current situation:
- SSH to 45.148.28.196 with admin@45.148.28.196 - **PASSWORD UNKNOWN**
- Webdock API script created but not tested
- Webdock web terminal is the fastest manual solution

## Until Fixed

- ALL audit scripts will fail when checking database
- Production/Staging backends may intermittently fail to serve requests
- Dashboard will not display real-time data
- New user registrations will fail
