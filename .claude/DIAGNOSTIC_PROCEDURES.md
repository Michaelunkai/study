# TovPlay - Step-by-Step Diagnostic Procedures
**For**: DevOps Team (Roman Fesunenko)
**Purpose**: Structured troubleshooting workflows
**Last Updated**: December 22, 2025

---

## 🔍 DIAGNOSTIC WORKFLOW: Complete System Check

### Step 1: Production Server Status (5 min)

```powershell
# SSH into production
ssh admin@193.181.213.220

# Check system resources
echo "=== CPU & MEMORY ==="
top -b -n 1 | head -20

echo "=== DISK USAGE ==="
df -h

echo "=== DOCKER CONTAINERS ==="
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "=== RUNNING PROCESSES ==="
ps aux | grep -E "python|node|nginx" | grep -v grep
```

**Expected Output**:
- All CPU usage <80%
- Disk usage <85%
- All Docker containers showing "Up"
- Python (backend), Node (not on prod), nginx (frontend)

**If anything is red**: Note the issue and continue to Step 2.

---

### Step 2: Backend Service Health (3 min)

```bash
# On production server

# Check container logs (last 50 lines)
sudo docker logs tovplay-backend --tail 50

# Check if listening on port 8000
sudo netstat -tuln | grep 8000

# Test health endpoint
curl http://localhost:8000/health -s -w "\nStatus: %{http_code}\n"

# Check PgBouncer (connection pool)
sudo netstat -tuln | grep 6432
```

**Expected Output**:
- No ERROR or CRITICAL in logs
- LISTEN on 0.0.0.0:8000
- Health endpoint returns 200 with timestamp
- PgBouncer LISTEN on 0.0.0.0:6432

**Failures**:
- Backend not listening → `sudo docker restart tovplay-backend`
- PgBouncer issue → `sudo docker restart pgbouncer`
- Health check 502 → Database connection problem (see Step 3)

---

### Step 3: Database Connection Test (5 min)

```powershell
# From your local machine (Windows)

# Test database connectivity
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c '\dt' | head -20"

# Expected: List of tables (users, games, matchmaking, etc.)

# Check table count
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT count(*) as table_count FROM information_schema.tables WHERE table_schema='\''public'\'';'"

# Expected: 28 tables (after latest restore)

# Check database size
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT pg_size_pretty(pg_database_size(current_database()));'"

# Expected: ~9.2MB (or similar)

# Check active connections
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT count(*) as active_connections FROM pg_stat_activity;'"

# Expected: <10 (fewer is better)
```

**If database is unreachable**:
1. Check network connectivity: `ping 45.148.28.196`
2. Wait 30 seconds (may be restarting)
3. Contact hosting provider if still down

**If tables are missing**: Database restore needed (see Emergency Recovery below)

---

### Step 4: Frontend Service Check (3 min)

```bash
# On production server

# Check nginx is running
sudo systemctl status nginx

# Check frontend files exist
ls -la /var/www/tovplay/ | head -10

# Check nginx config
sudo nginx -t

# Test frontend endpoint
curl http://localhost -s -w "\nStatus: %{http_code}\n" | head -5
```

**Expected Output**:
- nginx showing "active (running)"
- /var/www/tovplay/ contains: dist/, index.html, css/, js/
- nginx config test shows "successful"
- HTTP 200 response

**Failures**:
- nginx not running → `sudo systemctl start nginx`
- Files missing → Frontend not deployed
- Port 80 not listening → Check nginx config and restart

---

### Step 5: Monitoring Stack Check (5 min)

```bash
# On production server

# Check Prometheus
curl http://localhost:9090/api/v1/status/tsdb -s | jq '.status'

# Check Grafana
curl http://localhost:3002/api/health -s | jq '.status'

# Check Loki logs
curl http://localhost:3100/loki/api/v1/status/buildinfo -s | jq '.version'

# Check Promtail
sudo docker logs promtail --tail 20
```

**Expected Output**:
- Prometheus: "success"
- Grafana: "ok"
- Loki: Version number
- Promtail: No ERRORs in logs

**Note**: Staging may not have these (Docker Hub blocked). Production should have all.

---

### Step 6: Database Viewer Check (2 min)

```bash
# On production server, test database viewer API

curl http://localhost:7777/api/health -s -w "\nStatus: %{http_code}\n"

# Should return 200 and JSON with status

# Check dashboard is accessible
curl https://app.tovplay.org/api/database-health -s | jq '.'
```

**Expected**: 200 status and JSON response with table counts

---

## 🔴 TROUBLESHOOTING: Problem-Specific Workflows

