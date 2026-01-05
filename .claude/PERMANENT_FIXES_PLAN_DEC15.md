# TovPlay Permanent Fixes Plan - December 15, 2025

## GOAL: Achieve 100/100 across all systems with real-time debugging

---

## PHASE 1: CRITICAL SECURITY FIXES (IMMEDIATE)

### Fix 1: Disable Empty Passwords
**Module**: SECURITY (28/100)
**Priority**: 🔴 CRITICAL
**Location**: Production server (193.181.213.220)
**Steps**:
```bash
# SSH to production
wsl -d ubuntu bash -c "sshpass -p 'EbTyNkfJG6LM' ssh admin@193.181.213.220"

# Edit /etc/shadow to remove empty passwords
sudo sed -i 's/::\([^:]*$\)/:!:\1/g' /etc/shadow

# Verify
sudo cat /etc/shadow | grep -E '::' | wc -l  # Should be 0

# Test each user can't login with empty password
su - testuser  # Should fail
```
**Verification**: No users with empty passwords in /etc/shadow
**Expected Result**: SECURITY score rises to 42/100

---

### Fix 2: Remove Non-Root UID 0 Users
**Module**: SECURITY (28/100)
**Priority**: 🔴 CRITICAL
**Location**: Production /etc/passwd
**Steps**:
```bash
# Find all UID 0 users (only root should have it)
sudo awk -F: '$3 == 0 && $1 != "root"' /etc/passwd

# For each non-root UID 0 user:
sudo usermod -u 1000 username  # Reassign UID

# Verify only root has UID 0
sudo awk -F: '$3 == 0' /etc/passwd  # Should show only root
```
**Verification**: `sudo awk -F: '$3 == 0 && $1 != "root"' /etc/passwd` returns empty
**Expected Result**: SECURITY score rises to 54/100

---

## PHASE 2: DOCKER & MONITORING RESTORATION (HIGH PRIORITY)

### Fix 3: Restore Backend Container Health
**Module**: DOCKER (13/100)
**Priority**: 🔴 HIGH
**Location**: Production /home/admin/tovplay
**Steps**:
```bash
# SSH to production
wsl -d ubuntu bash -c "sshpass -p 'EbTyNkfJG6LM' ssh admin@193.181.213.220"

# Check current container status
docker ps -a
docker logs tovplay-backend --tail 50

# Restart backend with proper health checks
docker restart tovplay-backend
docker ps -a | grep tovplay-backend

# Wait 30s for health check
sleep 30

# Verify health status
docker inspect tovplay-backend | grep -A 5 Health
```
**Expected Result**: Backend shows "healthy" status

---

### Fix 4: Enable Prometheus Monitoring
**Module**: DOCKER (13/100)
**Priority**: 🟠 HIGH
**Location**: Production docker-compose.yml
**Steps**:
```bash
# SSH to production
cd /home/admin/tovplay

# Check if prometheus image exists
docker images | grep prometheus

# If exited, restart:
docker-compose up -d tovplay-prometheus
docker ps | grep prometheus  # Should show "Up"

# Verify metrics endpoint
curl http://localhost:9090/api/v1/targets
```
**Expected Result**: Prometheus running and scraping metrics

---

### Fix 5: Enable Loki Logging
**Module**: DOCKER (13/100)
**Priority**: 🟠 HIGH
**Location**: Production /home/admin/tovplay
**Steps**:
```bash
docker-compose up -d tovplay-loki
docker-compose up -d tovplay-promtail

# Verify Loki is scraping logs
curl http://localhost:3100/loki/api/v1/label/job/values
```
**Expected Result**: Loki and Promtail running and collecting logs

---

## PHASE 3: DATABASE OPTIMIZATION (MEDIUM PRIORITY)

### Fix 6: Fix Connection Pool Exhaustion
**Module**: DATABASE (88/100)
**Priority**: 🟡 MEDIUM
**Location**: Database /etc/postgresql/postgresql.conf
**Steps**:
```bash
# SSH to production
ssh admin@193.181.213.220

# Connect to database as admin
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay

# Current settings
SHOW max_connections;  # Currently: 100, Used: 101/100 - PROBLEM!

# Update in postgresql.conf
sudo vim /etc/postgresql/15/main/postgresql.conf
# Find: max_connections = 100
# Change to: max_connections = 200

# Restart PostgreSQL
sudo systemctl restart postgresql

# Verify
SHOW max_connections;  # Should show 200

# Check connection count
SELECT count(*) FROM pg_stat_activity;
```
**Expected Result**: max_connections = 200, connection usage < 100

---

