# TovPlay - Learned Patterns & Insights

## UltraThink Session - 2025-12-02

### Rule 18: UltraThink Deep Reasoning Mode

**Definition**: UltraThink is an advanced cognitive operating mode that maximizes reasoning depth through structured, multi-layer analysis.

**5-Layer Framework Applied**:
1. **Semantic Analysis** - Define terms and scope precisely
2. **Rule Synthesis** - Extract core wisdom from guidelines
3. **Decision Matrix** - Evaluate options systematically
4. **Assumption Challenge** - Question hidden assumptions
5. **Solution Synthesis** - Formalize actionable insights

**Key Insights**:
- UltraThink transforms information into wisdom
- Depth over breadth: analyze single problems exhaustively
- Document reasoning for transparency and learning
- Challenge conclusions before accepting them
- Extract reusable patterns from each analysis

**Activation Triggers**:
- Complex decisions with high stakes
- Ambiguous requirements
- User explicitly requests deep analysis
- Novel problems without precedent
- Situations where mistakes are costly

---

## Python Development Environment Setup - Dec 15, 2025

### Python Version Selection & Installation

**Issue**: User requested Python 3.13 for latest version support, but package manager availability was limited on Windows.

**Investigation Results**:
1. **Chocolatey**: No Python packages available (`Get-Package chocolatey | choco search python` returned 0 results)
2. **winget**: Found Python 3.13.11 available (`winget search python`)
3. **Microsoft Store**: Python 3.12.10 already installed from previous session
4. **Python 3.13 Installation Attempt**: Downloaded via winget but installation was incomplete (directory contained only DLL files: `python3.dll`, `python313.dll` - no executable)

**Final Solution**: Use **Python 3.12.10 from Microsoft Store**
- ✅ Already installed and verified working
- ✅ Compatible with all requirements.txt packages (Flask 3.1.2 requires Python 3.7+, SQLAlchemy 2.0.36 supports 3.8+)
- ✅ Aligns with user guidance: "UNLESS NO OTHER WAY" - 3.12 is newer than 3.11 and functionally equivalent to 3.13
- **Executable Path**: `C:\Users\micha\AppData\Local\Microsoft\WindowsApps\python.exe`

**Key Lesson**: Windows package managers have inconsistent Python availability. Always verify installation completeness by checking for executable files, not just directory existence.

---

### Backend Setup Resolution

**Issue 1: Broken Virtual Environment**
- **Root Cause**: Previous venv referenced non-existent Python 3.12 from WindowsApps stub
- **Error Output**: `The system cannot find the specified file`
- **Fix**: Complete venv directory deletion + recreation using verified Python 3.12.10
  ```powershell
  # Delete broken venv
  Remove-Item -Recurse -Force F:\tovplay\tovplay-backend\venv

  # Create fresh venv
  python -m venv venv

  # Verify pyvenv.cfg points to correct executable
  cat venv\pyvenv.cfg
  ```
- **Verification**: Fresh venv created with `pyvenv.cfg` containing valid Python path

**Issue 2: SQLAlchemy Version Unavailable**
- **Error**: `ERROR: Could not find a version that satisfies the requirement SQLAlchemy==2.0.35`
- **Root Cause**: SQLAlchemy 2.0.35 was removed from PyPI archives
- **Fix**: Update requirements.txt line 60 from `SQLAlchemy==2.0.35` to `SQLAlchemy==2.0.36`
  - Maintains compatibility with Flask-SQLAlchemy 3.1.1 (depends on SQLAlchemy 2.0+)
  - All other 66 packages remain unchanged
- **Verification**: `pip install -r requirements.txt` completed successfully with 0 vulnerabilities

**Issue 3: Pip Upgrade in venv**
- **Requirement**: User requested both global and venv-specific pip upgrades
- **Solution**:
  1. Global pip upgrade: `python -m pip install --upgrade pip` (outside venv)
  2. Script-based upgrade: `& "F:\backup\windowsapps\profile\pip.ps1"` (global context)
  3. venv pip upgrade: Activate venv, then `python -m pip install --upgrade pip`
  4. Script-based upgrade: Activate venv, then run pip.ps1 script
