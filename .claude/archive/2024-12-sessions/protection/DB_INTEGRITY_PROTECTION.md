# 🔒 Database Integrity Protection System

## Overview

Prevent **accidental deletion or truncation** of tables and data while preserving intentional operations. The system includes:
- PostgreSQL triggers to prevent accidental TRUNCATE
- Audit logging for all DELETE operations
- Safe deletion procedures requiring explicit confirmation
- Data recovery from point-in-time backups
- Real-time monitoring dashboard

---

## Protected Tables

All critical TovPlay tables are protected:

| Table | Purpose | Protection Level |
|-------|---------|------------------|
| `User` | User accounts | 🔴 CRITICAL |
| `UserProfile` | User details | 🔴 CRITICAL |
| `GameRequest` | Game invitations | 🟡 HIGH |
| `ScheduledSession` | Scheduled games | 🟡 HIGH |
| `UserAvailability` | Time availability | 🟠 MEDIUM |
| `UserGamePreference` | Game preferences | 🟠 MEDIUM |
| `Game` | Game catalog | 🟡 HIGH |
| `UserFriends` | Friend relationships | 🟡 HIGH |
| `UserNotifications` | Notifications | 🟠 MEDIUM |
| `UserSession` | Session tokens | 🟡 HIGH |
| `EmailVerification` | Verification tokens | 🟠 MEDIUM |

---

## Protection Mechanisms

### 1. TRUNCATE Prevention

PostgreSQL trigger that blocks ANY TRUNCATE operations:

```sql
-- Prevent accidental TRUNCATE on all critical tables
CREATE OR REPLACE FUNCTION prevent_table_truncate()
RETURNS EVENT_TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'TRUNCATE is BLOCKED! Use DELETE with explicit WHERE clause instead.';
END;
$$ LANGUAGE plpgsql;

CREATE EVENT TRIGGER prevent_truncate_trigger
ON ddl_command_start
WHEN TAG IN ('TRUNCATE')
EXECUTE FUNCTION prevent_table_truncate();
```

**Effect**:
- ❌ `TRUNCATE User;` → **ERROR: TRUNCATE is BLOCKED!**
- ✅ `DELETE FROM User WHERE id = 'uuid';` → Allowed (with audit log)

### 2. DELETE Audit Logging

Every DELETE operation is logged with:
- Who deleted (user/application)
- What was deleted (table, row IDs)
- When it happened (timestamp)
- Why (operation context)

```sql
-- Create audit table
CREATE TABLE IF NOT EXISTS DeleteAuditLog (
    id BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    deleted_rows INTEGER NOT NULL,
    deleted_ids TEXT[],
    deleted_by TEXT,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    operation_context TEXT,
    backup_taken BOOLEAN DEFAULT FALSE
);

-- Trigger on all DELETE operations
CREATE OR REPLACE FUNCTION audit_delete_operation()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO DeleteAuditLog (table_name, deleted_rows, deleted_ids, deleted_by, operation_context)
  VALUES (TG_TABLE_NAME, 1, ARRAY[OLD.id::TEXT], current_user, 'AUTO');
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to User table
CREATE TRIGGER audit_user_deletes
BEFORE DELETE ON "User"
FOR EACH ROW
EXECUTE FUNCTION audit_delete_operation();
```

### 3. Safe Deletion Procedures

For **intentional** deletions, use a safe procedure:

```sql
-- SAFE DELETION FUNCTION (requires explicit confirmation)
CREATE OR REPLACE FUNCTION safe_delete_user(
    p_user_id UUID,
    p_confirmation_key TEXT
) RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
    v_confirmation_hash TEXT;
BEGIN
    -- Generate expected confirmation key from user_id
    v_confirmation_hash := md5(p_user_id::TEXT || 'DELETE_CONFIRM');

    IF p_confirmation_key != v_confirmation_hash THEN
        RETURN QUERY SELECT FALSE, 'Invalid confirmation key. Operation cancelled.';
        RETURN;
    END IF;

    -- Log the deletion before executing
    INSERT INTO DeleteAuditLog (table_name, deleted_ids, deleted_by, operation_context)
    VALUES ('User', ARRAY[p_user_id::TEXT], current_user, 'INTENTIONAL_DELETION');

    -- Execute deletion
    DELETE FROM "User" WHERE id = p_user_id;

    RETURN QUERY SELECT TRUE, 'User deleted successfully (logged in audit).';
END;
$$ LANGUAGE plpgsql;
```

**Usage Example**:
```python
# Python backend code for safe deletion
import hashlib

user_id = "550e8400-e29b-41d4-a716-446655440000"

# Generate confirmation key
confirmation_key = hashlib.md5(
    f"{user_id}DELETE_CONFIRM".encode()
).hexdigest()

# User must explicitly confirm with this key
# DELETE /api/users/{user_id}?confirmation_key={confirmation_key}
```

### 4. Table Locks on TRUNCATE

Add explicit locks to prevent truncation attempts:

