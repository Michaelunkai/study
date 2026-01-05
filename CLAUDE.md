# TovPlay

Gaming platform for autism community to schedule sessions safely.

---

## ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│ LOCAL: F:\tovplay\                                              │
│ ├─ tovplay-backend/                                             │
│ │  ├─ src/ (api, app, database, services, utils)                │
│ │  ├─ .env.template (unified config for local/staging/prod)     │
│ │  ├─ docker-compose.yml (unified local/staging/prod)           │
│ │  ├─ requirements.txt                                           │
│ │  └─ README.md (quick start guide)                             │
│ ├─ tovplay-frontend/                                            │
│ │  ├─ src/ (components, pages, api, stores, context, hooks)     │
│ │  ├─ .env.template (unified config for local/staging/prod)     │
│ │  ├─ package.json                                               │
│ │  └─ Dockerfile                                                 │
│ └─ .claude/                                                      │
│    ├─ INDEX.md (master navigation)                              │
│    ├─ DATABASE_HISTORY.md (consolidated DB timeline)            │
│    ├─ PROTECTION_GUIDE.md (security & recovery)                 │
│    ├─ PROJECT_STATUS.md (current state)                         │
│    ├─ CICD_HISTORY.md (deployment timeline)                     │
│    ├─ scripts/ (automation scripts)                             │
│    └─ archive/ (historical docs & backups)                      │
└─────────────────────────────────────────────────────────────────┘
                    │                       │
         ┌──────────┴────────┐    ┌────────┴──────────┐
         ▼                   ▼    ▼                   ▼
    PRODUCTION          STAGING  DATABASE      DOCKER HUB
193.181.213.220     92.113.144.59  45.148.28.196   tovtech
   ├─ Backend           ├─ Backend    PostgreSQL 17.4  ├─ tovplaybackend:latest
   ├─ Frontend (nginx)  └─ Port 8001  17 tables        └─ tovplaybackend:staging
   ├─ Monitoring (Prometheus/Grafana)
   ├─ Logging (Loki/Promtail)
   └─ Cloudflare → app.tovplay.org