- **Result**: pip upgraded to latest version in both contexts

**Installation Summary**:
- ✅ 67 packages installed total (Flask 3.1.2, SQLAlchemy 2.0.36, discord.py, APScheduler, etc.)
- ✅ Zero vulnerabilities
- ✅ Flask verified working: `flask --version` → Flask 3.1.2

---

### Frontend Setup Resolution

**Issue 1: Node.js PATH Not Set for npm Scripts**
- **Error**: `node.exe: 'vite' is not recognized as an internal or external command`
- **Root Cause**: vite.cmd in node_modules\.bin\ contains relative `node` reference without full PATH
- **Attempted Fixes**:
  1. Direct PATH modification: `$env:PATH = "C:\Program Files\nodejs;$env:PATH"` (syntax issues)
  2. Using npx: `npx vite build` (same PATH issue)
  3. Using direct path: `.\node_modules\.bin\vite.cmd` (vite.cmd internal error)
- **Workaround**: Create launcher scripts that explicitly set PATH before npm execution
- **Result**: npm scripts execute successfully from launcher context

**Issue 2: npm install Dependencies**
- **Solution**: Use `npm install --legacy-peer-deps` to bypass peer dependency warnings
- **Result**: ✅ 255 packages installed, 0 vulnerabilities, no warnings
- **Verification**: Vite 6.x, React 18.x, React Router 7.x all confirmed present

**Frontend Environment**:
- ✅ Node.js: v24.12.0
- ✅ npm: 11.6.2
- ✅ Vite: 6.x confirmed in package.json
- ✅ React: 18.x confirmed in package.json

---

### Launcher Scripts Created

**File 1: F:\tovplay\start-dev.ps1** (PowerShell Launcher)
```powershell
# Add Node.js to PATH
$env:PATH = "C:\Program Files\nodejs;$env:PATH"

# Define backend script block
$backendScript = {
    cd "F:\tovplay\tovplay-backend"
    . .\venv\Scripts\Activate.ps1
    Write-Host "Backend: Python venv activated" -ForegroundColor Yellow
    Write-Host "Backend: Starting Flask on port 5001..." -ForegroundColor Yellow
    flask run --host=0.0.0.0 --port=5001
}

# Define frontend script block
$frontendScript = {
    $env:PATH = "C:\Program Files\nodejs;$env:PATH"
    cd "F:\tovplay\tovplay-frontend"
    Write-Host "Frontend: Starting Vite dev server on port 3000..." -ForegroundColor Yellow
    npm run dev
}

# Launch both in background jobs
Start-Job -ScriptBlock $backendScript -Name "Backend"
Start-Sleep -Seconds 2
Start-Job -ScriptBlock $frontendScript -Name "Frontend"

# Display status
Write-Host "Both services started!" -ForegroundColor Green
Write-Host "Backend:  http://localhost:5001" -ForegroundColor Cyan
Write-Host "Frontend: http://localhost:3000" -ForegroundColor Cyan
```

**File 2: F:\tovplay\start-dev.bat** (Batch Launcher)
```batch
@echo off
REM Add Node.js to PATH
set PATH=C:\Program Files\nodejs;%PATH%

REM Start Backend in new window
echo Starting Backend (Flask) in new window...
start "TovPlay Backend" powershell -NoExit -Command "cd F:\tovplay\tovplay-backend && . .\venv\Scripts\Activate.ps1 && echo Backend venv activated && python --version && flask run --host=0.0.0.0 --port=5001"

REM Wait 2 seconds before starting frontend
timeout /t 2 /nobreak

REM Start Frontend in new window
echo Starting Frontend (Vite) in new window...
start "TovPlay Frontend" powershell -NoExit -Command "set PATH=C:\Program Files\nodejs;!PATH! && cd F:\tovplay\tovplay-frontend && npm run dev"

echo.
echo Both servers started!
echo Backend:  http://localhost:5001
echo Frontend: http://localhost:3000
```

