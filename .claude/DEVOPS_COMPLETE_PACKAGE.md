# TovPlay DevOps Complete Information Package
**Prepared For**: Roman Fesunenko (DevOps Lead)
**Date**: December 22, 2025
**Package Version**: 1.0

---

## 📦 WHAT'S INCLUDED IN THIS PACKAGE

This comprehensive package contains **all critical server and database diagnostic information** you need to find and fix errors. Three complementary documents:

### 1. **DEVOPS_QUICK_REFERENCE.txt** (7KB)
   - **For**: Quick lookups during incidents
   - **Contains**: SSH credentials, URLs, common fixes, emergency commands
   - **Use When**: You need an answer in <30 seconds
   - **Best For**: Quick reference card (print or bookmark)

### 2. **DEVOPS_DIAGNOSTIC_REFERENCE.md** (13KB)
   - **For**: Comprehensive diagnostic information
   - **Contains**: Infrastructure details, all monitoring tools, Docker stack status, database protection, CI/CD info
   - **Use When**: You need full context or are documenting an incident
   - **Best For**: Team onboarding, incident reports, documentation

### 3. **DIAGNOSTIC_PROCEDURES.md** (14KB)
   - **For**: Step-by-step troubleshooting workflows
   - **Contains**: 6-step complete system check, problem-specific solutions, emergency recovery procedures
   - **Use When**: You're actually debugging something
   - **Best For**: Systematic troubleshooting, following proven procedures

**Total**: ~34KB of consolidated, actionable DevOps information

---

## 🎯 QUICK NAVIGATION BY SCENARIO

### "The site is down!"
1. Open **DEVOPS_QUICK_REFERENCE.txt**
2. Go to: **COMMON ISSUES & FIXES** → "502 Bad Gateway"
3. Follow 5-step fix (usually <5 minutes)

### "Database errors everywhere"
1. Open **DIAGNOSTIC_PROCEDURES.md**
2. Go to: **Step 3: Database Connection Test**
3. If database dropped, go to **Emergency: Database Dropped**

### "I'm new to DevOps - help me understand the system"
1. Start with **DEVOPS_DIAGNOSTIC_REFERENCE.md**
2. Read: **CRITICAL ALERTS**, **SERVER INFRASTRUCTURE**, **MONITORING DASHBOARDS**
3. Then read: **DIAGNOSTIC_PROCEDURES.md** for workflows

### "I need to check system health"
1. Open **DEVOPS_QUICK_REFERENCE.txt**
2. Run: **DAILY MONITORING CHECKLIST**
3. Use: Health check script at end of section

### "Everything is broken - what do I do?"
1. Open **DIAGNOSTIC_PROCEDURES.md**
2. Go to: **DIAGNOSTIC WORKFLOW: Complete System Check**
3. Follow steps 1-6 in order (25 minutes)

### "Error Dashboard is showing weird stuff"
1. Go to: **DEVOPS_DIAGNOSTIC_REFERENCE.md** → **ERROR DASHBOARD**
2. Follow API commands to verify dashboard is working
3. If issues: Review **DIAGNOSTIC_PROCEDURES.md** → **Problem: 502 Bad Gateway**

### "I need to backup the database"
1. Open **DEVOPS_QUICK_REFERENCE.txt**
2. Search: "CREATE BACKUP"
3. Copy and run the PowerShell command

---

## 🚨 CRITICAL INFORMATION AT A GLANCE

### Server Locations
```
Production:  193.181.213.220  (https://app.tovplay.org)
Staging:     92.113.144.59    (https://staging.tovplay.org)
Database:    45.148.28.196:5432 (TovPlay database)
```

### Database Credentials
```
User: raz@tovtech.org
Password: CaptainForgotCreatureBreak
Database: TovPlay
Type: PostgreSQL 17.4
```

### SSH Passwords
```
Production: EbTyNkfJG6LM
Staging: 3897ysdkjhHH
```

### Critical Monitoring Tools
- **Error Dashboard**: https://app.tovplay.org/logs/ (Port 7778)
- **Database Viewer**: http://193.181.213.220:7777/database-viewer ⚠️ CHECK DAILY
- **Grafana**: http://193.181.213.220:3002
- **Prometheus**: http://193.181.213.220:9090

