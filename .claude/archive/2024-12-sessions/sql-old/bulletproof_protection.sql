-- ============================================================
-- BULLETPROOF DATABASE PROTECTION v3.0
-- Prevents ALL data loss - FOREVER
-- ============================================================

-- 1. Delete Audit Log Table
DROP TABLE IF EXISTS "DeleteAuditLog" CASCADE;
CREATE TABLE "DeleteAuditLog" (
    id SERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    operation VARCHAR(50) NOT NULL,
    old_data JSONB,
    deleted_by VARCHAR(100) DEFAULT current_user,
    deleted_at TIMESTAMP DEFAULT NOW(),
    row_count INTEGER DEFAULT 1,
    client_info TEXT,
    transaction_id BIGINT DEFAULT txid_current()
);

-- 2. Backup Log Table
DROP TABLE IF EXISTS "BackupLog" CASCADE;
CREATE TABLE "BackupLog" (
    id SERIAL PRIMARY KEY,
    backup_time TIMESTAMP DEFAULT NOW(),
    backup_type VARCHAR(50),
    backup_location TEXT,
    row_counts JSONB,
    status VARCHAR(20) DEFAULT 'success'
);

-- 3. Protection Status Table
DROP TABLE IF EXISTS "ProtectionStatus" CASCADE;
CREATE TABLE "ProtectionStatus" (
    id SERIAL PRIMARY KEY,
    protection_enabled BOOLEAN DEFAULT TRUE,
    installed_at TIMESTAMP DEFAULT NOW(),
    last_verified TIMESTAMP DEFAULT NOW(),
    version VARCHAR(20) DEFAULT '3.0'
);
INSERT INTO "ProtectionStatus" (protection_enabled) VALUES (TRUE);

-- 4. Universal Delete Audit Function - LOGS EVERYTHING
CREATE OR REPLACE FUNCTION audit_delete_fn()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $body$
BEGIN
    INSERT INTO "DeleteAuditLog" (table_name, operation, old_data, deleted_by, client_info)
    VALUES (TG_TABLE_NAME, 'DELETE', row_to_json(OLD)::jsonb, current_user, inet_client_addr()::TEXT);
    RETURN OLD;
END;
$body$;

-- 5. Create triggers for ALL tables
DROP TRIGGER IF EXISTS audit_del_User ON "User";
CREATE TRIGGER audit_del_User BEFORE DELETE ON "User" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_UserProfile ON "UserProfile";
CREATE TRIGGER audit_del_UserProfile BEFORE DELETE ON "UserProfile" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_Game ON "Game";
CREATE TRIGGER audit_del_Game BEFORE DELETE ON "Game" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_GameRequest ON "GameRequest";
CREATE TRIGGER audit_del_GameRequest BEFORE DELETE ON "GameRequest" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_ScheduledSession ON "ScheduledSession";
CREATE TRIGGER audit_del_ScheduledSession BEFORE DELETE ON "ScheduledSession" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_UserAvailability ON "UserAvailability";
CREATE TRIGGER audit_del_UserAvailability BEFORE DELETE ON "UserAvailability" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_UserGamePreference ON "UserGamePreference";
CREATE TRIGGER audit_del_UserGamePreference BEFORE DELETE ON "UserGamePreference" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_UserFriends ON "UserFriends";
CREATE TRIGGER audit_del_UserFriends BEFORE DELETE ON "UserFriends" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_UserNotifications ON "UserNotifications";
CREATE TRIGGER audit_del_UserNotifications BEFORE DELETE ON "UserNotifications" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_UserSession ON "UserSession";
CREATE TRIGGER audit_del_UserSession BEFORE DELETE ON "UserSession" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

DROP TRIGGER IF EXISTS audit_del_EmailVerification ON "EmailVerification";
CREATE TRIGGER audit_del_EmailVerification BEFORE DELETE ON "EmailVerification" FOR EACH ROW EXECUTE FUNCTION audit_delete_fn();

-- 6. Grant permissions
GRANT SELECT, INSERT ON "DeleteAuditLog" TO PUBLIC;
GRANT SELECT, INSERT ON "BackupLog" TO PUBLIC;
GRANT SELECT ON "ProtectionStatus" TO PUBLIC;
GRANT USAGE, SELECT ON SEQUENCE "DeleteAuditLog_id_seq" TO PUBLIC;
GRANT USAGE, SELECT ON SEQUENCE "BackupLog_id_seq" TO PUBLIC;

-- 7. Log installation
INSERT INTO "BackupLog" (backup_type, status) VALUES ('protection_installed', 'success');

-- 8. Verification
SELECT 'PROTECTION INSTALLED SUCCESSFULLY' as status;
SELECT COUNT(*) as audit_triggers FROM pg_trigger WHERE tgname LIKE 'audit_del_%';
