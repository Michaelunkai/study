# Database Protection System - Complete Guide

Comprehensive guide to TovPlay database protection, integrity verification, and emergency recovery.

---

## Overview

The TovPlay database protection system provides multi-layered safeguards against:
- Accidental data deletion
- Unauthorized access
- Connection anomalies
- Deployment failures
- Data corruption

---

## Protection Layers

### 1. Database Triggers (Active)
```sql
-- See: db_protection_ultimate.sql for complete implementation
- Delete protection triggers on all critical tables
- Automatic audit logging for all modifications
- Connection tracking with IP/timestamp
- Bulk operation safeguards
```

### 2. Application-Level Validation
- Environment variable validation before DB operations
- Pre-deployment backup verification
- Connection pool monitoring
- Query timeout enforcement

### 3. Backup Strategy
- **Daily Automated**: 2:00 AM UTC
- **Pre-Deployment Manual**: Before every production push
- **Retention**: 30 days rolling
- **Storage**: F:\backup\tovplay\DB\

### 4. Monitoring & Alerts
- Real-time connection monitoring (Prometheus)
- Query performance tracking (Grafana)
- Automated alerts for suspicious activity
- Protection status dashboard

---

## Emergency Recovery Protocol

### Quick Recovery (< 5 minutes)
See: `EMERGENCY_DATABASE_RESTORATION_COMPLETE_DEC10_2025.md` for detailed steps

```bash
# 1. Find latest backup
$b=(gci F:\backup\tovplay\DB\*.sql|sort LastWriteTime -Desc)[0].FullName

# 2. Verify backup integrity
gc $b | Select-String "PostgreSQL database dump complete"

# 3. Restore
gc $b|wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay"

# 4. Verify restoration
wsl -d ubuntu bash -c "PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT COUNT(*) FROM \"User\";'"
```

### Protection Status Check
```sql
-- Check if protection is active
SELECT * FROM protection_status ORDER BY last_check DESC LIMIT 1;

-- Verify triggers are enabled
SELECT tgname, tgenabled FROM pg_trigger WHERE tgname LIKE '%protection%';

-- Check recent audit logs
SELECT * FROM connection_audit_log ORDER BY connected_at DESC LIMIT 10;
```

---

## Deployment Checklist

Before any production deployment:

- [ ] Create manual backup
- [ ] Verify backup integrity
- [ ] Check protection status (should be 'active')
- [ ] Review recent audit logs for anomalies
- [ ] Validate all environment variables
- [ ] Test database connection from deployment server
- [ ] Have rollback plan ready

---

## Key SQL Scripts

### Current Active Script
**File**: `db_protection_ultimate.sql` (21KB)
- Most comprehensive protection implementation
- All tables covered
- Full audit logging
- Connection tracking

### Historical Scripts (Archived)
- `bulletproof_db.sql` - Initial implementation
- `db_protection_comprehensive_v2.sql` - V2 iteration
- All others archived to `.claude/archive/2024-12-sessions/protection/`

---

## Monitoring Dashboards

### Grafana (http://193.181.213.220:3002)
- **Database Performance**: Query times, connection pool usage
- **Protection Status**: Real-time trigger status, audit log counts
- **Alerts**: Configured for mass deletes, connection spikes

### Prometheus (http://193.181.213.220:9090)
- Metrics: `postgresql_active_connections`, `postgresql_query_duration`
- Targets: postgres-exporter on production server

---

## Common Issues & Solutions

### Issue: Protection triggers disabled
**Solution**: Re-run `db_protection_ultimate.sql`

### Issue: Backup restore fails
**Solution**: Check PostgreSQL version compatibility, verify backup file integrity

### Issue: Slow query performance
**Solution**: Check `DATABASE_HISTORY.md` for optimization strategies

### Issue: Connection pool exhausted
**Solution**: Review `connection_audit_log` for connection leaks

---

## Historical Context

- **Dec 4, 2025**: Database wipe incident led to protection system creation
- **Dec 8, 2025**: Enhanced with performance optimizations
- **Dec 10, 2025**: Emergency recovery protocol established
- **Dec 11, 2025**: Protection system declared production-ready

See `DATABASE_HISTORY.md` for complete timeline.

---

## Quick Reference

**Current Protection SQL**: `db_protection_ultimate.sql`
**Emergency Recovery**: `EMERGENCY_DATABASE_RESTORATION_COMPLETE_DEC10_2025.md`
**Database History**: `DATABASE_HISTORY.md`
**Quick Commands**: `DB_PROTECTION_QUICK_REFERENCE.md`

**All historical protection docs**: `archive/2024-12-sessions/protection/`