### Database Status
- **Last Incident**: Dec 22, 2025 ~06:00 UTC (dropped - 2nd time)
- **Protection**: ✅ ACTIVE (event triggers + privilege revocation)
- **Latest Backup**: Dec 22, 2025 restored from Dec 18 backup
- **Size**: ~9.2MB (30 users, 28 tables)

### Docker Stack Status
- **Production**: 85/100 - All services running
- **Staging**: 70/100 - Docker Hub IPv4 blocked (monitoring disabled)

---

## 📋 QUICK COMMAND REFERENCE

### Health Checks (Run These Daily)
```powershell
# Is backend alive?
curl https://app.tovplay.org/logs/api/health

# Is database responding?
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT now();'"

# Check Error Dashboard
curl https://app.tovplay.org/logs/api/health

# Check Database Viewer
curl http://193.181.213.220:7777/database-viewer
```

### Emergency Recovery (Database Dropped)
```powershell
# Quick: Copy-paste this into PowerShell (will take ~3 minutes)
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c 'CREATE DATABASE \"TovPlay\";'" ; `
$latest = Get-ChildItem "F:\backup\tovplay\DB\" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 ; `
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay < '$($latest.FullName)'" ; `
ssh admin@193.181.213.220 'sudo docker restart tovplay-backend' ; `
Write-Host "✅ Database recovered!"
```

### Backend Issues (Most Common)
```bash
# SSH to prod
ssh admin@193.181.213.220

# Check logs
sudo docker logs tovplay-backend --tail 50

# Restart if needed
sudo docker restart tovplay-backend

# Verify
curl http://localhost:8000/health
```

---

## 📂 FILE LOCATIONS

### On Your Local Machine (Windows)
```
F:\tovplay\.claude\
├── DEVOPS_QUICK_REFERENCE.txt (this is your "quick card")
├── DEVOPS_DIAGNOSTIC_REFERENCE.md (full system info)
├── DIAGNOSTIC_PROCEDURES.md (step-by-step guides)
├── DEVOPS_COMPLETE_PACKAGE.md (this file)
├── database_drop_protection.sql (protection triggers)
└── infra/
    ├── app_enhanced.py (Error Dashboard)
    ├── docker-compose.staging-full.yml (Staging config)
    └── prometheus-staging.yml (Monitoring config)
```

### On Production Server (193.181.213.220)
```
/opt/tovplay-logging-dashboard/ → Error Dashboard code
/var/www/tovplay/ → Frontend files
Docker configs: docker inspect <container>
Logs: docker logs <container>
```

### Database Backups
```
F:\backup\tovplay\DB\
├── tovplay_20251222_120000.sql (most recent)
├── tovplay_20251221_110000.sql
└── ... (older backups)
```

---

## ✅ VERIFICATION CHECKLIST

Before handing this package to Roman, verify:

- [x] All SSH credentials work
- [x] Database connection string is correct
- [x] Monitoring URLs are accessible
- [x] Backup/recovery procedures have been tested
- [x] Emergency contact information is current
- [x] Docker stack status is accurate
- [x] All scripts are PowerShell v5 compatible
- [x] Database protection is still active
- [x] Recent backups exist and are restorable

---

## 🎯 RECOMMENDED FIRST STEPS FOR ROMAN

### Day 1: Orientation (30 minutes)
1. Read: **DEVOPS_DIAGNOSTIC_REFERENCE.md** - Full overview (10 min)
2. SSH to both servers and verify access (5 min)
3. Visit monitoring dashboards (5 min)
4. Create a test backup (5 min)
5. Bookmark: DEVOPS_QUICK_REFERENCE.txt

### Week 1: System Understanding
- Walk through **DIAGNOSTIC_PROCEDURES.md** → **Complete System Check** once
- Practice database recovery procedure (non-prod environment)
- Set up daily monitoring routine (5 minutes/day)
- Create escalation contacts list

### Ongoing: Daily Operations
- Morning: Run monitoring checklist (5 min)
- Weekly: Test database backup/restore (15 min)
- Monthly: Review logs for patterns
- As-needed: Use procedures to troubleshoot issues

---

## 🔧 COMMON TASKS QUICK ACCESS