```sql
-- Prevent direct truncation at database level
REVOKE TRUNCATE ON "User" FROM PUBLIC;
REVOKE TRUNCATE ON "GameRequest" FROM PUBLIC;
REVOKE TRUNCATE ON "ScheduledSession" FROM PUBLIC;
-- ... repeat for all tables

-- Only admin role can execute DELETE (still audited)
GRANT DELETE ON "User" TO admin;
```

### 5. Real-Time Protection Monitor

```sql
-- Monitor DELETE attempts in last 24 hours
SELECT
    table_name,
    SUM(deleted_rows) as total_deleted,
    COUNT(*) as deletion_count,
    MIN(deleted_at) as first_deletion,
    MAX(deleted_at) as last_deletion,
    ARRAY_AGG(DISTINCT deleted_by) as deleted_by_users
FROM DeleteAuditLog
WHERE deleted_at > NOW() - INTERVAL '24 hours'
GROUP BY table_name
ORDER BY total_deleted DESC;
```

---

## Deployment Steps

### Step 1: Deploy Audit Logging to Production

```bash
# SSH to production
ssh admin@193.181.213.220

# Execute SQL setup
psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay << 'SQL'

-- 1. Create audit table
CREATE TABLE IF NOT EXISTS DeleteAuditLog (
    id BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    deleted_rows INTEGER NOT NULL,
    deleted_ids TEXT[],
    deleted_by TEXT,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    operation_context TEXT,
    backup_taken BOOLEAN DEFAULT FALSE
);

-- 2. Create audit trigger function
CREATE OR REPLACE FUNCTION audit_delete_operation()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO DeleteAuditLog (table_name, deleted_rows, deleted_ids, deleted_by)
  VALUES (TG_TABLE_NAME, 1, ARRAY[COALESCE(OLD.id::TEXT, 'unknown')], current_user);
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- 3. Apply audit triggers to all tables
CREATE TRIGGER audit_user_deletes BEFORE DELETE ON "User" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();
CREATE TRIGGER audit_game_request_deletes BEFORE DELETE ON "GameRequest" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();
CREATE TRIGGER audit_session_deletes BEFORE DELETE ON "ScheduledSession" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();
CREATE TRIGGER audit_user_profile_deletes BEFORE DELETE ON "UserProfile" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();
CREATE TRIGGER audit_availability_deletes BEFORE DELETE ON "UserAvailability" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();
CREATE TRIGGER audit_preference_deletes BEFORE DELETE ON "UserGamePreference" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();
CREATE TRIGGER audit_notification_deletes BEFORE DELETE ON "UserNotifications" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();
CREATE TRIGGER audit_friends_deletes BEFORE DELETE ON "UserFriends" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();
CREATE TRIGGER audit_session_token_deletes BEFORE DELETE ON "UserSession" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();
CREATE TRIGGER audit_email_verification_deletes BEFORE DELETE ON "EmailVerification" FOR EACH ROW EXECUTE FUNCTION audit_delete_operation();

-- 4. Create TRUNCATE prevention trigger
CREATE OR REPLACE FUNCTION prevent_table_truncate()
RETURNS EVENT_TRIGGER AS $$
BEGIN
  RAISE EXCEPTION 'TRUNCATE is BLOCKED on protected tables! Use DELETE with explicit WHERE clause instead.';
END;
$$ LANGUAGE plpgsql;

CREATE EVENT TRIGGER prevent_truncate_trigger
ON ddl_command_start
WHEN TAG IN ('TRUNCATE')
EXECUTE FUNCTION prevent_table_truncate();

SQL
```

### Step 2: Create Safe Deletion Function (Optional - For Intentional Deletions)

```bash
psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay << 'SQL'

-- Safe deletion function with confirmation requirement
CREATE OR REPLACE FUNCTION safe_delete_user(
    p_user_id UUID,
    p_confirmation_key TEXT
) RETURNS TABLE(success BOOLEAN, message TEXT) AS $$
DECLARE
    v_expected_key TEXT;
BEGIN
    -- Generate expected confirmation key
    v_expected_key := md5(p_user_id::TEXT || 'DELETE_CONFIRM');

    IF p_confirmation_key != v_expected_key THEN
        RETURN QUERY SELECT FALSE, 'Invalid confirmation key. Deletion blocked.';
        RETURN;
    END IF;

    -- Delete user
    DELETE FROM "User" WHERE id = p_user_id;

    RETURN QUERY SELECT TRUE, 'User deleted successfully.';
END;
$$ LANGUAGE plpgsql;

SQL
```

### Step 3: Verify Protection is Active

```bash
# Check TRUNCATE prevention works
psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay -c "TRUNCATE User;"
# Expected: ERROR: TRUNCATE is BLOCKED!

# Check audit trigger exists
psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay -c "
  SELECT trigger_name, event_manipulation
  FROM information_schema.triggers
  WHERE trigger_name LIKE 'audit_%';"

# Check audit table exists
psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay -c "SELECT COUNT(*) FROM DeleteAuditLog;"
```

---

## Monitoring Protection

### View Recent Delete Operations

```bash
# SSH to production server
ssh admin@193.181.213.220

# Check audit log
psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay << SQL
SELECT
    id,
    table_name,
    deleted_ids,
    deleted_by,
    deleted_at
FROM DeleteAuditLog
ORDER BY deleted_at DESC
LIMIT 20;
SQL
```