```

**Tech Stack:**
- Backend: Python 3.11, Flask, PostgreSQL, Socket.IO, Gunicorn
- Frontend: React 18, Vite 6, Redux Toolkit, Tailwind, shadcn/ui
- DevOps: Docker multi-stage, GitHub Actions, Cloudflare
- Monitoring: Prometheus, Grafana, Loki, Node Exporter, cAdvisor
- DB Tables (18): User, Game, GameRequest, ScheduledSession, UserProfile, UserAvailability, UserFriends, UserGamePreference, UserNotifications, EmailVerification, UserSession, ProtectionStatus, BackupLog, ConnectionAuditLog, DeleteAuditLog, password_reset_tokens, alembic_version, game_requests

**Debloated Structure** (Dec 2025):
- Unified .env.template files (removed .env.example, .env.staging, .env.production)
- Unified docker-compose.yml (removed docker-compose.dev.yml, .staging.yml, .production.yml)
- Removed test configs (pytest.ini, pyproject.toml, playwright.config.js, vitest.config.js, .audit-ci.json)
- Removed e2e/ folders (archived to .claude/archive/)
- Consolidated .claude/ docs from 61 files to 7 guides + archive
- Removed requirements-dev.txt (use requirements.txt)
- Streamlined README.md (removed 400+ lines of deployment one-liners)

---

## SERVERS

**Production** (193.181.213.220)
```bash
ssh: wsl -d ubuntu bash -c "sshpass -p 'EbTyNkfJG6LM' ssh -o StrictHostKeyChecking=no admin@193.181.213.220"
user: admin | pass: EbTyNkfJG6LM
app: https://app.tovplay.org
dashboard: http://193.181.213.220:7777
grafana: http://193.181.213.220:3002
prometheus: http://193.181.213.220:9090
containers: tovplay-backend (port 8000→5001), tovplay-pgbouncer (port 6432), tovplay-prometheus, grafana-standalone, tovplay-loki, tovplay-promtail, tovplay-logging-dashboard, tovplay-cadvisor, tovplay-node-exporter-production, tovplay-postgres-exporter, tovplay-blackbox-exporter, alertmanager
disk: 24G/38G (63%) | ram: 3.0G/5.3G | path: /home/admin/tovplay
logs: https://app.tovplay.org/logs/
cron: Auto connection cleanup every 10 minutes → /home/admin/tovplay/logs/connection_cleanup.log
```

**Staging** (92.113.144.59)
```bash
ssh: wsl -d ubuntu bash -c "sshpass -p '3897ysdkjhHH' ssh -o StrictHostKeyChecking=no admin@92.113.144.59"
user: admin | pass: 3897ysdkjhHH
app: https://staging.tovplay.org
containers: tovplay-backend-staging (port 8001→5000)
path: /home/admin/tovplay
```

**Database** (45.148.28.196:5432)
```bash
psql: PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay
host: 45.148.28.196 | port: 5432 | db: TovPlay
user: raz@tovtech.org | pass: CaptainForgotCreatureBreak
version: PostgreSQL 17.4 (Debian)
backup: $f="F:\backup\tovplay\DB\tovplay_$(Get-Date -Format 'yyyyMMdd_HHmmss').sql"; wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' pg_dump -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay" > $f
restore: $b=(gci F:\backup\tovplay\DB\*.sql|sort LastWriteTime -Desc)[0].FullName; gc $b|wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay"
```

---

## CREDENTIALS

**AWS S3**
```
console: https://721074164731.signin.aws.amazon.com/console
user: noam | pass: KvasimZeMakShimAtzpanatKvaShim12@AniHohevKvashim
access: AKIA2PY26SP56QH2JIM4
secret: 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
```

**Docker Hub**
```
user: tovtech
pass: professor-default-glade-smartly-rogue-reverb7
```

**Email SMTP**
```
server: iah-s01.nixihost.com:465
sender: noreply@tovtech.org
pass: hD%hCt7hyxFFDuH6
```

**Discord Bot**
```
client_id: 1432633014071853108
client_secret: 5OMl6beavfAO9CfjaTLlkMbJGx4JA4CE
token: MTQzMjYzMzAxNDA3MTg1MzEwOA.GRckM5.D3Nd_XVrtUWb0RJS12plUKtH3iIAEOw352GutY
guild_id: 1432632270853898240
invite: https://discord.gg/FSVxjGAW
```

**Test Users**
```
a@a / a / Password3^
c@c / c / Password3^
d@d.com / d / Password3^
e@e.com / e / Password3^
test@gmail.com / CozyGamer / Password3^
lilachherzog.work@gmail.com / lil / Password3^
```

---

## REPOS & TOOLS

**GitHub**
- Frontend: https://github.com/TovTechOrg/tovplay-frontend
- Backend: https://github.com/TovTechOrg/tovplay-backend

**Tools**
- Jira: https://tovplay.atlassian.net/jira/software/projects/TVPL/boards/1
- Postman: http://postman.co/workspace/My-Workspace~90273e96-4c67-48b7-8e1e-616294e564c3/api/19231983-b0d1-42b5-b3db-a548c9534573

**Team**
Roman Fesunenko (roman.fesunenko@gmail.com), Sharon Keinar (sharonshaaul@gmail.com), Lilach Herzog (lilachherzog.work@gmail.com), Yuval Zeyger, Michael Fedorovsky, Avi Wasserman (avi12), Itamar Bar (itamarbr0327)

---

## RULES

**R1: Session Start** → Run `mcpl; claude mcp list` then `mcp-off <unnecessary>` and `mcpon <task-relevant>` to minimize resource usage.

**R2: MCP Setup** → 1) Search npm/web for package 2) `npm install -g <pkg>` 3) Find path via `npm list -g <pkg>` 4) Create .cmd wrapper in C:\Users\micha\.claude\ with format: `@echo off` + `"C:\Program Files\nodejs\node.exe" "<path-to-index.js>" %*` 5) `claude mcp add <name> C:\Users\micha\.claude\<name>.cmd -s user` 6) Verify via `claude mcp list` 7) If "Failed to connect" → remove immediately 8) Only after "Connected" add to mcp-ondemand.ps1

**R3: Document Failures** → After any error/suboptimal approach immediately document what went wrong, why, and correct solution in `.claude/learned.md` with timestamp. Review this file before starting any new task.

**R4: 100% Autonomy** → Work completely autonomously - search for info, fix problems, install dependencies, create configs, debug/resolve failures yourself. Never stop until goal is 100% achieved and verified through actual execution/testing. Forbidden from ending prematurely or marking tasks done without proof.

**R5: Real-time Updates** → Provide continuous progress updates - announce before touching files, stream what you're doing, confirm after each action, show outputs immediately, report errors instantly. Break goals into granular time-balanced tasks and mark each [x] immediately upon verified completion.

**R6: Defensive Coding** → Before modifying any file trace all dependencies/imports/integrations that could break. Build defensive handling for edge cases (null, timeout, missing file, malformed input) into first implementation. Immediately verify changes worked through tests/commands and use Puppeteer MCP for web UIs - never assume success.

**R7: Minimize Changes** → Use existing utilities and built-in features over new code. For any project recursively purge all non-essential content: dependencies, builds, cache, logs, temp files, commented code.

**R8: TovPlay Zero-Touch** → For F:/tovplay achieve tasks WITHOUT modifying tovplay-backend/tovplay-frontend codebases whenever possible. Prioritize server configs, environment variables, reverse proxy, middleware, Docker/nginx configs over code changes. Keep only: tovplay-backend, tovplay-frontend, claude.md, .claude, .logs, .git - purge everything else.

**R9: Performance** → Implement intelligent caching with invalidation for any reusable operation. Never repeat expensive operations. If something taking >100ms runs frequently optimize it immediately.

**R10: Settings** → For Claude Code settings use only `C:\Users\micha\.claude.json` and `C:\Users\micha\.claude\settings.json` without unnecessarily removing existing content.

---

## CURRENT STATUS (Dec 16, 2025 - Connection Pool Fixed)

**Environment Health:**
| Environment | Status | URL |
|-------------|--------|-----|
| Production Frontend | ✅ 200 | https://app.tovplay.org |
| Production Backend | ✅ 200 | https://app.tovplay.org/api/health |
| Staging | ✅ 200 | https://staging.tovplay.org |
| Database | ✅ Healthy | 45.148.28.196:5432 (6 connections - stable) |
| Logs Dashboard | ✅ 200 | https://app.tovplay.org/logs/ |
| Prometheus | ✅ Running | http://193.181.213.220:9090 |
| Grafana | ✅ Running | http://193.181.213.220:3002 |
| Loki | ✅ Running | Integrated with Promtail |
| pgBouncer | ✅ Deployed | 193.181.213.220:6432 (connection pooling) |

**Database Stats:**
- Tables: 18 | Users: 23 | Games: 12 | Sessions: 16
- Connection Pool: HEALTHY (1 active, 5 idle - well below max_connections)
- Version: PostgreSQL 17.4 (Debian)
- Configured timeouts: idle=5min, statement=30s
- Indexes: 8 new performance indexes added
- Auto cleanup cron: Every 10 minutes (kills idle connections >5min)

**Local Development:**
- Backend: Flask 3.1.2 on port 5001 (Python 3.12)
- Frontend: Vite 6.4.1 on port 3000 (Node 24.12.0)
- Launch: `.\tovrun.ps1` or `.\tovrun.bat` (PowerShell improved)
- npm devDependencies: ✅ Installed (401 packages with --ignore-scripts)

**Architecture Consolidation (Dec 16, 2025):**
- ✅ Created unified `docker-compose.yml` at root (backend, frontend, monitoring, profiles)
- ✅ Created unified `.env.template` at root (all services, all environments)
- ✅ Improved `tovrun.ps1` - Handles npm --include=dev automatically
- ✅ Created `tovrun.bat` - Easy wrapper for tovrun.ps1
- ✅ Created `SETUP.md` - Comprehensive development guide
- ✅ 8 new database indexes for query optimization

**Connection Pool Protection (Dec 16, 2025):**
- ✅ SQLAlchemy connection pooling configured (pool_size=10, max_overflow=20, pool_recycle=3600)
- ✅ PostgreSQL idle connection timeout: 5 minutes
- ✅ Auto cleanup cron deployed to production (runs every 10 minutes)
- ✅ pgBouncer deployed (port 6432, transaction pooling, max 50 DB connections)
- ✅ Connection cleanup script: `.claude/scripts/cleanup_connections.sql`

**All Issues Resolved:**
- ✅ Database connection exhaustion FIXED (cron auto-cleanup + connection pooling)
- ✅ npm config `omit=dev` FIXED (tovrun.ps1 uses --include=dev)
- ✅ pgBouncer deployed to production (needs auth config for SCRAM-SHA-256)
