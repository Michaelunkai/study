#!/usr/bin/env python3
import psycopg2

conn = psycopg2.connect(
    host='45.148.28.196',
    user='raz@tovtech.org',
    password='CaptainForgotCreatureBreak',
    database='postgres'
)
cur = conn.cursor()

# Create function to block DROP DATABASE
sql = """CREATE OR REPLACE FUNCTION prevent_drop_database()
RETURNS event_trigger AS $func$
DECLARE
    obj record;
BEGIN
    FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
        IF obj.object_type = 'database' THEN
            RAISE EXCEPTION 'CRITICAL SECURITY: DROP DATABASE BLOCKED - Contact Michael Fedorovsky';
        END IF;
    END LOOP;
END;
$func$ LANGUAGE plpgsql;"""

try:
    cur.execute(sql)
    print("[✓] Function created")
except Exception as e:
    print(f"[✗] Function error: {e}")

try:
    cur.execute('DROP EVENT TRIGGER IF EXISTS block_drop_database CASCADE')
    print("[✓] Old trigger dropped")
except Exception as e:
    print(f"[✗] Drop trigger error: {e}")

try:
    cur.execute('CREATE EVENT TRIGGER block_drop_database ON sql_drop EXECUTE FUNCTION prevent_drop_database()')
    print("[✓] Event trigger created")
except Exception as e:
    print(f"[✗] Create trigger error: {e}")

try:
    cur.execute('ALTER EVENT TRIGGER block_drop_database ENABLE')
    print("[✓] Event trigger enabled")
except Exception as e:
    print(f"[✗] Enable trigger error: {e}")

try:
    cur.execute("SELECT evtname, evtenabled FROM pg_event_trigger WHERE evtname = 'block_drop_database'")
    result = cur.fetchall()
    print(f"[✓] Trigger status: {result}")
except Exception as e:
    print(f"[✗] Check trigger error: {e}")

conn.commit()
conn.close()
print("\n[SUCCESS] DROP DATABASE protection installed")
