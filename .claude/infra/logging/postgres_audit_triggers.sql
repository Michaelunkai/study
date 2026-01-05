-- ============================================================================
-- POSTGRESQL AUDIT TRIGGERS - TovPlay Production
-- ============================================================================
-- Comprehensive database-level audit trail for forensic analysis
-- Tracks WHO/WHEN/WHAT/WHY for all database operations at table level
--
-- Features:
-- - Automatic tracking of all INSERT/UPDATE/DELETE operations
-- - Row-level change tracking (before/after values)
-- - User identification (application user + DB user)
-- - Timestamp tracking (when operation occurred)
-- - Operation type tracking (INSERT/UPDATE/DELETE)
-- - Change delta tracking (what changed)
--
-- Deploy:
-- PGPASSWORD='CaptainForgotCreatureBreak' psql -h 45.148.28.196 -U 'raz@tovtech.org' -d TovPlay -f postgres_audit_triggers.sql
-- ============================================================================

-- ============================================================================
-- AUDIT LOG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_log_db (
    id BIGSERIAL PRIMARY KEY,

    -- When
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),

    -- Who
    db_user VARCHAR(100) NOT NULL,
    app_user_id INTEGER,
    app_username VARCHAR(100),
    ip_address INET,
    correlation_id VARCHAR(50),

    -- What
    operation VARCHAR(10) NOT NULL CHECK (operation IN ('INSERT', 'UPDATE', 'DELETE')),
    table_name VARCHAR(100) NOT NULL,
    record_id VARCHAR(100),

    -- Change details
    old_values JSONB,
    new_values JSONB,
    changed_fields JSONB,

    -- Context
    query TEXT,
    application_name VARCHAR(100),

    -- Indexing
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- INDEXES FOR FAST FORENSIC QUERIES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_audit_log_db_timestamp ON audit_log_db (timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_app_user_id ON audit_log_db (app_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_operation ON audit_log_db (operation);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_table_name ON audit_log_db (table_name);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_record_id ON audit_log_db (table_name, record_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_correlation_id ON audit_log_db (correlation_id);

-- GIN indexes for JSONB columns (fast JSON queries)
CREATE INDEX IF NOT EXISTS idx_audit_log_db_old_values_gin ON audit_log_db USING GIN (old_values);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_new_values_gin ON audit_log_db USING GIN (new_values);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_changed_fields_gin ON audit_log_db USING GIN (changed_fields);

-- Composite indexes for common forensic queries
CREATE INDEX IF NOT EXISTS idx_audit_log_db_user_timestamp ON audit_log_db (app_user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_table_timestamp ON audit_log_db (table_name, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_db_table_record ON audit_log_db (table_name, record_id, timestamp DESC);

COMMENT ON TABLE audit_log_db IS 'Database-level audit trail for all table operations';
COMMENT ON COLUMN audit_log_db.db_user IS 'PostgreSQL user who performed the operation';
COMMENT ON COLUMN audit_log_db.app_user_id IS 'Application user ID (from session context)';
COMMENT ON COLUMN audit_log_db.operation IS 'Type of operation: INSERT, UPDATE, DELETE';
COMMENT ON COLUMN audit_log_db.old_values IS 'Row values before operation (UPDATE/DELETE)';
COMMENT ON COLUMN audit_log_db.new_values IS 'Row values after operation (INSERT/UPDATE)';
COMMENT ON COLUMN audit_log_db.changed_fields IS 'Fields that changed (UPDATE only)';

-- ============================================================================
-- SESSION CONTEXT VARIABLES (FOR USER TRACKING)
-- ============================================================================

-- Application should set these at the start of each request:
-- SET LOCAL app.user_id = '123';
-- SET LOCAL app.username = 'john_doe';
-- SET LOCAL app.ip_address = '192.168.1.1';
-- SET LOCAL app.correlation_id = '550e8400-e29b-41d4-a716-446655440000';

-- ============================================================================
-- GENERIC AUDIT TRIGGER FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION audit_trigger_func()
RETURNS TRIGGER AS $$
DECLARE
    audit_row audit_log_db%ROWTYPE;
    changed_fields JSONB;
    old_json JSONB;
    new_json JSONB;
    record_id_value VARCHAR(100);
BEGIN
    -- Initialize audit row
    audit_row.timestamp = NOW();
    audit_row.db_user = current_user;
    audit_row.table_name = TG_TABLE_NAME;
    audit_row.operation = TG_OP;
    audit_row.query = current_query();
    audit_row.application_name = current_setting('application_name', true);

    -- Get application context (if set)
    BEGIN
        audit_row.app_user_id = current_setting('app.user_id', true)::INTEGER;
    EXCEPTION WHEN OTHERS THEN
        audit_row.app_user_id = NULL;
    END;

    BEGIN
        audit_row.app_username = current_setting('app.username', true);
    EXCEPTION WHEN OTHERS THEN
        audit_row.app_username = NULL;
    END;

    BEGIN
        audit_row.ip_address = current_setting('app.ip_address', true)::INET;
    EXCEPTION WHEN OTHERS THEN
        audit_row.ip_address = NULL;
    END;

    BEGIN
        audit_row.correlation_id = current_setting('app.correlation_id', true);
    EXCEPTION WHEN OTHERS THEN
        audit_row.correlation_id = NULL;
    END;

    -- Handle different operation types
    IF (TG_OP = 'INSERT') THEN
        new_json = to_jsonb(NEW);
        audit_row.new_values = new_json;
        audit_row.record_id = COALESCE(NEW.id::VARCHAR, NULL);

    ELSIF (TG_OP = 'UPDATE') THEN
        old_json = to_jsonb(OLD);
        new_json = to_jsonb(NEW);
        audit_row.old_values = old_json;
        audit_row.new_values = new_json;
        audit_row.record_id = COALESCE(NEW.id::VARCHAR, OLD.id::VARCHAR);

        -- Calculate changed fields
        changed_fields = jsonb_object_agg(
            key,
            jsonb_build_object(
                'old', old_json->key,
                'new', new_json->key
            )
        )
        FROM jsonb_each(old_json) AS e(key, value)
        WHERE old_json->key IS DISTINCT FROM new_json->key;

        audit_row.changed_fields = changed_fields;

    ELSIF (TG_OP = 'DELETE') THEN
        old_json = to_jsonb(OLD);
        audit_row.old_values = old_json;
        audit_row.record_id = COALESCE(OLD.id::VARCHAR, NULL);
    END IF;

    -- Insert audit record
    INSERT INTO audit_log_db (
        timestamp, db_user, app_user_id, app_username, ip_address, correlation_id,
        operation, table_name, record_id, old_values, new_values, changed_fields,
        query, application_name
    ) VALUES (
        audit_row.timestamp, audit_row.db_user, audit_row.app_user_id,
        audit_row.app_username, audit_row.ip_address, audit_row.correlation_id,
        audit_row.operation, audit_row.table_name, audit_row.record_id,
        audit_row.old_values, audit_row.new_values, audit_row.changed_fields,
        audit_row.query, audit_row.application_name
    );

    -- Return appropriate row
    IF (TG_OP = 'DELETE') THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION audit_trigger_func() IS 'Generic audit trigger function for all tables';

-- ============================================================================
-- HELPER FUNCTION: ENABLE AUDIT FOR TABLE
-- ============================================================================

CREATE OR REPLACE FUNCTION enable_audit_for_table(table_name_param VARCHAR)
RETURNS VOID AS $$
BEGIN
    -- Create trigger for INSERT
    EXECUTE format('
        CREATE TRIGGER audit_trigger_insert
        AFTER INSERT ON %I
        FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
    ', table_name_param);

    -- Create trigger for UPDATE
    EXECUTE format('
        CREATE TRIGGER audit_trigger_update
        AFTER UPDATE ON %I
        FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
    ', table_name_param);

    -- Create trigger for DELETE
    EXECUTE format('
        CREATE TRIGGER audit_trigger_delete
        AFTER DELETE ON %I
        FOR EACH ROW EXECUTE FUNCTION audit_trigger_func();
    ', table_name_param);

    RAISE NOTICE 'Audit triggers enabled for table: %', table_name_param;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION enable_audit_for_table(VARCHAR) IS 'Enable audit triggers for a specific table';

-- ============================================================================
-- HELPER FUNCTION: DISABLE AUDIT FOR TABLE
-- ============================================================================

CREATE OR REPLACE FUNCTION disable_audit_for_table(table_name_param VARCHAR)
RETURNS VOID AS $$
BEGIN
    EXECUTE format('DROP TRIGGER IF EXISTS audit_trigger_insert ON %I', table_name_param);
    EXECUTE format('DROP TRIGGER IF EXISTS audit_trigger_update ON %I', table_name_param);
    EXECUTE format('DROP TRIGGER IF EXISTS audit_trigger_delete ON %I', table_name_param);

    RAISE NOTICE 'Audit triggers disabled for table: %', table_name_param;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION disable_audit_for_table(VARCHAR) IS 'Disable audit triggers for a specific table';

-- ============================================================================
-- ENABLE AUDIT FOR CRITICAL TABLES
-- ============================================================================

-- Enable audit for critical tables
SELECT enable_audit_for_table('user');
SELECT enable_audit_for_table('game');
SELECT enable_audit_for_table('gamerequest');
SELECT enable_audit_for_table('scheduledsession');
SELECT enable_audit_for_table('userprofile');
SELECT enable_audit_for_table('useravailability');
SELECT enable_audit_for_table('userfriends');
SELECT enable_audit_for_table('usergamepreference');
SELECT enable_audit_for_table('usernotifications');
SELECT enable_audit_for_table('emailverification');
SELECT enable_audit_for_table('usersession');
SELECT enable_audit_for_table('password_reset_tokens');

-- Enable audit for protection/admin tables
SELECT enable_audit_for_table('protectionstatus');
SELECT enable_audit_for_table('backuplog');
SELECT enable_audit_for_table('connectionauditlog');
SELECT enable_audit_for_table('deleteauditlog');

-- ============================================================================
-- FORENSIC QUERY TEMPLATES
-- ============================================================================

-- Query 1: Find who deleted a specific game
-- SELECT * FROM audit_log_db
-- WHERE table_name = 'game'
--   AND operation = 'DELETE'
--   AND record_id = '123'
-- ORDER BY timestamp DESC;

-- Query 2: Find all actions by a specific user
-- SELECT * FROM audit_log_db
-- WHERE app_user_id = 123
-- ORDER BY timestamp DESC;

-- Query 3: Find all changes to a specific record
-- SELECT * FROM audit_log_db
-- WHERE table_name = 'user'
--   AND record_id = '456'
-- ORDER BY timestamp DESC;

-- Query 4: Find who changed a specific field
-- SELECT * FROM audit_log_db
-- WHERE table_name = 'user'
--   AND changed_fields ? 'email'
-- ORDER BY timestamp DESC;

-- Query 5: Find all deletes in the last 24 hours
-- SELECT * FROM audit_log_db
-- WHERE operation = 'DELETE'
--   AND timestamp > NOW() - INTERVAL '24 hours'
-- ORDER BY timestamp DESC;

-- Query 6: Find all operations from a specific IP
-- SELECT * FROM audit_log_db
-- WHERE ip_address = '192.168.1.1'
-- ORDER BY timestamp DESC;

-- Query 7: Find all operations in a specific correlation ID (request trace)
-- SELECT * FROM audit_log_db
-- WHERE correlation_id = '550e8400-e29b-41d4-a716-446655440000'
-- ORDER BY timestamp ASC;

-- Query 8: Find all critical changes (multiple deletes)
-- SELECT app_user_id, app_username, COUNT(*) as delete_count
-- FROM audit_log_db
-- WHERE operation = 'DELETE'
--   AND timestamp > NOW() - INTERVAL '1 hour'
-- GROUP BY app_user_id, app_username
-- HAVING COUNT(*) > 5
-- ORDER BY delete_count DESC;

-- Query 9: Audit history for specific table
-- SELECT
--     timestamp,
--     operation,
--     app_username,
--     record_id,
--     CASE
--         WHEN operation = 'INSERT' THEN new_values
--         WHEN operation = 'UPDATE' THEN changed_fields
--         WHEN operation = 'DELETE' THEN old_values
--     END as details
-- FROM audit_log_db
-- WHERE table_name = 'game'
-- ORDER BY timestamp DESC
-- LIMIT 100;

-- Query 10: Database wipe detection
-- SELECT
--     timestamp,
--     app_user_id,
--     app_username,
--     table_name,
--     COUNT(*) as records_deleted
-- FROM audit_log_db
-- WHERE operation = 'DELETE'
--   AND timestamp > NOW() - INTERVAL '5 minutes'
-- GROUP BY timestamp, app_user_id, app_username, table_name
-- HAVING COUNT(*) > 10
-- ORDER BY records_deleted DESC;

-- ============================================================================
-- RETENTION POLICY (OPTIONAL)
-- ============================================================================

-- Create function to clean old audit logs
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs(retention_days INTEGER DEFAULT 365)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM audit_log_db
    WHERE timestamp < NOW() - (retention_days || ' days')::INTERVAL;

    GET DIAGNOSTICS deleted_count = ROW_COUNT;

    RAISE NOTICE 'Deleted % old audit log records', deleted_count;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_audit_logs(INTEGER) IS 'Delete audit logs older than specified days (default: 365)';

-- Schedule cleanup (run weekly via cron or pg_cron extension)
-- SELECT cleanup_old_audit_logs(365);

-- ============================================================================
-- PGAUDIT EXTENSION (OPTIONAL - ADVANCED)
-- ============================================================================

-- For even more comprehensive auditing, enable pgaudit extension
-- This requires PostgreSQL superuser and extension installation

-- CREATE EXTENSION IF NOT EXISTS pgaudit;

-- -- Configure pgaudit
-- ALTER SYSTEM SET pgaudit.log = 'write, ddl';
-- ALTER SYSTEM SET pgaudit.log_catalog = off;
-- ALTER SYSTEM SET pgaudit.log_client = on;
-- ALTER SYSTEM SET pgaudit.log_level = 'log';
-- ALTER SYSTEM SET pgaudit.log_parameter = on;
-- ALTER SYSTEM SET pgaudit.log_relation = on;
-- ALTER SYSTEM SET pgaudit.log_statement_once = off;

-- -- Reload configuration
-- SELECT pg_reload_conf();

-- -- Verify pgaudit is working
-- SHOW pgaudit.log;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify audit table exists
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE tablename = 'audit_log_db';

-- Verify triggers are created
SELECT
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers
WHERE trigger_name LIKE 'audit_trigger%'
ORDER BY event_object_table, event_manipulation;

-- Test audit trigger
-- INSERT INTO game (name, description) VALUES ('Test Game', 'Test Description');
-- SELECT * FROM audit_log_db ORDER BY timestamp DESC LIMIT 5;

-- ============================================================================
-- DEPLOYMENT COMPLETE
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '========================================================================';
    RAISE NOTICE 'PostgreSQL Audit Triggers - Deployment Complete!';
    RAISE NOTICE '========================================================================';
    RAISE NOTICE 'Audit table created: audit_log_db';
    RAISE NOTICE 'Triggers enabled for 16 tables';
    RAISE NOTICE 'Indexes created for fast forensic queries';
    RAISE NOTICE 'Helper functions available: enable_audit_for_table(), disable_audit_for_table()';
    RAISE NOTICE '========================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'FORENSIC QUERIES READY:';
    RAISE NOTICE '- Find who deleted record: WHERE operation=DELETE AND record_id=X';
    RAISE NOTICE '- Find all user actions: WHERE app_user_id=X';
    RAISE NOTICE '- Trace request: WHERE correlation_id=X';
    RAISE NOTICE '- Detect mass deletes: GROUP BY table_name, app_user_id HAVING COUNT(*)>10';
    RAISE NOTICE '========================================================================';
END $$;
