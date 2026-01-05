# TovPlay Emergency Recovery Playbook

**KEEP THIS DOCUMENT ACCESSIBLE AT ALL TIMES**

---

## SCENARIO 1: Database Appears Offline

### Symptoms
- App shows "database connection failed"
- Monitoring: No connection from backend

### Recovery Steps

**1. Verify database server is online**
```bash
ping 45.148.28.196
```
If no response, contact hosting provider.

**2. Check if database exists**
```bash
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c '\l'
```

**3. If TovPlay database missing:**
```bash
# Create empty database
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c 'CREATE DATABASE "TovPlay"'

# Restore from latest backup
cd /opt/tovplay_backups/external
latest=$(ls -t *.sql | head -1)
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres < $latest
```

**4. Reinstall protections**
- Follow "SCENARIO 4: Triggers Disabled" section below

---

## SCENARIO 2: TRUNCATE Operation Blocked (User Frustrated)

### Symptoms
- User gets error: "TRUNCATE BLOCKED"
- Says they need to clear all records from a table

### Assessment
**This is WORKING AS INTENDED.** TRUNCATE is blocked to prevent accidental data wipes.

### Solution
If deletion is genuinely needed:

**1. Verify request is legitimate**
- Who is requesting? What's the business reason?
- Is this a cleanup or accidental operation?

**2. Contact Michael Fedorovsky for authorization**
- Decision: Remove trigger temporarily OR do row-by-row deletes (max 5 at a time)

**3. If authorized, remove specific trigger**
```bash
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'DROP TRIGGER block_truncate_user ON "User"'
```

**4. Perform operation and reinstall trigger**
```bash
# Truncate operation...

# Reinstall trigger
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay << EOF
CREATE TRIGGER block_truncate_user
    BEFORE TRUNCATE ON "User"
    EXECUTE FUNCTION block_truncate();
EOF
```

---

## SCENARIO 3: Need to Restore to Specific Date

### Symptoms
- Data got corrupted a few days ago
- Need to restore to specific point in time

### Recovery Steps

**1. Find backup from desired date**
```bash
ssh admin@193.181.213.220
ls -lah /opt/tovplay_backups/external/tovplay_external_YYYYMMDD*.sql
# Or daily snapshots:
ls -lah /opt/tovplay_backups/daily/tovplay_daily_YYYYMMDD.sql.gz
```

**2. List available backups**
```bash
# Show backups by date
ls -1 /opt/tovplay_backups/external/ | sort
```

**3. Restore from backup**
```bash
# Drop current database
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c 'DROP DATABASE "TovPlay"'

# Create fresh database
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres -c 'CREATE DATABASE "TovPlay"'

# Restore from selected backup
backup_file='/opt/tovplay_backups/external/tovplay_external_YYYYMMDD_HHMMSS.sql'
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d postgres < $backup_file
```

**4. Verify restoration**
```bash
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay << EOF
SELECT COUNT(*) as users FROM "User";
SELECT COUNT(*) as games FROM "Game";
SELECT COUNT(*) as requests FROM "GameRequest";
EOF
```

**5. Reinstall all protections (see SCENARIO 4)**

---

## SCENARIO 4: Triggers Not Blocking (Need to Reinstall)

### Symptoms
- TRUNCATE operations succeeding (should be blocked)
- Mass DELETE operations not being limited
- Triggers were disabled for troubleshooting and forgot to reinstall

### Quick Reinstall All Protections

**Run this Python script:**
```python
import psycopg2

conn = psycopg2.connect(
    host='45.148.28.196',
    user='raz@tovtech.org',
    password='CaptainForgotCreatureBreak',
    database='TovPlay'
)
cur = conn.cursor()

# Recreate TRUNCATE blocker
cur.execute("""
CREATE OR REPLACE FUNCTION block_truncate()
RETURNS TRIGGER AS $func$
BEGIN
    RAISE EXCEPTION 'TRUNCATE BLOCKED on table %: Contact Michael', TG_TABLE_NAME;
    RETURN NULL;
END;
$func$ LANGUAGE plpgsql;
""")

# Recreate mass DELETE blocker
cur.execute("""
CREATE OR REPLACE FUNCTION block_mass_delete()
RETURNS TRIGGER AS $func$
DECLARE delete_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO delete_count FROM old_table;
    IF delete_count > 5 THEN
        RAISE EXCEPTION 'MASS DELETE BLOCKED: % rows attempted, max 5 allowed', delete_count;
    END IF;
    RETURN NULL;
END;
$func$ LANGUAGE plpgsql;
""")

tables = ['User', 'Game', 'GameRequest', 'ScheduledSession', 'UserProfile',
          'UserAvailability', 'UserFriends', 'UserGamePreference',
          'UserNotifications', 'EmailVerification', 'UserSession']

# Recreate all TRUNCATE triggers
for table in tables:
    trigger_name = f'block_truncate_{table.lower()}'
    cur.execute(f'DROP TRIGGER IF EXISTS {trigger_name} ON "{table}" CASCADE')
    cur.execute(f'''CREATE TRIGGER {trigger_name}
        BEFORE TRUNCATE ON "{table}"
        EXECUTE FUNCTION block_truncate()''')

# Recreate all DELETE triggers
for table in tables:
    trigger_name = f'block_mass_delete_{table.lower()}'
    cur.execute(f'DROP TRIGGER IF EXISTS {trigger_name} ON "{table}" CASCADE')
    cur.execute(f'''CREATE TRIGGER {trigger_name}
        AFTER DELETE ON "{table}"
        REFERENCING OLD TABLE AS old_table
        FOR EACH STATEMENT
        EXECUTE FUNCTION block_mass_delete()''')

conn.commit()
print("All protections reinstalled successfully")
conn.close()
```