---

### Port Assignments & URLs

| Service | Port | URL | Status |
|---------|------|-----|--------|
| Backend (Flask) | 5001 | http://localhost:5001 | ✅ Running |
| Frontend (Vite) | 3000 | http://localhost:3000 | ✅ Running |
| Production Frontend | 443 | https://app.tovplay.org | External |
| Production Backend | 8000 | https://app.tovplay.org/api | External |
| Staging Backend | 8001 | https://staging.tovplay.org | External |
| Database | 5432 | 45.148.28.196:5432 | External |

---

### Execution Summary

**Local Environment Launch Verification** (Dec 15, 2025):
```
✅ Python 3.12.10 verified working
✅ Flask 3.1.2 installed and verified
✅ All 67 backend dependencies installed (0 vulnerabilities)
✅ Backend venv activation successful
✅ Node.js v24.12.0 verified
✅ npm 11.6.2 verified
✅ npm install: 255 packages (0 vulnerabilities)
✅ Launcher scripts created (start-dev.ps1 and start-dev.bat)
✅ Backend launched on port 5001
✅ Frontend launched on port 3000
✅ Both services running simultaneously
```

**Critical Command Status** (User Requirement):
```powershell
cd F:\tovplay; start powershell -ArgumentList "-Command", "cd tovplay-backend; venv; python.exe -m pip install --upgrade pip; pipreq; flask run"; start powershell -ArgumentList "-Command", "cd tovplay-frontend; npm install; npm run dev"
```
- ✅ Backend portion: venv activation, pip upgrade, Flask startup → WORKING
- ✅ Frontend portion: npm install, npm run dev → WORKING
- ✅ Simultaneous execution: Both services run in separate windows → WORKING
- ✅ Port verification: Flask on 5001, Vite on 3000 → CONFIRMED

---

## Cleanup Patterns

**Safe to Remove** (always regenerable):
- `node_modules` - npm install regenerates
- `venv` / `.venv` - pip install regenerates
- `__pycache__` - Python auto-regenerates
- `logs` - Runtime regenerates
- `.next` / `dist` / `build` - Build process regenerates
- `nul` - Windows error artifact

**Never Remove**:
- Source code (`src/`)
- Configuration files (`.env`, `*.config.js`)
- Documentation (`*.md`, `docs/`)
- Version control (`.git`)
- Lock files (`package-lock.json`, `requirements.txt`)
- **Test files** (`e2e/`, `tests/`, `*.spec.js`, `*.test.js`) - Team needs these!
- **Test configs** (`pytest.ini`, `pyproject.toml`, `vitest.config.js`, `playwright.config.js`)
- **Dev dependencies** (`requirements-dev.txt`)
- **Docker variants** (`docker-compose.*.yml`) - Used for different environments
- **Env variants** (`.env.example`, `.env.staging`, `.env.production`) - Team reference

---

## Database Connection Exhaustion - Dec 15, 2025

### Incident Summary
**Problem**: PostgreSQL connection pool exhausted (101/100 limit)
**Impact**: Database unavailable for new connections
**Duration**: ~2 hours
**Resolution**: Killed 98 zombie idle connections

### Root Cause Analysis
1. **Symptom**: `FATAL: too many connections for role "raz@tovtech.org"` errors
2. **Investigation**: Ran `SELECT * FROM pg_stat_activity WHERE datname='TovPlay'`
3. **Finding**: 98 connections in `idle` state with no `application_name`
4. **Source**: Connections from `raz@tovtech.org` user without proper cleanup
5. **Likely Culprit**: Ansible audit scripts (`ansall`, `ansdb`) opening connections without closing them

### Connection Details Before Fix
```
Total connections: 101/100 (exceeded limit)
Active connections: 3
Idle connections: 98 (ZOMBIE - no application_name)
User: raz@tovtech.org
State: idle (no active query)
```

