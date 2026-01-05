# CI/CD Audit Investigation - December 5, 2025

## Summary
Investigated CI/CD audit scoring (improved from 0/100 → 9/100). Root causes identified: containers running as root, database connection errors, audit script false positives.

---

## Current Score: 9/100 (Improved from 0/100)

### Scoring Breakdown
- **0 CRITICAL** (previously 1) ✓ Fixed: Node.js installed on Staging
- **4 HIGH** (investigation needed)
- **6 MEDIUM** (partially investigated)
- **1 LOW** (Git update available)

---

## Root Cause Categories

### 1. Database-Caused Issues (BLOCKED - Requires DB Restart)
**Issue**: PostgreSQL connection exhaustion on 45.148.28.196
**Impact**: Causes container errors in logs
- tovplay-backend: 320 errors ("FATAL: sorry, too many clients already")
- tovplay-loki: 1055 errors (DB connection failures)
- tovplay-promtail: 1055 errors (DB connection failures)

**Status**: BLOCKED - Requires manual PostgreSQL restart by user
**Expected**: These errors will disappear once database is restarted

### 2. Containers Running as Root (MEDIUM Security Issue)
**Finding**: `docker exec <container> id` revealed:
- ✓ tovplay-loki: uid=10001(loki) - GOOD
- ✓ grafana-standalone: uid=472(grafana) - GOOD
- ✓ tovplay-prometheus: uid=65534(nobody) - GOOD
- ❌ tovplay-promtail: uid=0(root) - **SECURITY ISSUE**

**Root Cause**: Promtail container has no user specified in configuration
```bash
docker inspect tovplay-promtail --format="{{.Config.User}}"
# Output: (empty) → defaults to root
```

**Impact**:
- Security vulnerability (containers should not run as root)
- Triggers MEDIUM issue in CI/CD audit
- Increases attack surface if container is compromised

**Fix Options**:
1. **Option 1 - Recreate container with non-root user**:
   ```bash
   docker run -d --name tovplay-promtail \
     --user 10001:10001 \
     --restart unless-stopped \
     grafana/promtail:2.9.3 \
     [... other flags ...]
   ```

2. **Option 2 - Add to docker-compose if managed**:
   ```yaml
   promtail:
     image: grafana/promtail:2.9.3
     container_name: tovplay-promtail
     user: "10001:10001"  # Add this line
   ```

**Status**: **NOT YET FIXED** - Requires:
1. Finding the full docker run command or compose file that starts promtail
2. Stopping the container
3. Recreating with --user flag
4. Verifying promtail still has access to log files

**Investigation Status**:
- ✓ Identified root user issue
- ✓ Confirmed image: grafana/promtail:2.9.3
- ❌ Could not locate docker-compose file that manages Loki/Promtail
- Containers appear to be started with `docker run` commands, not docker-compose

### 3. Audit Script False Positives (HIGH Issues)
**Finding**: Audit script checks for issues that don't apply to Docker-based deployments

**Examples**:
- Checks `/opt/tovplay-backend` but actual path is `/root/tovplay-backend`
- Checks for systemd services but apps run in Docker containers
- Reports "Service tovplay-backend not running" but `docker ps` shows it IS running

**Status**: These are NOT real issues - audit script needs updates to check Docker containers

### 4. Network/Registry Issues (MEDIUM - Staging Only)
**Finding**: npm Registry, Docker Hub, PyPI unreachable from Staging server

**Status**: Low priority - likely firewall or network configuration issue on Staging

### 5. Git Repository Issues (MEDIUM + LOW)
**Issues**:
- MEDIUM: Repository tovplay-dashboard last commit 20427 days ago
- MEDIUM: Repository tovplay-dashboard has no remote
- LOW: Git update available on Staging

**Status**: Low priority - documentation/maintenance issues, not infrastructure problems

---

## Files & Paths Investigated

### Docker Compose Files Found:
1. `/opt/monitoring/docker-compose.yml` - Monitoring stack (Prometheus, Grafana, Node Exporter, cAdvisor, etc.)
   - **Does NOT include Loki or Promtail**
2. `/root/tovplay-backend/docker-compose.production.yml` - Backend only
3. `/root/tovplay-backend/docker-compose.staging.yml`
4. `/root/tovplay-backend/docker-compose.dev.yml`
5. `/root/tovplay-backend/docker-compose.yml`

### Running Containers (Production):
```
tovplay-loki         grafana/loki:2.9.3
tovplay-backend      tovtech/tovplaybackend:latest
grafana-standalone   grafana/grafana:latest
tovplay-prometheus   prom/prometheus:latest
tovplay-promtail     grafana/promtail:2.9.3
```

---

## Action Plan

### Immediate (After DB Restart):
1. Re-run `cicd_report.sh` - expect container errors to disappear
2. Score should improve significantly

### Short-term (Fixable Now):
1. **Fix tovplay-promtail root user**:
   - Find how promtail is started (docker run command or systemd service)
   - Recreate container with `--user 10001:10001`
   - Verify log access still works
   - Expected score increase: +5-10 points

2. **Address low-priority items**:
   - Git update on Staging
   - Dashboard repository maintenance

### Long-term (Nice to Have):
1. **Fix audit script false positives**:
   - Update script to check Docker containers instead of systemd services
   - Update paths to match actual Docker deployment structure
   - Expected score increase: +10-20 points

---

## Score Projection

| Component | Current | After DB Fix | After Promtail Fix | After All Fixes |
|-----------|---------|--------------|-------------------|-----------------|
| CI/CD     | 9/100   | ~30-40/100   | ~40-50/100        | ~60-80/100      |

**Note**: Perfect 100/100 unlikely due to audit script limitations and minor operational items that don't affect functionality.

---

## Recommendation

**Priority Order**:
1. **Wait for Database Restart** (user action required) - Expected: +20-30 score increase
2. **Fix Promtail Root User** (can do now) - Expected: +10 score increase
3. **Fix Git/Network Issues** (low priority) - Expected: +5-10 score increase
4. **Update Audit Script** (optional) - Expected: +10-20 score increase

**Current Status**: Investigation complete. Ready to fix promtail user once we locate startup configuration.

---

## Files Created This Session
- This document: `F:\tovplay\.claude\CICD_INVESTIGATION_DEC5.md`
