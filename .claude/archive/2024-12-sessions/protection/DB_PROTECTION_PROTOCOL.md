# 🔒 DATABASE PROTECTION PROTOCOL - CRITICAL
**Status**: LOCKED - NEVER DELETE, MODIFY, OR LOSE DATA

## CRITICAL FACTS
- **Database Location**: `45.148.28.196:5432` (External PostgreSQL Server)
- **Database Name**: `TovPlay`
- **Username**: `raz@tovtech.org`
- **Password**: `CaptainForgotCreatureBreak`
- **Real-time Dashboard**: `http://193.181.213.220:7777/database-viewer`
- **Container**: Running LOCALLY on production server in Docker

## ABSOLUTE RULES
1. ❌ **NEVER** delete the database
2. ❌ **NEVER** modify database schema without backup
3. ❌ **NEVER** truncate or clear tables
4. ❌ **NEVER** lose data integrity
5. ✅ **ALWAYS** maintain live real-time viewer
6. ✅ **ALWAYS** backup before any changes
7. ✅ **ALWAYS** verify dashboard shows current data

## Dashboard Viewer (Port 7777)
- **Purpose**: Real-time database viewer running on production server
- **Location**: `http://193.181.213.220:7777/database-viewer`
- **Implementation**:
  - File: `/opt/tovplay-dashboard/templates/dashboard_enhanced.html`
  - File: `/opt/tovplay-dashboard/templates/database_viewer.html`
  - App: `/opt/tovplay-dashboard/app.py`
- **Safe Operations**: Modify display logic, add new routes, update JS
- **Forbidden**: DB connections, SQL queries, schema changes

## Automated Backups
```powershell
# BACKUP DAILY (every 24 hours)
# Location: F:\backup\tovplay\DB\
# Pattern: tovplay_backup_YYYYMMDD_HHMMSS.sql
# Retention: Keep last 7 days
# Verify: Always check backup file size > 1MB
```

## Disaster Recovery (If Data Lost)
```powershell
# Step 1: Verify latest backup exists
Get-ChildItem "F:\backup\tovplay\DB" -Filter "*.sql" | Sort-Object LastWriteTime -Descending

# Step 2: Restore from latest backup
# See CLAUDE.md "DB Backup/Restore" section
```

## Container Database Protection
- **Docker**: tovtech/tovplay services running on `193.181.213.220`
- **Volume Mounts**: Database data persisted to disk
- **Never**: Stop container without graceful shutdown
- **Never**: Remove containers without backup
- **Always**: Use `docker compose down` (not `rm`)

## Monitoring Checklist
- [ ] Dashboard viewer accessible at port 7777
- [ ] Database-viewer route returns current data
- [ ] Last backup file dated within 24 hours
- [ ] Production database connection working
- [ ] All tables present and non-empty

## Claude Rules for DB Protection
- **Rule 1**: Before ANY backend changes, check if they touch DB schema
- **Rule 2**: If modifying user routes or models, backup first
- **Rule 3**: Test all changes on staging before production
- **Rule 4**: Zero-touch DB operations - use dashboards/admins only
- **Rule 5**: Document all manual DB interventions

## Emergency Contacts
- DB Server: `45.148.28.196` (admin@tovtech.org)
- Production: `193.181.213.220` (admin, EbTyNkfJG6LM)
- Dashboard restarts: `sudo systemctl restart tovplay-dashboard`

---
**Last Updated**: 2025-12-01
**Status**: 🔐 PROTECTED - DO NOT MODIFY