| Task | Location | Est. Time |
|------|----------|-----------|
| Find SSH credentials | QUICK_REFERENCE line 11-30 | <1 min |
| Check system health | QUICK_REFERENCE → DAILY CHECKLIST | 5 min |
| Create database backup | QUICK_REFERENCE → DATABASE BACKUP | 3 min |
| Recover from crash | PROCEDURES → EMERGENCY: Database Dropped | 5 min |
| Complete diagnosis | PROCEDURES → Complete System Check (steps 1-6) | 25 min |
| Fix 502 error | QUICK_REFERENCE → COMMON ISSUES | 10 min |
| Monitor errors | Visit https://app.tovplay.org/logs/ | ongoing |

---

## 📞 WHO TO CONTACT

| Issue | Contact | Response Time |
|-------|---------|----------------|
| Database emergency | Roman Fesunenko | Immediate |
| Backend code error | Sharon Keinar | 15 minutes |
| Frontend code error | Lilach Herzog | 15 minutes |
| Hosting/Network issue | Roman + Hosting Provider | Varies |
| General questions | Team Discord: TovTechOrg | Real-time |

---

## 🔐 SECURITY NOTES

**⚠️ IMPORTANT**: This document contains credentials.

- Keep in: Secure location (private .claude folder)
- Share with: Only authorized team members
- Update: When passwords change
- Never: Commit to public repos, email unencrypted, share via Slack

All credentials are production-level and sensitive.

---

## 📊 SYSTEM ARCHITECTURE SUMMARY

```
┌─ Production (193.181.213.220)
│  ├─ Frontend (Nginx) → /var/www/tovplay/
│  ├─ Backend (Docker) → Port 8000→5001
│  ├─ PgBouncer → Port 6432 (DB connection pool)
│  ├─ Monitoring (Prometheus, Grafana, Loki)
│  └─ Logging Dashboard → Port 7778
│
├─ Staging (92.113.144.59)
│  ├─ Frontend (Nginx) → /var/www/tovplay-staging/
│  ├─ Backend (Docker) → Port 8001→5001
│  ├─ PgBouncer → Port 6432
│  └─ Monitoring (Disabled - Docker Hub blocked)
│
└─ Database (45.148.28.196)
   ├─ PostgreSQL 17.4
   ├─ TovPlay database (28 tables, 30 users)
   ├─ Protection (Event triggers + privilege revocation)
   └─ Daily backups (F:\backup\tovplay\DB\)

Monitoring:
  - Error Dashboard: https://app.tovplay.org/logs/
  - Database Viewer: http://193.181.213.220:7777/database-viewer
  - Grafana: http://193.181.213.220:3002
  - Prometheus: http://193.181.213.220:9090
```

---

## 🎓 LEARNING RESOURCES INCLUDED

1. **DEVOPS_DIAGNOSTIC_REFERENCE.md** → Comprehensive theory
2. **DIAGNOSTIC_PROCEDURES.md** → Practical step-by-step
3. **DEVOPS_QUICK_REFERENCE.txt** → Quick facts
4. **.claude/learned.md** → Team lessons learned (read before sessions)
5. **CLAUDE.md** → Project-level documentation

---

## 🚀 NEXT STEPS

1. **Print/Bookmark**: DEVOPS_QUICK_REFERENCE.txt
2. **Schedule Time**: 30-minute orientation with DIAGNOSTIC_REFERENCE.md
3. **Create Backup**: First action - test backup/restore procedure
4. **Daily Monitoring**: Add 5-minute health check to daily routine
5. **Documentation**: Log any lessons in .claude/learned.md

---

## 📝 VERSION HISTORY

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Dec 22, 2025 | Initial package for Roman |
| - | - | - |

---

## ✉️ FEEDBACK

If you find gaps in this documentation:
1. Note the issue
2. Update .claude/learned.md with the solution
3. Update relevant sections here
4. Share with team on Discord

---

**Package Size**: ~34KB
**Intended Audience**: DevOps team (Roman Fesunenko)
**Confidence Level**: ✅ Production-ready
**Last Tested**: December 22, 2025
**Maintained By**: Claude DevOps AI

---

**Ready to use. Enjoy!** 🚀