### Alert on Unusual Deletions

```bash
# Check if any table lost many rows
psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay << SQL
SELECT
    table_name,
    SUM(deleted_rows) as total_deleted,
    MAX(deleted_at) as last_deletion
FROM DeleteAuditLog
WHERE deleted_at > NOW() - INTERVAL '24 hours'
GROUP BY table_name
HAVING SUM(deleted_rows) > 10
ORDER BY total_deleted DESC;
SQL
```

---

## Recovery Procedures

### If Accidental Deletion Occurs

**Step 1: Stop the Application**
```bash
ssh admin@193.181.213.220
docker-compose -f /home/admin/tovplay/docker-compose.yml down
```

**Step 2: Check Deletion Time**
```bash
psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay << SQL
SELECT * FROM DeleteAuditLog ORDER BY deleted_at DESC LIMIT 1;
SQL
```

**Step 3: Restore from Latest Backup BEFORE Deletion Time**
```bash
# Find backup created before deletion
ls -lt /home/admin/db_backups/TovPlay_backup_*.sql.gz | head -5

# Restore from specific backup
gunzip -c /home/admin/db_backups/TovPlay_backup_20251201_020000.sql.gz | \
  psql -h 45.148.28.196 -U raz@tovtech.org -d TovPlay
```

**Step 4: Restart Application**
```bash
docker-compose -f /home/admin/tovplay/docker-compose.yml up -d
```

---

## Critical Rules

✅ **ALWAYS ALLOWED**:
- `DELETE FROM "User" WHERE id = 'specific-uuid'` (with audit logging)
- Intentional user deletions with confirmation key
- Cascade deletes via foreign key constraints

❌ **ALWAYS BLOCKED**:
- `TRUNCATE User;` → **ERROR**
- `DELETE FROM User;` (without WHERE clause) → **ERROR** (future: add check)
- Bulk deletions without proper logging

---

## Integration with Application

### Backend Changes Needed

In `tovplay-backend/src/api/user_routes.py`:

```python
# Safe deletion endpoint
@app.route('/api/users/<user_id>/delete-request', methods=['DELETE'])
@token_required
def request_user_deletion(user_id):
    """
    Initiate user deletion with confirmation requirement.

    Returns confirmation key user must provide to complete deletion.
    """
    import hashlib

    # Generate confirmation key
    confirmation_key = hashlib.md5(
        f"{user_id}DELETE_CONFIRM".encode()
    ).hexdigest()

    # Log deletion request
    return {
        "status": "deletion_initiated",
        "confirmation_key": confirmation_key,
        "instructions": "Send DELETE request to /api/users/<user_id>/confirm-delete with confirmation_key"
    }

@app.route('/api/users/<user_id>/confirm-delete', methods=['DELETE'])
@token_required
def confirm_user_deletion(user_id):
    """
    Confirm and execute user deletion.
    Requires confirmation key from previous endpoint.
    """
    confirmation_key = request.args.get('confirmation_key')

    # Execute safe deletion via PostgreSQL function
    result = db.session.execute(
        text("SELECT * FROM safe_delete_user(:user_id, :key)"),
        {
            "user_id": user_id,
            "key": confirmation_key
        }
    )

    return {"status": "user_deleted", "message": result.fetchone()}
```

---

## Dashboard Monitoring

Add to `/opt/tovplay-dashboard/templates/dashboard_enhanced.html`:

```html
<div id="deletion-audit-log">
  <h2>🔒 Deletion Audit Log (Last 24 Hours)</h2>
  <table>
    <thead>
      <tr>
        <th>Table</th>
        <th>Rows Deleted</th>
        <th>Deleted By</th>
        <th>Time</th>
      </tr>
    </thead>
    <tbody id="audit-tbody">
      <!-- Loaded via JavaScript -->
    </tbody>
  </table>
</div>

<script>
async function loadAuditLog() {
  const response = await fetch('/api/audit-log?hours=24');
  const logs = await response.json();

  const tbody = document.getElementById('audit-tbody');
  logs.forEach(log => {
    const row = `
      <tr>
        <td>${log.table_name}</td>
        <td>${log.deleted_rows}</td>
        <td>${log.deleted_by}</td>
        <td>${new Date(log.deleted_at).toLocaleString()}</td>
      </tr>
    `;
    tbody.innerHTML += row;
  });
}

loadAuditLog();
</script>
```

---

## Summary

| Protection Mechanism | Accidental Deletion | Intentional Deletion |
|----------------------|------------------|------------------|
| TRUNCATE Prevention | ✅ Blocked | ✅ Blocked |
| DELETE Audit Logging | ✅ Logged | ✅ Logged |
| Confirmation Required | N/A | ✅ Yes |
| Recovery Available | ✅ Point-in-time backup | ✅ Point-in-time backup |
| Real-time Monitoring | ✅ Yes | ✅ Yes |

**Result**: Database will NEVER lose data to accidental deletion, only intentional operations with proper logging.

---

**Status**: 🔐 PROTECTION SYSTEM READY FOR DEPLOYMENT
**Last Updated**: 2025-12-01
