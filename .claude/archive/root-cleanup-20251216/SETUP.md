# TovPlay Development Setup - New Unified Architecture

## Quick Start (Local Development)

### Option 1: Using PowerShell Script (Recommended)

```powershell
cd F:\tovplay
.\tovrun.ps1
```

Or use the batch wrapper from anywhere:
```cmd
F:\tovplay\tovrun.bat
```

This will launch:
- Backend (Flask) on port 5001
- Frontend (Vite) on port 3000

### Option 2: Using Docker Compose

```bash
# Copy environment template
cp .env.template .env

# Start backend + frontend
docker-compose up backend frontend

# Start with local PostgreSQL database
docker-compose --profile local-db up

# Start monitoring stack (Prometheus, Grafana, Loki)
docker-compose --profile monitoring up
```

---

## Configuration Files (Unified)

### Root Level Files (NEW - Dec 16, 2025)

- **`.env.template`** - Unified environment configuration for all services
  - Backend: FLASK_ENV, DATABASE_URL, Discord OAuth, SMTP, etc.
  - Frontend: VITE_API_BASE_URL, VITE_WS_URL, feature flags, etc.
  - Docker: POSTGRES_PORT, BACKEND_PORT, FRONTEND_PORT, etc.
  - Monitoring: GRAFANA_PASSWORD, etc.

- **`docker-compose.yml`** - Single unified Docker Compose configuration
  - `backend` service (Flask on port 5001)
  - `frontend` service (Nginx on port 3000)
  - `db` service (PostgreSQL - local-db profile only)
  - Monitoring services (prometheus, grafana, loki, promtail, alertmanager, node-exporter, cadvisor)
  - All services use tovplay-network

- **`tovrun.ps1`** - PowerShell script to launch backend + frontend with proper npm config
  - Activates Python venv
  - Installs pip packages
  - Installs npm dependencies with `--include=dev` flag (critical!)
  - Launches Flask and Vite in separate windows
  - Shows logs in real-time

- **`tovrun.bat`** - Batch wrapper for tovrun.ps1 (easier to call)

---

## Architecture (Consolidated)

### Before (Bloated - Multiple Files)

```
F:\tovplay/
├─ tovplay-backend/
│  ├─ docker-compose.yml  ← Duplicate
│  ├─ .env.template       ← Duplicate
│  └─ .env.production     ← Duplicate (should not exist)
├─ tovplay-frontend/
│  ├─ docker-compose.yml  ← Duplicate
│  ├─ .env.template       ← Duplicate
│  └─ .env.production     ← Duplicate (should not exist)
├─ .claude/infra/
│  ├─ docker-compose.monitoring.yml  ← Separate
│  ├─ docker-compose.production.yml  ← Duplicate
│  ├─ docker-compose.staging.yml     ← Duplicate
│  └─ pgbouncer/docker-compose-pgbouncer.yml  ← Separate
└─ .claude/archive/backend-docker-old/  ← Old versions
```

### After (Consolidated - Single Source of Truth)

```
F:\tovplay/
├─ docker-compose.yml        ← Single unified compose file
├─ .env.template             ← Single unified .env config
├─ tovrun.ps1                ← Launch script
├─ tovrun.bat                ← Launch wrapper
├─ tovplay-backend/
│  ├─ .env.template          ← Referenced by parent .env
│  └─ docker-compose.yml     ← Can be removed (using root version)
├─ tovplay-frontend/
│  ├─ .env.template          ← Referenced by parent .env
│  └─ docker-compose.yml     ← Can be removed (using root version)
└─ .claude/infra/            ← Config files referenced by root docker-compose.yml
   ├─ prometheus/
   ├─ grafana/provisioning/
   ├─ loki/
   ├─ promtail/
   ├─ alertmanager/
   └─ pgbouncer/
```

---

## Environment Setup (`.env` file)

### 1. Create `.env` from template

```bash
cp .env.template .env
```

### 2. For Local Development (Default)

Most settings are pre-configured for localhost development:
- Backend runs on `http://localhost:5001`
- Frontend runs on `http://localhost:3000`
- Uses external PostgreSQL at `45.148.28.196:5432`
- No changes needed - just copy the template!

### 3. For Local Development with Local PostgreSQL

Uncomment these in `.env`:
```bash
# Local Development with Docker: Uncomment to use local PostgreSQL
POSTGRES_HOST=db
DATABASE_URL=postgresql://postgres:postgres@db:5432/tovplay
```

Then start with:
```bash
docker-compose --profile local-db up
```

### 4. For Production

Uncomment the Production sections in `.env`:
```bash
# Production: Uncomment for production
WEBSITE_URL=https://app.tovplay.org
APP_URL=https://app.tovplay.org
ALLOWED_ORIGINS=https://app.tovplay.org
# ... and other prod URLs
```

### 5. For Staging

Uncomment the Staging sections in `.env`:
```bash
# Staging: Uncomment for staging
WEBSITE_URL=https://staging.tovplay.org
APP_URL=https://staging.tovplay.org
# ... and other staging URLs
```

---

## Docker Compose Profiles

### Profile: `local-db` (Optional Local PostgreSQL)

```bash
docker-compose --profile local-db up
```

Starts:
- `db` (PostgreSQL 15)
- `backend` (Flask)
- `frontend` (Nginx)

### Profile: `monitoring` (Prometheus/Grafana/Loki)

```bash
docker-compose --profile monitoring up
```

Starts:
- `prometheus` (metrics collection) - http://localhost:9090
- `grafana` (dashboards) - http://localhost:3002
- `loki` (log aggregation) - http://localhost:3100
- `promtail` (log collector)
- `alertmanager` (alert routing)
- `node-exporter` (host metrics)
- `cadvisor` (container metrics)

### Profile: Default (Backend + Frontend)