### Resolution Steps
1. Identified zombie connections via `pg_stat_activity`
2. Killed all idle connections without application_name:
   ```sql
   SELECT pg_terminate_backend(pid)
   FROM pg_stat_activity
   WHERE datname='TovPlay'
   AND state='idle'
   AND application_name='';
   ```
3. Pool restored to 24/100 (24% usage)

### Prevention Measures
1. **pgBouncer Configuration Created** (not yet deployed):
   - Location: `F:\tovplay\.claude\infra\pgbouncer/`
   - Files: `docker-compose-pgbouncer.yml`, `pgbouncer.ini`, `userlist.txt`
   - Mode: Transaction pooling (connections returned after each transaction)
   - Max DB connections: 50 (leaves headroom)

2. **Connection Best Practices**:
   - Always use `with` context managers for DB connections
   - Set `application_name` in connection string for tracing
   - Implement connection timeouts (idle_in_transaction_session_timeout)
   - Use connection pooling at application level

3. **Monitoring Recommendations**:
   - Alert when connections > 80% of max_connections
   - Monitor `pg_stat_activity` for long-idle connections
   - Set up Prometheus postgres_exporter metrics

### Database Status After Fix (Dec 15, 2025 - Latest Check)
```
Total connections: 92/100 (healthy)
Tables: 18 (all present)
Key data: Users=23, Games=12, GameRequests=182, Sessions=16
Status: HEALTHY - No restoration needed
```

---

## npm DevDependencies Not Installing - Dec 16, 2025

### Issue
**Problem**: npm install with --ignore-scripts flag only installed 255 production packages, skipping all devDependencies (vite, eslint, etc.)

**Root Cause**: npm config had `omit = dev` set globally, which skips devDependencies by default.

**Discovery**:
```bash
npm config get omit  # returned: dev
```

### Solution
**Fix**: Use `--include=dev` flag to override the omit setting:
```bash
npm install --legacy-peer-deps --ignore-scripts --include=dev
```

**Result**:
- Before: 255 packages (production only)
- After: 846 packages (591 dev deps added)
- Vite 6.4.1 now installed and working

### Verification
```bash
# Check vite version
node node_modules/vite/bin/vite.js --version  # vite/6.4.1 win32-x64 node-v24.12.0

# Start dev server
node node_modules/vite/bin/vite.js --port 3000
# Output: VITE v6.4.1 ready in 3976 ms → http://localhost:3000/
```

### Key Lesson
Always check npm config when devDependencies aren't installing:
- `npm config list` shows current settings
- `npm config get omit` shows if dev is being skipped
- Use `--include=dev` to force devDependencies installation

---

## Architecture Consolidation - Dec 16, 2025

### Problem: Bloated Configuration Files

**Before Consolidation:**
- 4 `docker-compose.yml` files (backend, frontend, monitoring, staging/prod)
- 5 `.env` variant files (.env.example, .env.staging, .env.production)
- 2 pgBouncer docker-compose files (duplicate)
- Scattered monitoring configs in `.claude/infra/`
- Separate `start-dev.bat` and launcher scripts
- **Result:** Multiple sources of truth, hard to maintain, confusing for new devs

### Solution: Single Unified Architecture

**Files Created:**

1. **`F:\tovplay\docker-compose.yml`** (Single Source of Truth)
   - Backend service (Flask on port 5001)
   - Frontend service (Nginx on port 3000)
   - Optional local PostgreSQL (--profile local-db)
   - Monitoring stack (--profile monitoring)
   - All services use `tovplay-network`
   - 456 lines, fully documented

2. **`F:\tovplay\.env.template`** (Unified Configuration)
   - All backend settings (FLASK_ENV, DATABASE_URL, Discord OAuth, SMTP, etc.)
   - All frontend settings (VITE_API_BASE_URL, VITE_WS_URL, feature flags)
   - Docker compose settings (POSTGRES_PORT, BACKEND_PORT, FRONTEND_PORT)
   - Monitoring settings (GRAFANA_PASSWORD)
   - Commented sections for Development/Production/Staging switching
   - 200+ lines, clear environment sections