### Fix 7: Add Missing Database Indexes
**Module**: DATABASE (88/100)
**Priority**: 🟡 MEDIUM
**Location**: TovPlay database
**Tables with missing indexes**: User, Game, UserProfile, ScheduledSession, GameRequest
**Steps**:
```sql
-- Connect to database
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay

-- Add indexes for high-scan tables
CREATE INDEX idx_user_email ON public.User(email);
CREATE INDEX idx_game_name ON public.Game(name);
CREATE INDEX idx_user_profile_user_id ON public.UserProfile(user_id);
CREATE INDEX idx_scheduled_session_user ON public.ScheduledSession(user_id);
CREATE INDEX idx_game_request_user ON public.GameRequest(user_id);

-- Verify indexes were created
\d public.User  -- Should show email index

-- Analyze tables to update stats
ANALYZE public.User;
ANALYZE public.Game;
ANALYZE public.UserProfile;
ANALYZE public.ScheduledSession;
ANALYZE public.GameRequest;
```
**Expected Result**: Database score rises to 92/100

---

## PHASE 4: NGINX & SECURITY HEADERS (MEDIUM PRIORITY)

### Fix 8: Enable HSTS in Nginx
**Module**: NGINX (81/100)
**Priority**: 🟡 MEDIUM
**Location**: /etc/nginx/sites-enabled/tovplay.conf
**Steps**:
```bash
# SSH to production
ssh admin@193.181.213.220

# Edit nginx config
sudo vim /etc/nginx/sites-enabled/tovplay.conf

# Add to server block (inside https block):
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# Test nginx config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Verify header is set
curl -I https://app.tovplay.org | grep -i strict-transport
```
**Expected Result**: HSTS header present in all HTTPS responses

---

### Fix 9: Add Complete Security Headers
**Module**: NGINX (81/100)
**Priority**: 🟡 MEDIUM
**Location**: /etc/nginx/sites-enabled/tovplay.conf
**Steps**:
```bash
# Add to nginx server block:
cat >> /tmp/security-headers.conf << 'EOF'
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'" always;
add_header Permissions-Policy "geolocation=(), camera=(), microphone=()" always;
EOF

# Merge into config (manual edit required)
sudo nano /etc/nginx/sites-enabled/tovplay.conf

# Test and reload
sudo nginx -t && sudo systemctl reload nginx
```
**Expected Result**: NGINX score rises to 94/100

---

## PHASE 5: INFRASTRUCTURE & TIME SYNC (LOW PRIORITY)

### Fix 10: Synchronize System Time
**Module**: INFRASTRUCTURE (85/100)
**Priority**: 🟡 MEDIUM
**Location**: Production systemd-timesyncd
**Steps**:
```bash
# SSH to production
ssh admin@193.181.213.220

# Check current time sync status
timedatectl

# If not synced, enable NTP
sudo timedatectl set-ntp on

# Verify sync
timedatectl show-timesync --no-pager

# Force sync
sudo systemctl restart systemd-timesyncd

# Verify again
date  # Should match `timedatectl show`
```
**Expected Result**: Time synchronized status = yes

---

### Fix 11: Fix Failed systemd Services
**Module**: INFRASTRUCTURE (85/100)
**Priority**: 🟡 MEDIUM
**Location**: Production /etc/systemd/system/
**Steps**:
```bash
# List failed services
systemctl list-units --state=failed

# For each failed service:
sudo systemctl status [SERVICE]  # Get error details
sudo journalctl -u [SERVICE] -n 50  # Check logs

# Common fixes:
sudo systemctl restart [SERVICE]
sudo systemctl enable [SERVICE]

# Reload systemd
sudo systemctl daemon-reload

# Verify no failed services
systemctl list-units --state=failed | wc -l  # Should be 0
```
**Expected Result**: INFRASTRUCTURE score rises to 92/100

---

## PHASE 6: CLEANUP & OPTIMIZATION

### Fix 12: Clean Docker Dangling Resources
**Module**: DOCKER (13/100)
**Priority**: 🟡 MEDIUM
**Location**: Production docker
**Steps**:
```bash
# Check dangling resources
docker images --filter "dangling=true"  # 1 dangling image
docker volume ls --filter "dangling=true"  # 8 dangling volumes

# Clean up
docker image prune -f  # Remove dangling images
docker volume prune -f  # Remove dangling volumes

# Verify
docker system df  # Should show reduced usage
```
**Expected Result**: No dangling images or volumes

---

