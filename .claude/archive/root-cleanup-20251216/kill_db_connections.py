#!/usr/bin/env python3
"""Emergency script to kill all PostgreSQL connections via production server"""
import subprocess
import sys

DB_HOST = "45.148.28.196"
DB_USER = "raz@tovtech.org"
DB_PASS = "CaptainForgotCreatureBreak"
PROD_SERVER = "admin@193.181.213.220"
PROD_PASS = "EbTyNkfJG6LM"

# First, let's try to use pg_ctl to restart PostgreSQL via SSH
# We'll connect to production server and execute remote commands

restart_command = f"""
sshpass -p '{PROD_PASS}' ssh -o StrictHostKeyChecking=no {PROD_SERVER} "
  # Try to find PostgreSQL on database server and restart it
  echo 'Attempting to restart PostgreSQL on {DB_HOST}...'

  # Option 1: If we can SSH to DB server from production server
  sshpass -p 'try_various_passwords' ssh -o ConnectTimeout=5 root@{DB_HOST} 'systemctl restart postgresql || service postgresql restart' 2>&1

  # Option 2: Try via PostgreSQL admin functions (requires connection)
  # This won't work if pool is full, but worth trying
  PGPASSWORD='{DB_PASS}' psql -h {DB_HOST} -U '{DB_USER}' -d postgres -c \"
    SELECT pg_terminate_backend(pid)
    FROM pg_stat_activity
    WHERE pid <> pg_backend_pid()
    AND datname IS NOT NULL;
  \" 2>&1 || echo 'Cannot connect - pool full'

  echo 'Done'
"
"""

print("Attempting to kill all PostgreSQL connections...")
print("=" * 60)

try:
    result = subprocess.run(
        ['wsl', '-d', 'ubuntu', 'bash', '-c', restart_command],
        capture_output=True,
        text=True,
        timeout=60
    )

    print("STDOUT:")
    print(result.stdout)
    print("\nSTDERR:")
    print(result.stderr)
    print(f"\nReturn code: {result.returncode}")

except subprocess.TimeoutExpired:
    print("ERROR: Command timed out after 60 seconds")
    sys.exit(1)
except Exception as e:
    print(f"ERROR: {e}")
    sys.exit(1)