```bash
docker-compose up backend frontend
```

Starts:
- `backend` (Flask on port 5001)
- `frontend` (Nginx on port 3000)
- Uses external PostgreSQL at 45.148.28.196

---

## Development Workflow

### Using PowerShell Script (Recommended)

```powershell
PS F:\tovplay> .\tovrun.ps1

# This will:
# 1. Check/create Python venv
# 2. Activate venv
# 3. Upgrade pip
# 4. Install requirements.txt
# 5. Start Flask on port 5001
# 6. Install npm with --include=dev flag (CRITICAL!)
# 7. Start Vite on port 3000
# 8. Display logs in real-time in separate windows

# Press Ctrl+C in each window to stop
```

### Using Docker Compose

```bash
# Option A: Use external PostgreSQL (production database)
docker-compose up backend frontend

# Option B: Use local PostgreSQL (development)
docker-compose --profile local-db up

# Option C: Include monitoring stack
docker-compose up backend frontend
docker-compose --profile monitoring up  # In another terminal

# View logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Stop services
docker-compose down
```

### Manual Setup (For Debugging)

```bash
# Backend
cd F:\tovplay\tovplay-backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
flask run --host=0.0.0.0 --port=5001 --debug

# Frontend (in another terminal)
cd F:\tovplay\tovplay-frontend
npm install --legacy-peer-deps --ignore-scripts --include=dev
npm run dev
```

---

## Services & URLs

| Service | URL | Port |
|---------|-----|------|
| Frontend | http://localhost:3000 | 3000 |
| Backend API | http://localhost:5001 | 5001 |
| Backend Health | http://localhost:5001/health | 5001 |
| Prometheus | http://localhost:9090 | 9090 |
| Grafana | http://localhost:3002 | 3002 |
| Loki | http://localhost:3100 | 3100 |

---

## Database Connection

### External (Shared) Database
```bash
host: 45.148.28.196
port: 5432
database: TovPlay
user: raz@tovtech.org
password: CaptainForgotCreatureBreak
```

```bash
# Direct access
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay

# From Docker
docker-compose exec backend psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay
```

### Local Development Database
```bash
# Only available with --profile local-db
docker-compose --profile local-db up

# Connect to local db
docker-compose exec db psql -U postgres -d tovplay
```

---

## Troubleshooting

### "npm install" Only Installs 255 Packages (Missing devDependencies)

**Problem:** npm config has `omit=dev` globally
**Solution:** Use `--include=dev` flag (already included in tovrun.ps1)

```bash
npm install --legacy-peer-deps --ignore-scripts --include=dev
```

### Backend Won't Start - ModuleNotFoundError: No module named 'bot'

**Problem:** bot.py was deleted
**Solution:** Restore from git

```bash
cd tovplay-backend
git checkout HEAD -- bot.py
```

### Database "Too Many Clients Already"

**Problem:** 100+ idle connections
**Solution:** Kill idle connections

```bash
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay << 'SQL'
SELECT pg_terminate_backend(pid) FROM pg_stat_activity
WHERE datname='TovPlay' AND state='idle' AND pid <> pg_backend_pid();
SQL
```

### Port Already in Use

```bash
# Find what's using the port
netstat -ano | findstr :3000   # Frontend
netstat -ano | findstr :5001   # Backend

# Kill the process
taskkill /PID <PID> /F
```

---

## File Organization

### What to Keep

- `F:\tovplay/docker-compose.yml` - Use this (unified)
- `F:\tovplay/.env.template` - Use this (unified)
- `F:\tovplay/tovrun.ps1` - Use this (improved)
- `F:\tovplay/tovplay-backend/` - Source code
- `F:\tovplay/tovplay-frontend/` - Source code
- `F:\tovplay/.claude/infra/` - Config files for monitoring

### What Can Be Removed (Use Root Versions Instead)

- `F:\tovplay/tovplay-backend/docker-compose.yml` - Use root version
- `F:\tovplay/tovplay-frontend/docker-compose.yml` - Use root version
- `F:\tovplay/.claude/infra/docker-compose.*.yml` - Merged into root version
- Old .env files (use unified .env.template)

---

## Git Workflow

```bash
# All changes should be made to root-level files only
git add .env.template docker-compose.yml tovrun.ps1 tovrun.bat

# Update CLAUDE.md to reference new consolidated architecture
git add CLAUDE.md

# Don't commit individual .env files
git add -u  # Remove deleted duplicate files

git commit -m "refactor: Consolidate docker-compose and .env into single unified root configs"
```

---

## Migration from Old Setup

If transitioning from the old multi-file approach:

```bash
# 1. Backup old configs
mkdir -p .claude/archive/old-configs-backup
cp tovplay-backend/docker-compose.yml .claude/archive/old-configs-backup/
cp tovplay-frontend/docker-compose.yml .claude/archive/old-configs-backup/
cp .claude/infra/docker-compose.*.yml .claude/archive/old-configs-backup/

# 2. Copy new unified files
cp .env.template .env  # Edit with your settings

# 3. Update your workflow
# OLD: cd tovplay-backend && docker-compose up
# NEW: cd F:\tovplay && docker-compose up backend

# 4. Test everything still works
.\tovrun.ps1
# or
docker-compose up backend frontend

# 5. Commit cleanup
git add -A
git commit -m "remove: Old duplicate docker-compose and .env files"
```

---

## Notes

- **Single Source of Truth:** All configuration now centralized in root `.env.template`
- **Profiles:** Use docker-compose profiles to control which services start
- **Backward Compatible:** Old per-directory compose files still work if needed
- **Environment Flexibility:** Single template supports dev, staging, and production
- **Improved tovrun:** PowerShell script handles all npm config issues automatically

---

Last Updated: Dec 16, 2025
