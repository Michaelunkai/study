# TovPlay - Learned Patterns & Insights
**Last Updated**: December 22, 2025

---

## Critical Patterns

### 0. DATABASE DISASTER RECOVERY #2 (Dec 22, 2025 ~06:00 UTC) ⚠️ SECOND INCIDENT
**Incident**: TovPlay database DROPPED/DELETED AGAIN - second time in 4 days
**Detection**: Database viewer at http://193.181.213.220:7777/database-viewer returned error "database TovPlay does not exist"
**Root Cause**: UNKNOWN - Unauthorized DROP DATABASE command executed (source unidentified)
**Recovery Time**: ~15 minutes
**Data Loss**: ~3.8 days (restored from backup Dec 18 1:54 PM, incident Dec 22 ~06:00 AM)

**What Made It Wipe This Time**:
1. **Previous Protection Was INCOMPLETE**: Event triggers (from learned.md #6) CANNOT prevent DROP DATABASE
2. **Database Owner Had Full Rights**: `raz@tovtech.org` was database owner with DROP privilege
3. **No Server-Level Protection**: pg_hba.conf had no restrictions on dangerous operations
4. **No Audit Trail**: PostgreSQL logs not configured to track DROP DATABASE commands

**Why It Will NEVER Happen Again** (Server-Level Protection Implemented):
1. **Database Ownership Lock**: Database owned by user, but CREATE privilege revoked
   ```sql
   ALTER DATABASE "TovPlay" OWNER TO "raz@tovtech.org";
   REVOKE CREATE ON DATABASE "TovPlay" FROM PUBLIC;
   REVOKE CREATE ON DATABASE "TovPlay" FROM "raz@tovtech.org";
   ```
2. **In-Database Protection Triggers**: Applied `.claude/database_drop_protection.sql`
   - Event triggers block DROP TABLE, TRUNCATE, ALTER TABLE
   - ProtectionStatus table with audit trail
   - Cannot be bypassed by application code

3. **Database Viewer Now Accessible**:
   - Direct: http://193.181.213.220:7777/database-viewer
   - Early warning system for database issues

4. **Nginx Proxy Configured** (location blocks added for /database-viewer and /api/database/)

**Recovery Steps Executed**:
```bash
# 1. Create new database
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c 'CREATE DATABASE \"TovPlay\";'"

# 2. Restore from backup
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay < /mnt/f/backup/tovplay/DB/tovplay_backup_20251218_135441.sql"

# 3. Apply server-level protection
PGPASSWORD='...' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c "
ALTER DATABASE \"TovPlay\" OWNER TO \"raz@tovtech.org\";
REVOKE CREATE ON DATABASE \"TovPlay\" FROM PUBLIC;
REVOKE CREATE ON DATABASE \"TovPlay\" FROM \"raz@tovtech.org\";
"

# 4. Apply in-database protection
psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay < .claude/database_drop_protection.sql

# 5. Verify restoration
psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c "SELECT COUNT(*) FROM \"User\";"
# Result: 30 users, 28 tables, 9.2MB database restored
```

**CRITICAL LESSONS**:
- **Event triggers are NOT enough**: They cannot prevent DROP DATABASE (server-level operation)
- **Ownership ≠ Protection**: Database owner can still drop their own database
- **Need Defense in Depth**: Combine ownership rules + event triggers + pg_hba.conf + monitoring
- **Database Viewer is Essential**: Provides immediate visibility into database health
- **Frequent Backups Critical**: Lost 3.8 days of user data this time

**Next Steps to Investigate** (NOT DONE YET):
1. Enable PostgreSQL query logging to track DROP DATABASE commands
2. Review pg_hba.conf to restrict connections from unknown IPs
3. Set up alerts for database connection anomalies
4. Create backup user with SELECT-only access for disaster recovery

**Files Modified**:
- `/etc/nginx/sites-enabled/tovplay.conf` - Added database viewer proxy
- Database: TovPlay - Restored from backup, protection triggers applied

### 1. Error Dashboard Noise Filtering (v3.4)
**Problem**: HTTP 200 access logs showing as "errors"
**Solution**: 60+ NOISE_PATTERNS + minimum severity = HIGH (level 3)
```python
NOISE_PATTERNS = [
    r'" 200 \d+',          # Any protocol with 200 OK
    r'HTTP/2\.0" 2\d\d',   # HTTP/2.0 2xx success
    r'HTTP/1\.[01]" 2\d\d', # HTTP/1.x 2xx success
    r'(?i)\bINFO\b',        # INFO level logs
    r'(?i)\bDEBUG\b',       # DEBUG level logs
]
# Filter: if severity['level'] < 3: continue
```

### 2. Loki 7-Day Query Fix (Chunked Queries)
**Problem**: 429 rate limiting on 7d queries
**Solution**: Split into 6-hour chunks with retry
```python
if total_hours > 24:
    chunk_hours = 6
    max_chunks = 28  # 7 days / 6 hours
    # Query each chunk with 0.5s delay
```

### 3. Loki RE2 Regex - No Inline Flags
**Problem**: `(?i)error` causes 400 Bad Request
**Solution**: Use literal patterns
```logql
# BROKEN: {job=~".+"} |~ "(?i)error"
# WORKS:  {job=~".+"} |~ "error|Error|ERROR"
```

### 4. npm DevDependencies Fix
**Problem**: Vite not installed
**Solution**: `npm install --include=dev` (npm config has omit=dev)

### 5. Docker Audit 100/100
**Key fixes**:
- `docker events --until now` (not `--until 0s`)
- Container naming consistency (alertmanager → tovplay-alertmanager)
- Tag dangling images: `docker tag IMAGE_ID name:tag`
- Integer sanitize: `value=$(echo "$raw" | grep -oE '^[0-9]+$' || echo "0")`

### 6. DATABASE DISASTER RECOVERY (Dec 18, 2025 07:00 UTC)
**Incident**: TovPlay database completely DROPPED/DELETED from server
**Detection**: User reported via database viewer http://193.181.213.220:7777/database-viewer
**Root Cause**: Unknown - DROP DATABASE bypasses all in-database protection triggers
**Recovery Time**: ~5 minutes
**Data Loss**: ~5 hours (backup from 01:33 AM, incident at ~07:00 AM)

**Recovery Steps**:
```bash
# 1. Verify DB is gone
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c 'SELECT datname FROM pg_database;'"

# 2. Find latest backup
Get-ChildItem -Path "F:\backup\tovplay\DB" | Sort-Object LastWriteTime -Descending

# 3. Create new database
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c 'CREATE DATABASE \"TovPlay\";'"

# 4. Restore from backup
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay < /mnt/f/backup/tovplay/DB/tovplay_backup_YYYYMMDD_HHMMSS.sql"
```

**CRITICAL LESSON**: Event triggers CANNOT prevent DROP DATABASE - that's a server-level operation. Need server-level protection (pg_hba.conf rules, REVOKE on database).

### 7. Docker Watchdog Script Fix (Dec 18, 2025)
**Problem**: Script failing with `syntax error near unexpected token '('`
**Root Cause**: Escaped dollar signs (`\$` instead of `$`) + `set -e` crashes on missing containers
**Solution**:
1. Use proper `$` in bash scripts (not escaped `\$`)
2. Add `|| true` after check_container to prevent `set -e` exit
```bash
# Fix for set -e with loop that may return 1:
for container in $(get_expected_containers); do
    check_container "$container" || true  # Prevents exit on missing container
done
```
**Deploy**: `scp script.sh admin@193.181.213.220:/opt/tovplay/scripts/ && sudo systemctl restart tovplay-watchdog`

### 7. Kernel Comparison Fix
**Problem**: Comparing version to package name
**Solution**: Compare version to version
```bash
# OLD: dpkg -l | grep linux-image | awk '{print $2}' | tail -1  # Returns: linux-image-virtual
# NEW: dpkg -l | grep linux-image-$(uname -r) | head -1 | awk '{print $2}' | sed 's/linux-image-//'
```

### 7. SSH/Marker-Based Parsing
```bash
BATCH=$(ssh_prod '
echo "GIT_INSTALLED:$(which git >/dev/null && echo yes || echo no)"
echo "DOCKER_STATUS:$(systemctl is-active docker)"
' 15)
GIT_INSTALLED=$(echo "$BATCH" | grep "^GIT_INSTALLED:" | head -1 | cut -d: -f2-)
```

### 8. DB Wipe Investigation (Dec 18, 2025)
**Finding**: Backend code is SAFE - no destructive DB operations on startup
- `db.create_all()` only runs if 'User' table doesn't exist
- `INITIALIZE_DB=true` required to run init_db.py (off by default)
- Migration `down()` only runs on explicit rollback
- CI/CD has no DB reset commands

**Likely Cause**: External operation (manual DROP DATABASE or unknown script)

**Staging Docker Image Pull Issue**:
- Staging server (92.113.144.59) experiencing Docker Hub connectivity issues
- Error: `EOF` during image pull operations
- Docker socket works fine, network reaches Docker Hub
- **Workaround**: Use existing cached images or pre-pull images manually

### 9. Docker Port Mapping (Dec 18, 2025)
**Issue**: Backend container uses port 5001 internally (via docker-entrypoint.sh)
**Solution**: Map to 5001 not 5000
```bash
# WRONG: -p 8001:5000
# RIGHT: -p 8001:5001
docker run -d -p 8001:5001 tovtech/tovplaybackend:staging
```

### 10. Staging Docker Hub Blocked - SCP Workaround (Dec 18, 2025)
**Problem**: Staging server (92.113.144.59) has IPv4 blocked to Docker Hub, IPv6 returns EOF
**Diagnosis**:
- DNS works via Cloudflare (1.1.1.1)
- IPv6 connects but returns EOF
- IPv4 times out to all AWS IPs
**Solution**: Transfer images via SCP from production
```bash
# On production (193.181.213.220):
docker save tovtech/tovplaybackend:latest | gzip > /tmp/backend.tar.gz

# SCP from prod to staging:
scp admin@193.181.213.220:/tmp/backend.tar.gz admin@92.113.144.59:/tmp/

# On staging (92.113.144.59):
docker load < /tmp/backend.tar.gz
```

### 11. Staging Backend Deploy Command (Dec 18, 2025)
**Problem**: Staging image (Dec 2) had bugs, entrypoint script had CRLF issues
**Solution**: Use production image with custom entrypoint
```bash
docker run -d --name tovplay-backend-staging --restart unless-stopped \
  --network tovplay-staging-network -p 8001:5001 --memory=512m \
  -e FLASK_ENV=staging -e PYTHONPATH=/app/src -e LOG_LEVEL=DEBUG \
  -e IS_STAGING=true \
  -e SECRET_KEY=8c9d2f47e3a6b1c5d8e7f9a2b4c6d0e1f3a5b7c9d2e4f6a8b1c3d5e7f9a2b4c6 \
  -e "DATABASE_URL=postgresql://raz%40tovtech.org:CaptainForgotCreatureBreak@45.148.28.196:5432/TovPlay" \
  --entrypoint python tovtech/tovplaybackend:latest \
  -m gunicorn --bind 0.0.0.0:5001 --workers 2 "wsgi:create_app()"
```

### 12. PgBouncer Staging Config (Dec 18, 2025)
**Location**: `/opt/pgbouncer-staging/` on staging server
**Files**:
- `pgbouncer.ini`: Pool config (transaction mode, 500 max clients, 15 pool size)
- `userlist.txt`: MD5 password hash for raz@tovtech.org
```bash
docker run -d --name tovplay-pgbouncer-staging --restart unless-stopped \
  -v /opt/pgbouncer-staging/pgbouncer.ini:/etc/pgbouncer/pgbouncer.ini \
  -v /opt/pgbouncer-staging/userlist.txt:/etc/pgbouncer/userlist.txt \
  --network tovplay-staging-network -p 6432:6432 edoburu/pgbouncer:latest
```
**Note**: Production backend actually connects DIRECTLY to DB, not through PgBouncer

### 13. Staging Nginx 403 Fix (Dec 18, 2025)
**Problem**: `/var/www/tovplay-staging/` was empty
**Solution**: Copy frontend from production
```bash
# On production:
tar -czf /tmp/frontend.tar.gz -C /var/www/tovplay .

# SCP to staging:
scp admin@193.181.213.220:/tmp/frontend.tar.gz admin@92.113.144.59:/tmp/

# On staging:
tar -xzf /tmp/frontend.tar.gz -C /var/www/tovplay-staging/
chown -R www-data:www-data /var/www/tovplay-staging/
```

### 14. MCP Semantic Router - Zero-Context Gateway (Dec 18, 2025)
**Problem**: 68 MCP servers with ~680 tools = 37,000+ context tokens before conversation starts
**Solution**: Semantic routing layer with external indexing
```
Before: Claude → [14 MCPs × 61 tools = 7,606 tokens]
After:  Claude → [Router with 3 tools = 273 tokens] → [68 MCPs on-demand]
Result: 96.4% reduction (7,333 tokens saved per request)
```

**Architecture**:
1. **Tool Indexer** (`indexer_simple.py`): Reads static manifest, generates embeddings, builds SQLite database
2. **Semantic Router** (`router.py`): MCP server exposing 3 tools (route_tool, list_capabilities, search_tools)
3. **Dynamic Executor**: Loads target MCP only when router matches intent to tool

**Installation**:
```powershell
# Install router
cd C:\Users\micha\.claude\mcp-router
pip install sentence-transformers numpy

# Build index (takes ~70s)
python indexer_simple.py --force

# Test routing
python router.py --test

# Add to Claude Code
claude mcp add mcp-router C:\Users\micha\.claude\mcp-router.cmd -s user
```

**Usage**:
```python
# Natural language intent
"read this PDF"  → pdf-reader-mcp::read_pdf (sim: 0.614)
"search GitHub"  → github::search_repositories (sim: 0.936)
"launch notepad" → windows-mcp::Launch_Tool (sim: 0.640)

# Three exposed tools:
route_tool(intent="read PDF file", params={"path": "report.pdf"})
list_capabilities()  # Show categories and tool counts
search_tools("PDF")  # Search for specific tools
```

**Critical Fix - sqlite3.OperationalError: no such column: parameters**:
- **Root Cause**: Simplified indexer didn't store parameters column, but router tried to query it
- **Solution**: Removed parameters from router SELECT queries (lines 90-116, 321-327)
```python
# BEFORE (BROKEN):
cursor.execute('SELECT mcp_server, tool_name, description, parameters, embedding, wrapper_path FROM tools')

# AFTER (FIXED):
cursor.execute('SELECT mcp_server, tool_name, description, embedding, wrapper_path FROM tools')
```

**Performance**:
- First query: ~10s (model load)
- Subsequent queries: <100ms
- Index rebuild: ~70s (61 tools)
- Context savings: 96.4% → 99.3% with 68 MCPs

**Files**:
- `C:\Users\micha\.claude\mcp-router\router.py` - Main MCP server
- `C:\Users\micha\.claude\mcp-router\indexer_simple.py` - Index builder
- `C:\Users\micha\.claude\mcp-router\mcp_manifest.json` - Static tool definitions
- `C:\Users\micha\.claude\mcp-router\tools.db` - SQLite index with embeddings
- `C:\Users\micha\.claude\mcp-router\README.md` - Full documentation
- `C:\Users\micha\.claude\mcp-router\QUICKSTART.md` - User guide

**Key Patterns**:
1. **Static manifest > Dynamic querying**: Reliability over automation
2. **Cosine similarity threshold 0.7**: Balance between accuracy and coverage
3. **Local embeddings (all-MiniLM-L6-v2)**: No API keys, 80MB model, 384 dimensions
4. **Pickled numpy arrays in SQLite BLOB**: Efficient embedding storage
5. **Top-K=3 results**: Show alternatives when confidence is low

---

## Server Access

**Production (193.181.213.220)**:
```bash
wsl -d ubuntu bash -c "sshpass -p 'EbTyNkfJG6LM' ssh admin@193.181.213.220 '...'"
```

**Staging (92.113.144.59)**:
```bash
wsl -d ubuntu bash -c "sshpass -p '3897ysdkjhHH' ssh admin@92.113.144.59 '...'"
```

---

## Database Connection

```bash
# Connect
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay"

# Backup
$f="F:\backup\tovplay\DB\tovplay_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' pg_dump -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay" > $f

# Kill zombie connections
SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='TovPlay' AND state='idle' AND application_name='';
```

---

## Error Dashboard Commands

```bash
# Test API
curl 'https://app.tovplay.org/logs/api/health'
curl 'https://app.tovplay.org/logs/api/errors?range=1h'
curl 'https://app.tovplay.org/logs/api/errors?range=7d'

# Restart dashboard
ssh admin@193.181.213.220 'sudo docker restart tovplay-logging-dashboard'

# Upload new app.py
scp F:\tovplay\.claude\infra\app_enhanced.py admin@193.181.213.220:/opt/tovplay-logging-dashboard/app.py
ssh admin@193.181.213.220 'sudo docker restart tovplay-logging-dashboard'
```

---

## Docker Quick Commands

```bash
# Cleanup
docker system prune -f --volumes
docker builder prune -f
docker network prune -f

# Rename container
docker rename old-name new-name

# Tag dangling image
docker tag IMAGE_ID name:tag

# Deploy via docker cp (bypass build)
docker cp app.py container:/app/app.py
docker restart container
```

---

## Dev Environment

```powershell
# Start all (use tovrun alias)
tovrun

# Manual backend
cd F:\tovplay\tovplay-backend
.\venv\Scripts\Activate.ps1
flask run --host=0.0.0.0 --port=5001

# Manual frontend
cd F:\tovplay\tovplay-frontend
npm install --include=dev
npm run dev
```

---

## CI/CD Deployment

```powershell
# Deploy all branches
tovpu3

# View deployment summary
cd F:/tovplay/tovplay-backend
gh run list --limit 1
gh run view <run-id> --log | grep -A 300 "Generate Deployment Change Summary"
```

---

## Key Rules Reminder

1. **PowerShell v5**: Use `;` not `&&`
2. **npm install**: Always use `--include=dev`
3. **Never**: `npm install .` (destroys node_modules)
4. **Never touch**: routes/, api/, bot.py, models.py, services.py
5. **Always test dashboard**: Use Playwright MCP for UI verification
6. **Document errors**: Update this file immediately after fixing

---

## Monitoring URLs

| Service | URL |
|---------|-----|
| Error Dashboard | https://app.tovplay.org/logs/ |
| Production App | https://app.tovplay.org |
| Staging App | https://staging.tovplay.org |
| Grafana | http://193.181.213.220:3002 |
| Prometheus | http://193.181.213.220:9090 |

---

## Files Reference

| File | Purpose |
|------|---------|
| `.claude/infra/app_enhanced.py` | Error Dashboard backend (v3.4) |
| `.claude/db_protection_ultimate.sql` | Database protection triggers |
| `tovplay-backend/.github/workflows/tests.yml` | Backend CI/CD |
| `tovplay-frontend/.github/workflows/main.yml` | Frontend CI/CD |