### Problem: "502 Bad Gateway" in Browser

**Diagnosis** (run in order):

```bash
# 1. Is backend listening?
sudo netstat -tuln | grep 8000
# Expected: LISTEN on :8000

# 2. Are there backend logs?
sudo docker logs tovplay-backend --tail 50 | grep -i error
# Expected: No recent ERRORs

# 3. Can we reach backend directly?
curl http://localhost:8000/health
# Expected: 200 status

# 4. Is PgBouncer working?
sudo docker exec pgbouncer psql -U postgres -p 6432 -d postgres -c "SHOW version;"
# Expected: version output
```

**Fixes** (in order):

1. If backend not listening:
   ```bash
   sudo docker restart tovplay-backend
   sleep 5
   curl http://localhost:8000/health
   ```

2. If PgBouncer issue:
   ```bash
   sudo docker restart pgbouncer
   sleep 3
   sudo docker restart tovplay-backend
   ```

3. If database unreachable:
   ```bash
   # Check database exists
   PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c "SELECT datname FROM pg_database WHERE datname='TovPlay';"
   # If no output, database dropped → Emergency recovery below
   ```

---

### Problem: "Database does not exist" Error

**Diagnosis**:

```powershell
# Check if TovPlay database exists
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -l | grep TovPlay"

# If empty result: Database has been dropped
# If shows: TovPlay | raz@tovtech.org | UTF8, then it exists but may be corrupted
```

**Recovery**:

See "Emergency Recovery: Database Dropped" section below.

---

### Problem: Database Connections Exhausted

**Diagnosis**:

```powershell
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT count(*) as total, state FROM pg_stat_activity GROUP BY state;'"

# If total count > 100 or many "idle" connections:
# System is leak ing connections
```

**Immediate Fix**:

```powershell
# Kill all idle connections
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE state='\''idle'\'';'"

# Restart backend to clear its connection pool
ssh admin@193.181.213.220 'sudo docker restart tovplay-backend'
```

**Permanent Fix**:
- Ensure backend app uses connection pooling (PgBouncer)
- Monitor connection count daily: http://193.181.213.220:7777/database-viewer

---

### Problem: Slow Database Queries

**Diagnosis**:

```powershell
# Check for long-running queries
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT pid, query, query_start FROM pg_stat_activity WHERE query NOT LIKE '\''%pg_stat%'\'' AND query_start < NOW() - interval '\''1 minute'\'';'"

# If queries running >1 minute: investigate query performance

# Check table bloat
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'\''.'\''||tablename)) FROM pg_tables WHERE schemaname NOT IN ('\''pg_catalog'\'', '\''information_schema'\'') ORDER BY pg_total_relation_size(schemaname||'\''.'\''||tablename) DESC;'"
```

**Fix**:
- VACUUM tables with high bloat: `VACUUM ANALYZE <tablename>;`
- Cancel long queries: `SELECT pg_cancel_backend(<pid>);`
- Check if indexes are needed on frequently filtered columns

---

## 🚨 EMERGENCY PROCEDURES

### Emergency: Database Dropped

**Timeline**: <5 minutes to restore

```powershell
# STEP 1: Verify database is gone
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -l | grep TovPlay"
# If no output: confirmed dropped

# STEP 2: Create empty database
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c 'CREATE DATABASE \"TovPlay\";'"

# STEP 3: Find latest backup
Get-ChildItem "F:\backup\tovplay\DB\" | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# STEP 4: Restore from latest backup
$latest = Get-ChildItem "F:\backup\tovplay\DB\" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Write-Host "Restoring from: $($latest.FullName)"
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay < '$($latest.FullName)'" 2>&1

# STEP 5: Verify restore
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT count(*) as table_count FROM information_schema.tables WHERE table_schema='\''public'\'';'"
# Expected: 28 tables

# STEP 6: Reapply protection
wsl -d ubuntu bash -c "cat F:\tovplay\.claude\database_drop_protection.sql | PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay"

# STEP 7: Restart backend
ssh admin@193.181.213.220 'sudo docker restart tovplay-backend'

# STEP 8: Verify health
curl https://app.tovplay.org/logs/api/health

echo "✅ Database restored successfully!"
```

---

### Emergency: Backend Service Not Starting

