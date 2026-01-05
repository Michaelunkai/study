#!/usr/bin/env python3
"""Deploy enhanced dashboard to production server"""
import paramiko
import os

SERVER = '193.181.213.220'
USER = 'admin'
PASSWORD = 'EbTyNkfJG6LM'
REMOTE_PATH = '/opt/tovplay-logging-dashboard'

# Files to deploy
LOCAL_FILES = {
    'F:/tovplay/.claude/infra/app_enhanced.py': f'{REMOTE_PATH}/app.py',
    'F:/tovplay/.claude/infra/dashboard_enhanced.html': f'{REMOTE_PATH}/templates/dashboard_enhanced.html',
}

def deploy():
    print(f"Connecting to {SERVER}...")
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USER, password=PASSWORD, timeout=30)

    sftp = ssh.open_sftp()

    # Backup existing app.py
    print("Backing up existing app.py...")
    stdin, stdout, stderr = ssh.exec_command(f'sudo cp {REMOTE_PATH}/app.py {REMOTE_PATH}/app.py.bak-v1')
    stdout.read()

    # Upload files
    for local_path, remote_path in LOCAL_FILES.items():
        print(f"Uploading {os.path.basename(local_path)} -> {remote_path}")
        try:
            sftp.put(local_path.replace('/', os.sep) if os.name == 'nt' else local_path, f'/tmp/{os.path.basename(remote_path)}')
            # Move with sudo
            stdin, stdout, stderr = ssh.exec_command(f'sudo mv /tmp/{os.path.basename(remote_path)} {remote_path}')
            stdout.read()
            print(f"  OK")
        except Exception as e:
            print(f"  ERROR: {e}")

    sftp.close()

    # Restart container
    print("\nRestarting dashboard container...")
    stdin, stdout, stderr = ssh.exec_command('sudo docker restart tovplay-logging-dashboard')
    print(stdout.read().decode())
    print(stderr.read().decode())

    # Check status
    print("\nChecking container status...")
    stdin, stdout, stderr = ssh.exec_command('sudo docker ps | grep logging-dashboard')
    print(stdout.read().decode())

    # Test health endpoint
    print("\nTesting health endpoint...")
    stdin, stdout, stderr = ssh.exec_command('curl -s http://localhost:7778/api/health')
    print(stdout.read().decode())

    ssh.close()
    print("\nDeployment complete!")

if __name__ == '__main__':
    deploy()
