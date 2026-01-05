#!/usr/bin/env python3
import paramiko
import os

# Server details
host = "193.181.213.220"
username = "admin"
password = "EbTyNkfJG6LM"

# Files to upload
files = [
    ("F:/tovplay/.claude/infra/app_errors_only.py", "/opt/tovplay-logging-dashboard/app.py"),
    ("F:/tovplay/.claude/infra/errors_dashboard.html", "/opt/tovplay-logging-dashboard/templates/errors_dashboard.html")
]

try:
    # Connect via SSH
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(host, username=username, password=password)

    # Upload files via SFTP
    sftp = ssh.open_sftp()

    for local_path, remote_path in files:
        print(f"Uploading {local_path} -> {remote_path}")

        # Create temp file
        temp_path = f"/tmp/{os.path.basename(remote_path)}"
        sftp.put(local_path, temp_path)

        # Move to final location with sudo
        stdin, stdout, stderr = ssh.exec_command(f"sudo mv {temp_path} {remote_path} && sudo chown admin:admin {remote_path}")
        stdout.channel.recv_exit_status()

        print(f"[OK] Uploaded {local_path}")

    sftp.close()
    ssh.close()
    print("\n[OK] All files uploaded successfully!")

except Exception as e:
    print(f"[ERROR] Error: {e}")
    exit(1)