```bash
# On production server

# STEP 1: Check container logs
sudo docker logs tovplay-backend -f --tail 100

# STEP 2: Check for Python errors
sudo docker exec tovplay-backend python -m py_compile /app/src/app/__init__.py

# STEP 3: Check environment variables
sudo docker exec tovplay-backend env | grep DATABASE_URL

# STEP 4: Try manual restart with more logging
sudo docker stop tovplay-backend
sleep 3
sudo docker run --name tovplay-backend-debug -it -e LOG_LEVEL=DEBUG tovplay-backend:latest

# STEP 5: If still failing, check if database is accessible
sudo docker exec -it tovplay-backend bash
# Then in container:
python -c "import sqlalchemy; print(sqlalchemy.create_engine(os.environ['DATABASE_URL']).execute('SELECT 1'))"

# STEP 6: If database issue, run database recovery
# (See: Emergency: Database Dropped)
```

---

### Emergency: Staging Docker Hub Blocked

**Workaround**: SCP images from production

```bash
# On production server: Save image
sudo docker save tovplay-backend:latest -o /tmp/tovplay-backend.tar
sudo docker save tovplay-frontend:latest -o /tmp/tovplay-frontend.tar

# On your machine:
scp admin@193.181.213.220:/tmp/tovplay-backend.tar .
scp admin@193.181.213.220:/tmp/tovplay-frontend.tar .

# On staging server: Load image
sudo docker load -i /tmp/tovplay-backend.tar
sudo docker load -i /tmp/tovplay-frontend.tar

# Verify
sudo docker images | grep tovplay
```

---

## 📊 MONITORING HEALTH CHECKS

### Quick Health Check Script

Save this as `health-check.ps1`:

```powershell
Write-Host "TovPlay System Health Check - $(Get-Date)" -ForegroundColor Cyan
Write-Host "======================================"

# 1. Backend API
Write-Host "`n[1/5] Backend API Health..." -ForegroundColor Yellow
try {
    $response = curl https://app.tovplay.org/logs/api/health -s
    if ($response -like "*timestamp*") {
        Write-Host "✅ Backend API: OK" -ForegroundColor Green
    } else {
        Write-Host "❌ Backend API: Unexpected response" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Backend API: Unreachable" -ForegroundColor Red
}

# 2. Database
Write-Host "`n[2/5] Database Health..." -ForegroundColor Yellow
try {
    $db_check = wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT count(*) FROM information_schema.tables;'" 2>&1
    if ($db_check -match '\d+') {
        Write-Host "✅ Database: Connected" -ForegroundColor Green
    } else {
        Write-Host "❌ Database: Connection failed" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Database: Error checking" -ForegroundColor Red
}

# 3. Frontend
Write-Host "`n[3/5] Frontend Health..." -ForegroundColor Yellow
try {
    $status = curl https://app.tovplay.org/ -s -w "%{http_code}" -o $null
    if ($status -eq "200") {
        Write-Host "✅ Frontend: OK" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Frontend: HTTP $status" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Frontend: Unreachable" -ForegroundColor Red
}

# 4. Staging
Write-Host "`n[4/5] Staging Environment..." -ForegroundColor Yellow
try {
    $status = curl https://staging.tovplay.org/ -s -w "%{http_code}" -o $null
    if ($status -eq "200") {
        Write-Host "✅ Staging: OK" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Staging: HTTP $status" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Staging: Unreachable" -ForegroundColor Red
}

# 5. Database Viewer
Write-Host "`n[5/5] Database Viewer..." -ForegroundColor Yellow
try {
    $status = curl http://193.181.213.220:7777/database-viewer -s -w "%{http_code}" -o $null
    if ($status -eq "200") {
        Write-Host "✅ Database Viewer: OK" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Database Viewer: HTTP $status" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Database Viewer: Unreachable" -ForegroundColor Red
}

Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "Check complete!" -ForegroundColor Cyan
```

**Run with**: `powershell -ExecutionPolicy Bypass -File health-check.ps1`

---

## 🎯 INCIDENT LOG TEMPLATE

When investigating an issue, record:

```markdown
## Incident Report
**Date**: YYYY-MM-DD HH:MM UTC
**Duration**: X minutes
**Impact**: [Users affected / Services affected]
**Severity**: [P1-Critical / P2-High / P3-Medium / P4-Low]

### Timeline
- HH:MM - Issue detected
- HH:MM - Root cause identified
- HH:MM - Fix applied
- HH:MM - Verified resolved

### Root Cause
[What actually caused it]

### Solution Applied
[What was done]

### Prevention
[What to do next time]

### Follow-up
- [ ] Update monitoring
- [ ] Document in learned.md
- [ ] Schedule post-mortem if P1/P2
```

---

**Last Updated**: December 22, 2025
**Next Review**: January 22, 2026
**Contact**: Roman Fesunenko (DevOps Lead)