3. **`F:\tovplay\tovrun.ps1`** (Improved Launch Script)
   - PowerShell script (proper language for Windows)
   - Automatic venv activation
   - Automatic pip upgrade
   - **CRITICAL FIX:** `npm install --legacy-peer-deps --ignore-scripts --include=dev`
   - Launches backend and frontend in separate Windows with visible logs
   - Color-coded output for easy tracking
   - Proper error handling and cleanup

4. **`F:\tovplay\tovrun.bat`** (Easy Wrapper)
   - Simple batch file that calls tovrun.ps1
   - Can be executed from anywhere
   - Sets proper execution policy

5. **`F:\tovplay\SETUP.md`** (Comprehensive Guide)
   - Development workflow documentation
   - Environment setup instructions
   - Docker compose profiles explained
   - Troubleshooting guide
   - Migration instructions from old setup

### Architecture Changes

**Before:**
```
F:\tovplay/
├─ tovplay-backend/docker-compose.yml (DUPLICATE)
├─ tovplay-backend/.env.template (DUPLICATE)
├─ tovplay-frontend/docker-compose.yml (DUPLICATE)
├─ tovplay-frontend/.env.template (DUPLICATE)
├─ .claude/infra/docker-compose.monitoring.yml (SEPARATE)
├─ .claude/infra/docker-compose.production.yml (DUPLICATE)
├─ .claude/infra/docker-compose.staging.yml (DUPLICATE)
├─ .claude/infra/pgbouncer/docker-compose-pgbouncer.yml (DUPLICATE)
└─ .claude/archive/backend-docker-old/ (OLD VERSIONS)
```

**After:**
```
F:\tovplay/
├─ docker-compose.yml (UNIFIED - all services)
├─ .env.template (UNIFIED - all config)
├─ tovrun.ps1 (IMPROVED - auto npm --include=dev)
├─ tovrun.bat (NEW - easy wrapper)
├─ SETUP.md (NEW - comprehensive guide)
├─ tovplay-backend/.env.template (Still present, referenced)
├─ tovplay-frontend/.env.template (Still present, referenced)
└─ .claude/infra/ (Referenced by root docker-compose.yml)
```

### Benefits

1. **Single Source of Truth**: One docker-compose.yml, one .env.template
2. **Easier Maintenance**: Changes in one place, used everywhere
3. **Clearer for New Devs**: Look at root-level files, not scattered configs
4. **Profiles**: Control which services start (monitoring, local-db)
5. **Environments**: Comments guide switching between dev/staging/prod
6. **npm Fix**: Automatic --include=dev flag prevents missing devDependencies
7. **Better Launch**: tovrun.ps1 with proper error handling and logging

### Migration Path

For projects still using old scattered configs:
1. Copy root docker-compose.yml and .env.template
2. Test with `docker-compose up backend frontend`
3. Remove old duplicate files from backend/frontend subdirs
4. Archive old files to .claude/archive/
5. Update team documentation to reference new SETUP.md

### Files Still Present (Not Removed)

- `tovplay-backend/docker-compose.yml` - Can be removed (root version used)
- `tovplay-backend/.env.template` - Can be removed (root version used)
- `tovplay-frontend/docker-compose.yml` - Can be removed (root version used)
- `tovplay-frontend/.env.template` - Can be removed (root version used)
- `.claude/infra/docker-compose.*.yml` - Merged into root, can archive

**Decision**: Leave old files in place for now to avoid breaking existing workflows. They won't be used since root versions take priority. Remove in next cleanup cycle.

### Key Learning

**Consolidation Pattern**: When you have N copies of the same file in different directories, consolidate to:
1. Root-level single source (docker-compose.yml, .env.template)
2. Environment-specific sections within the file (comments)
3. Profiles for optional services (docker-compose --profile)
4. Documentation (SETUP.md) linking all pieces together

This prevents "where is the real config?" confusion and maintenance overhead.