### Fix 13: Create docker-compose.yml for Production
**Module**: CI/CD (58/100)
**Priority**: 🟡 MEDIUM
**Location**: /home/admin/tovplay/docker-compose.prod.yml
**Steps**:
```bash
# Create production-specific compose file
cat > /home/admin/tovplay/docker-compose.prod.yml << 'EOF'
version: '3.9'

services:
  backend:
    image: tovtech/tovplaybackend:latest
    container_name: tovplay-backend
    ports:
      - "8000:5001"
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=postgresql://raz@tovtech.org:CaptainForgotCreatureBreak@45.148.28.196:5432/TovPlay
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped

  prometheus:
    image: prom/prometheus:latest
    container_name: tovplay-prometheus
    ports:
      - "9090:9090"
    volumes:
      - /etc/prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    restart: unless-stopped

  loki:
    image: grafana/loki:latest
    container_name: tovplay-loki
    ports:
      - "3100:3100"
    volumes:
      - loki_data:/loki
    restart: unless-stopped

volumes:
  prometheus_data:
  loki_data:
EOF

# Deploy
docker-compose -f docker-compose.prod.yml up -d

# Verify all services up
docker-compose -f docker-compose.prod.yml ps
```
**Expected Result**: Production has compose file, all services managed

---

## PHASE 7: TESTING & VERIFICATION

### Fix 14: Add robots.txt and favicon
**Module**: FRONTEND (84/100)
**Priority**: 🔵 LOW
**Location**: /var/www/tovplay/
**Steps**:
```bash
# SSH to production
ssh admin@193.181.213.220

# Create robots.txt
cat > /var/www/tovplay/robots.txt << 'EOF'
User-agent: *
Allow: /
Disallow: /admin/
Sitemap: https://app.tovplay.org/sitemap.xml
EOF

# Create simple favicon
# (Use existing or create placeholder)
touch /var/www/tovplay/favicon.ico

# Verify Nginx serves them
curl https://app.tovplay.org/robots.txt
curl https://app.tovplay.org/favicon.ico
```
**Expected Result**: FRONTEND score rises to 92/100

---

## PHASE 8: FINAL VERIFICATION

### Testing Checklist:
```bash
# 1. Health check all services
curl https://app.tovplay.org  # Frontend
curl https://app.tovplay.org/api/health  # Backend API
curl http://localhost:9090/api/v1/targets  # Prometheus
curl http://localhost:3100/loki/api/v1/targets  # Loki

# 2. Database check
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c "\dt"

# 3. Security verification
# - Run security audit
# - Check SSL certificate validity
# - Verify no empty passwords
# - Check fail2ban status

# 4. Final audit score target
# UPDATE: 90/100
# DOCKER: 95/100
# FRONTEND: 95/100
# CICD: 90/100
# SECURITY: 95/100
# NGINX: 98/100
# INFRASTRUCTURE: 95/100
# PRODUCTION: 100/100
# STAGING: 100/100 (maintain)
# DATABASE: 96/100
# BACKEND: 100/100
# OVERALL: 96/100
```

---

## LOCAL TESTING (Windows Development)

### Complete Frontend + Backend Test:
```powershell
# Terminal 1 - Backend
cd F:\tovplay\tovplay-backend
.\venv\Scripts\Activate.ps1
python.exe -m pip install --upgrade pip
pip install -r requirements.txt
flask run --host=0.0.0.0 --port=5001

# Terminal 2 - Frontend
cd F:\tovplay\tovplay-frontend
npm install --legacy-peer-deps
npm run dev

# Test URLs
https://localhost:3000  # Frontend
https://localhost:5001  # Backend API
https://localhost:5001/health  # Health check
```

**Expected Output**:
- Frontend: Vite dev server running on port 3000
- Backend: Flask running on port 5001
- Both respond to requests without errors
- Database connection successful
- Health checks return 200 OK

---

## ESTIMATED TIMELINE

| Phase | Tasks | Time | Target Score |
|-------|-------|------|---------------|
| Phase 1 | Security Fixes | 15 min | 54/100 |
| Phase 2 | Docker/Monitoring | 20 min | 70/100 |
| Phase 3 | Database | 15 min | 82/100 |
| Phase 4 | Nginx/Security | 10 min | 88/100 |
| Phase 5 | Infrastructure | 10 min | 92/100 |
| Phase 6 | Cleanup | 10 min | 94/100 |
| Phase 7 | Testing | 20 min | 96/100 |
| Total | 14 fixes + testing | ~2 hours | **96/100** |

---

## SUCCESS CRITERIA

✅ All 11 audit modules score ≥90/100
✅ Zero critical security issues
✅ All services running and healthy
✅ Monitoring stack fully operational
✅ Database optimized and responsive
✅ Nginx properly configured with security headers
✅ Local development environment perfect
✅ Staging environment remains at 100/100
✅ Real-time debugging output for each fix
✅ Documentation updated in CLAUDE.md
