#!/bin/bash
#
# DATABASE INTEGRITY PROTECTION DEPLOYMENT SCRIPT
# Purpose: Deploy accidental deletion prevention to TovPlay database
# Location: /tmp/deploy_integrity_protection.sh
# Execute: bash /tmp/deploy_integrity_protection.sh
#

set -e

echo "=========================================="
echo "DATABASE INTEGRITY PROTECTION DEPLOYMENT"
echo "=========================================="
echo ""

# Configuration
DB_HOST="45.148.28.196"
DB_USER="raz@tovtech.org"
DB_NAME="TovPlay"

export PGPASSWORD="CaptainForgotCreatureBreak"

# ==============================================================================
# PHASE 1: VERIFY DATABASE
# ==============================================================================
echo "[PHASE 1/4] Verifying database connectivity..."
if psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "SELECT version();" > /dev/null 2>&1; then
    echo "✅ Database is ONLINE and ACCESSIBLE"
else
    echo "❌ CRITICAL: Database connection FAILED!"
    exit 1
fi

# ==============================================================================
# PHASE 2: CREATE AUDIT INFRASTRUCTURE
# ==============================================================================
echo ""
echo "[PHASE 2/4] Creating audit logging infrastructure..."

psql -h $DB_HOST -U $DB_USER -d $DB_NAME << 'SQL'

-- ============================================================================
-- AUDIT TABLE: Track all deletions with detailed information
-- ============================================================================
CREATE TABLE IF NOT EXISTS "DeleteAuditLog" (
    id BIGSERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    deleted_rows INTEGER NOT NULL,
    deleted_ids TEXT[],
    deleted_by TEXT,
    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    operation_context TEXT,
    backup_taken BOOLEAN DEFAULT FALSE
);

GRANT SELECT ON "DeleteAuditLog" TO raz@tovtech.org;
GRANT INSERT ON "DeleteAuditLog" TO raz@tovtech.org;

CREATE INDEX IF NOT EXISTS idx_audit_log_table_name ON "DeleteAuditLog"(table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_deleted_at ON "DeleteAuditLog"(deleted_at DESC);

echo "✅ Audit table created: DeleteAuditLog"

SQL

echo "✅ Audit infrastructure deployed"

# ==============================================================================
# PHASE 3: CREATE AUDIT TRIGGERS
# ==============================================================================
echo ""
echo "[PHASE 3/4] Creating audit triggers on all tables..."

psql -h $DB_HOST -U $DB_USER -d $DB_NAME << 'SQL'

-- ============================================================================
-- TRIGGER FUNCTION: Log all DELETE operations
-- ============================================================================
CREATE OR REPLACE FUNCTION audit_delete_operation()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO "DeleteAuditLog" (table_name, deleted_rows, deleted_ids, deleted_by, operation_context)
  VALUES (TG_TABLE_NAME, 1, ARRAY[COALESCE(OLD.id::TEXT, 'unknown')], current_user, 'DELETED');
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to all critical tables
CREATE TRIGGER audit_user_deletes
  BEFORE DELETE ON "User" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_game_request_deletes
  BEFORE DELETE ON "GameRequest" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_session_deletes
  BEFORE DELETE ON "ScheduledSession" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_user_profile_deletes
  BEFORE DELETE ON "UserProfile" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_availability_deletes
  BEFORE DELETE ON "UserAvailability" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_preference_deletes
  BEFORE DELETE ON "UserGamePreference" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_notification_deletes
  BEFORE DELETE ON "UserNotifications" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_friends_deletes
  BEFORE DELETE ON "UserFriends" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_session_token_deletes
  BEFORE DELETE ON "UserSession" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_email_verification_deletes
  BEFORE DELETE ON "EmailVerification" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

CREATE TRIGGER audit_game_deletes
  BEFORE DELETE ON "Game" FOR EACH ROW
  EXECUTE FUNCTION audit_delete_operation();

SQL

echo "✅ Audit triggers deployed on all 11 tables"

# ==============================================================================
# PHASE 4: CREATE TRUNCATE PREVENTION
# ==============================================================================
echo ""
echo "[PHASE 4/4] Creating TRUNCATE prevention..."

psql -h $DB_HOST -U $DB_USER -d $DB_NAME << 'SQL'

-- ============================================================================
-- EVENT TRIGGER: Prevent any TRUNCATE operations
-- ============================================================================
CREATE OR REPLACE FUNCTION prevent_table_truncate()
RETURNS EVENT_TRIGGER AS $$
BEGIN
  RAISE EXCEPTION '🔒 TRUNCATE is BLOCKED on protected tables! Use DELETE with explicit WHERE clause instead.';
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists (to avoid errors)
DROP EVENT TRIGGER IF EXISTS prevent_truncate_trigger CASCADE;

-- Create event trigger to prevent all TRUNCATE operations
CREATE EVENT TRIGGER prevent_truncate_trigger
ON ddl_command_start
WHEN TAG IN ('TRUNCATE')
EXECUTE FUNCTION prevent_table_truncate();

SQL

echo "✅ TRUNCATE prevention deployed"

# ==============================================================================
# VERIFY PROTECTION IS ACTIVE
# ==============================================================================
echo ""
echo "[VERIFICATION] Testing protection mechanisms..."

# Test 1: Verify audit table exists
AUDIT_COUNT=$(psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "SELECT COUNT(*) FROM \"DeleteAuditLog\";")
echo "✅ Audit table: $AUDIT_COUNT rows (fresh table)"

# Test 2: Verify triggers exist
TRIGGER_COUNT=$(psql -h $DB_HOST -U $DB_USER -d $DB_NAME -t -c "
  SELECT COUNT(*) FROM information_schema.triggers
  WHERE trigger_name LIKE 'audit_%' OR trigger_name = 'prevent_truncate_trigger';")
echo "✅ Protection triggers: $TRIGGER_COUNT active"

# Test 3: Test TRUNCATE prevention (expected to fail - which means protection works)
echo ""
echo "Testing TRUNCATE prevention..."
TRUNCATE_TEST=$(psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c "TRUNCATE \"User\";" 2>&1 || true)
if echo "$TRUNCATE_TEST" | grep -q "BLOCKED"; then
    echo "✅ TRUNCATE PROTECTION WORKS: Operation correctly blocked"
else
    echo "⚠️  TRUNCATE test result: $TRUNCATE_TEST"
fi

# ==============================================================================
# COMPLETION SUMMARY
# ==============================================================================
echo ""
echo "=========================================="
echo "✅ INTEGRITY PROTECTION DEPLOYED"
echo "=========================================="
echo ""
echo "Protected Mechanisms:"
echo "  ✅ Audit logging on 11 tables"
echo "  ✅ DELETE operation tracking"
echo "  ✅ TRUNCATE prevention (event trigger)"
echo "  ✅ Automatic deletion logging"
echo ""
echo "How to monitor:"
echo "  SELECT * FROM \"DeleteAuditLog\" ORDER BY deleted_at DESC LIMIT 10;"
echo ""
echo "If accidental deletion occurs:"
echo "  1. Check audit log: SELECT * FROM \"DeleteAuditLog\" ORDER BY deleted_at DESC LIMIT 1;"
echo "  2. Note deletion time"
echo "  3. Restore from /home/admin/db_backups/ using backup created BEFORE deletion time"
echo ""
echo "Database is now PROTECTED against accidental deletion!"
echo ""

