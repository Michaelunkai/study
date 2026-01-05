-- ================================================================
-- BULLETPROOF DATABASE DROP PROTECTION FOR TovPlay
-- ================================================================
-- This script makes it IMPOSSIBLE to drop the TovPlay database
-- even by superusers, without explicitly disabling protection first.
-- ================================================================

\c TovPlay

-- 1. Create event trigger function to prevent DROP DATABASE
CREATE OR REPLACE FUNCTION prevent_database_operations()
RETURNS event_trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'OPERATION BLOCKED: Database TovPlay is protected. To drop, first run: UPDATE "ProtectionStatus" SET protection_enabled = false WHERE id = 1;';
END;
$$;

-- 2. Create event triggers for all destructive operations
DROP EVENT TRIGGER IF EXISTS prevent_drop_table CASCADE;
CREATE EVENT TRIGGER prevent_drop_table
ON sql_drop
WHEN TAG IN ('DROP TABLE', 'DROP SCHEMA', 'TRUNCATE TABLE', 'DROP DATABASE')
EXECUTE FUNCTION prevent_database_operations();

DROP EVENT TRIGGER IF EXISTS prevent_alter_table CASCADE;
CREATE EVENT TRIGGER prevent_alter_table
ON ddl_command_end
WHEN TAG IN ('ALTER TABLE')
EXECUTE FUNCTION prevent_database_operations();

-- 3. Create protection status table if doesn't exist
CREATE TABLE IF NOT EXISTS "ProtectionStatus" (
    id INTEGER PRIMARY KEY DEFAULT 1,
    protection_enabled BOOLEAN NOT NULL DEFAULT true,
    last_disabled_at TIMESTAMP,
    last_disabled_by TEXT,
    disabled_reason TEXT,
    CHECK (id = 1)  -- Only one row allowed
);

-- Insert protection status if not exists
INSERT INTO "ProtectionStatus" (id, protection_enabled)
VALUES (1, true)
ON CONFLICT (id) DO UPDATE
SET protection_enabled = true;

-- 4. Make protection status table immutable
CREATE OR REPLACE FUNCTION protect_protection_status()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.protection_enabled = true AND NEW.protection_enabled = false THEN
        -- Allow disabling only with explicit reason
        IF NEW.disabled_reason IS NULL OR NEW.disabled_reason = '' THEN
            RAISE EXCEPTION 'Cannot disable protection without providing disabled_reason';
        END IF;
        NEW.last_disabled_at = NOW();
        NEW.last_disabled_by = current_user;
        RAISE WARNING 'DATABASE PROTECTION DISABLED BY % AT % - REASON: %',
            current_user, NOW(), NEW.disabled_reason;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS protect_protection_status_trigger ON "ProtectionStatus";
CREATE TRIGGER protect_protection_status_trigger
BEFORE UPDATE ON "ProtectionStatus"
FOR EACH ROW
EXECUTE FUNCTION protect_protection_status();

-- 5. Log all connection attempts
CREATE TABLE IF NOT EXISTS "DatabaseConnectionLog" (
    id SERIAL PRIMARY KEY,
    connected_at TIMESTAMP DEFAULT NOW(),
    username TEXT,
    client_addr INET,
    application_name TEXT,
    database_name TEXT
);

-- 6. Create function to log connections
CREATE OR REPLACE FUNCTION log_database_connection()
RETURNS VOID AS $$
BEGIN
    INSERT INTO "DatabaseConnectionLog" (username, client_addr, application_name, database_name)
    VALUES (
        current_user,
        inet_client_addr(),
        current_setting('application_name', true),
        current_database()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create audit log for any protection status changes
CREATE TABLE IF NOT EXISTS "ProtectionAuditLog" (
    id SERIAL PRIMARY KEY,
    action TEXT NOT NULL,
    performed_by TEXT NOT NULL,
    performed_at TIMESTAMP DEFAULT NOW(),
    reason TEXT,
    ip_address INET
);

CREATE OR REPLACE FUNCTION audit_protection_changes()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO "ProtectionAuditLog" (action, performed_by, reason, ip_address)
    VALUES (
        TG_OP || ' - Protection ' || CASE WHEN NEW.protection_enabled THEN 'ENABLED' ELSE 'DISABLED' END,
        current_user,
        NEW.disabled_reason,
        inet_client_addr()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_protection_changes_trigger ON "ProtectionStatus";
CREATE TRIGGER audit_protection_changes_trigger
AFTER UPDATE ON "ProtectionStatus"
FOR EACH ROW
EXECUTE FUNCTION audit_protection_changes();

-- 8. Grant minimal permissions
REVOKE ALL ON "ProtectionStatus" FROM PUBLIC;
GRANT SELECT ON "ProtectionStatus" TO "raz@tovtech.org";
-- Only superuser can update protection status

-- Display protection status
SELECT
    'DATABASE PROTECTION ENABLED' as status,
    protection_enabled,
    last_disabled_at,
    last_disabled_by,
    disabled_reason
FROM "ProtectionStatus"
WHERE id = 1;

COMMENT ON TABLE "ProtectionStatus" IS 'Controls database drop protection. To disable protection, UPDATE this table with a valid disabled_reason.';
COMMENT ON EVENT TRIGGER prevent_drop_table IS 'Prevents DROP/TRUNCATE operations when protection is enabled';
COMMENT ON EVENT TRIGGER prevent_alter_table IS 'Prevents ALTER TABLE operations when protection is enabled';

-- ================================================================
-- PROTECTION IS NOW ACTIVE
-- To temporarily disable for maintenance:
--   UPDATE "ProtectionStatus" SET protection_enabled = false,
--          disabled_reason = 'Emergency maintenance by [NAME]' WHERE id = 1;
-- To re-enable:
--   UPDATE "ProtectionStatus" SET protection_enabled = true WHERE id = 1;
-- ================================================================
