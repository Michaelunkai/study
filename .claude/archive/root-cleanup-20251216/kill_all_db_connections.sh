#!/bin/bash
set -e

DB_HOST="45.148.28.196"
DB_USER="raz@tovtech.org"
DB_PASS="CaptainForgotCreatureBreak"

echo "[$(date)] Starting aggressive connection killer..."
echo "Target: $DB_HOST"
echo "=========================================="

# Try every 2 seconds for 5 minutes to get a connection
for i in {1..150}; do
    echo -n "[$i/150] Attempt to connect..."

    # Try to connect and kill all other connections
    if PGPASSWORD="$DB_PASS" timeout 5 psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c "
        SELECT pg_terminate_backend(pid), usename, application_name, state
        FROM pg_stat_activity
        WHERE pid <> pg_backend_pid()
          AND datname IS NOT NULL;
    " 2>&1; then
        echo " SUCCESS! Killed connections."

        # Now show how many are left
        echo ""
        echo "Remaining connections:"
        PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d postgres -c "
            SELECT count(*) as total_connections FROM pg_stat_activity;
        "

        exit 0
    else
        echo " failed (pool full or timeout)"
        sleep 2
    fi
done

echo ""
echo "FAILED: Could not get a connection slot after 150 attempts (5 minutes)"
exit 1