**And reinstall DROP DATABASE protection on postgres database:**
```python
import psycopg2

conn = psycopg2.connect(
    host='45.148.28.196',
    user='raz@tovtech.org',
    password='CaptainForgotCreatureBreak',
    database='postgres'
)
cur = conn.cursor()

cur.execute("""
CREATE OR REPLACE FUNCTION prevent_drop_database()
RETURNS event_trigger AS $func$
DECLARE obj record;
BEGIN
    FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
        IF obj.object_type = 'database' THEN
            RAISE EXCEPTION 'DROP DATABASE BLOCKED - Contact Michael Fedorovsky';
        END IF;
    END LOOP;
END;
$func$ LANGUAGE plpgsql;
""")

cur.execute('DROP EVENT TRIGGER IF EXISTS block_drop_database CASCADE')
cur.execute('CREATE EVENT TRIGGER block_drop_database ON sql_drop EXECUTE FUNCTION prevent_drop_database()')
cur.execute('ALTER EVENT TRIGGER block_drop_database ENABLE')

conn.commit()
print("DROP DATABASE protection reinstalled")
conn.close()
```

---

## SCENARIO 5: Investigate Audit Log

### Symptoms
- Suspicious activity in logs
- Need to find who did what

### Audit Log Query

**View recent suspicious activity:**
```sql
SELECT * FROM auditlog
ORDER BY event_timestamp DESC
LIMIT 50;
```

**Find activity by specific user:**
```sql
SELECT * FROM auditlog
WHERE user_account = 'raz@tovtech.org'
ORDER BY event_timestamp DESC;
```

**Find activity by IP:**
```sql
SELECT * FROM auditlog
WHERE user_ip = '37.142.178.102'
ORDER BY event_timestamp DESC;
```

**Find failed/blocked operations:**
```sql
SELECT * FROM auditlog
WHERE error_details LIKE '%BLOCKED%'
ORDER BY event_timestamp DESC;
```

---

## SCENARIO 6: Grant Someone TRUNCATE Permission

### Symptoms
- Legitimate admin needs to perform bulk operations
- Currently can't because TRUNCATE is blocked

### Steps

**1. Decision:**
- Is this user authorized?
- Should be Michael Fedorovsky or designated admin

**2. Remove triggers temporarily**
```bash
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay << EOF
DROP TRIGGER block_truncate_user ON "User";
DROP TRIGGER block_truncate_game ON "Game";
-- ... drop for other tables as needed
EOF
```

**3. Perform operation**
```sql
TRUNCATE "User" CASCADE;
```

**4. Reinstall triggers (CRITICAL)**
```bash
# Use SCENARIO 4 script to reinstall all
```

---

## SCENARIO 7: Backup System Failing

### Symptoms
- Backup log shows errors
- Backups not being created
- Disk space warnings

### Check Backup Health

**View backup log:**
```bash
ssh admin@193.181.213.220
tail -50 /var/log/db_backups.log
```

**Check backup directory space:**
```bash
ssh admin@193.181.213.220
df -h /opt/tovplay_backups/
du -sh /opt/tovplay_backups/*
```

**Test backup manually:**
```bash
ssh admin@193.181.213.220
/opt/dual_backup.sh
```

**If failing, check PostgreSQL connection:**
```bash
ssh admin@193.181.213.220
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -c 'SELECT COUNT(*) FROM "User"'
```

**Clean up old backups if disk full:**
```bash
# Delete backups older than 14 days
find /opt/tovplay_backups/external -name "*.sql" -mtime +14 -delete
find /opt/tovplay_backups/daily -name "*.sql.gz" -mtime +60 -delete
```

---

## CRITICAL CONTACTS

| Role | Name | Email | Purpose |
|------|------|-------|---------|
| Lead DevOps | Michael Fedorovsky | michael@tovtech.org | Database authorization, emergency access |
| Backend Lead | Roman Fesunenko | roman.fesunenko@gmail.com | Application impact assessment |
| Infrastructure | Admin SSH | admin@193.181.213.220 | Server access (username: admin) |

---

## PASSWORD REFERENCE

| System | User | Password | Host |
|--------|------|----------|------|
| PostgreSQL (Admin) | raz@tovtech.org | CaptainForgotCreatureBreak | 45.148.28.196:5432 |
| PostgreSQL (Read-Only) | tovplay_readonly | ReadOnly_SecurePass2025_TovPlay | 45.148.28.196:5432 |
| Production Server | admin | EbTyNkfJG6LM | 193.181.213.220 (SSH) |

**SECURITY: These passwords should be in a secure vault, not documentation.**

---

## QUICK REFERENCE COMMANDS

```bash
# Connect to database
PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay

# SSH to production
ssh admin@193.181.213.220  # password: EbTyNkfJG6LM

# View latest 10 backups
ls -lhat /opt/tovplay_backups/external/ | head -10

# Check backup health
tail -20 /var/log/db_backups.log

# List all tables
SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;

# Verify all triggers
SELECT schemaname, tablename, triggername FROM pg_triggers;

# Check event triggers
SELECT evtname, evtenabled FROM pg_event_trigger;
```

---

## DO NOT FORGET

1. **After ANY major operation, reinstall protections** (SCENARIO 4)
2. **Always test restoration procedures** (weekly)
3. **Monitor backup health** (daily)
4. **Review audit log** (weekly for suspicious activity)
5. **Keep this playbook accessible** and up-to-date

---

**Last Updated:** 2025-12-15
**Created:** After database incident of 2025-12-15 09:10-09:20 UTC
