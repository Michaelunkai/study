#!/usr/bin/env python3
"""
TovPlay Unified Logging Dashboard - Enhanced with Team Member Attribution
Real-time documentation of all code, infrastructure, repo, and server changes
"""

from flask import Flask, render_template, jsonify, request
from flask_cors import CORS
from datetime import datetime, timedelta
import requests
import json
import os
import logging
from functools import wraps
import hashlib
import hmac
import re

app = Flask(__name__)
CORS(app)

# Configuration
LOKI_URL = os.getenv('LOKI_URL', 'http://tovplay-loki:3100')
GITHUB_WEBHOOK_SECRET = os.getenv('GITHUB_WEBHOOK_SECRET', 'tovplay-webhook-secret-2024')
LOG_FILE = '/var/log/tovplay/github-webhooks.log'

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Team member mapping (from CLAUDE.md)
TEAM_MEMBERS = {
    # GitHub usernames
    'romanfesu': {'name': 'Roman Fesunenko', 'role': 'DevOps', 'color': '#58a6ff'},
    'lilachHerzog': {'name': 'Lilach Herzog', 'role': 'Frontend', 'color': '#a371f7'},
    'sharon': {'name': 'Sharon Keinar', 'role': 'Backend', 'color': '#3fb950'},
    'yuval': {'name': 'Yuval Zeyger', 'role': 'Contributor', 'color': '#d29922'},
    'michael': {'name': 'Michael Fedorovsky', 'role': 'Contributor', 'color': '#f85149'},
    'avi': {'name': 'Avi Wasserman', 'role': 'Contributor', 'color': '#ff7b72'},
    'itamar': {'name': 'Itamar Bar', 'role': 'Contributor', 'color': '#79c0ff'},

    # Database/email usernames (lowercase matching)
    'raz@tovtech.org': {'name': 'Roman Fesunenko', 'role': 'DevOps', 'color': '#58a6ff'},
    'lilach': {'name': 'Lilach Herzog', 'role': 'Frontend', 'color': '#a371f7'},
    'herzog': {'name': 'Lilach Herzog', 'role': 'Frontend', 'color': '#a371f7'},
    'roman': {'name': 'Roman Fesunenko', 'role': 'DevOps', 'color': '#58a6ff'},
}

def identify_team_member(text):
    """Identify team member from log text"""
    if not text:
        return None

    text_lower = text.lower()

    # Check for exact username matches
    for username, info in TEAM_MEMBERS.items():
        if username.lower() in text_lower:
            return info

    # Check for name mentions in logs
    for username, info in TEAM_MEMBERS.items():
        name_lower = info['name'].lower()
        if name_lower in text_lower:
            return info

    return None

def query_loki(query, start=None, end=None, limit=1000):
    """Query Loki for logs with flexible time ranges"""
    if not start:
        start = (datetime.utcnow() - timedelta(hours=24)).isoformat() + 'Z'
    if not end:
        end = datetime.utcnow().isoformat() + 'Z'

    params = {
        'query': query,
        'start': start,
        'end': end,
        'limit': limit
    }

    try:
        response = requests.get(f'{LOKI_URL}/loki/api/v1/query_range', params=params, timeout=10)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        logger.error(f"Loki query failed: {e}")
        return {'status': 'error', 'error': str(e)}

def verify_github_signature(payload, signature):
    """Verify GitHub webhook signature"""
    if not signature:
        return False
    expected = 'sha256=' + hmac.new(
        GITHUB_WEBHOOK_SECRET.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)

def log_to_file(log_file, data):
    """Append log entry to file for Promtail to pick up"""
    os.makedirs(os.path.dirname(log_file), exist_ok=True)
    with open(log_file, 'a') as f:
        f.write(json.dumps({
            'timestamp': datetime.utcnow().isoformat(),
            **data
        }) + '\n')

# ===========================================
# GITHUB WEBHOOK ENDPOINTS
# ===========================================

@app.route('/webhook/github', methods=['POST'])
def github_webhook():
    """Receive and log GitHub webhook events"""
    signature = request.headers.get('X-Hub-Signature-256')
    event_type = request.headers.get('X-GitHub-Event', 'unknown')

    # Verify signature in production
    if os.getenv('VERIFY_WEBHOOK', 'false').lower() == 'true':
        if not verify_github_signature(request.data, signature):
            return jsonify({'error': 'Invalid signature'}), 403

    payload = request.json

    # Parse event details
    log_entry = {
        'event_type': event_type,
        'repository': payload.get('repository', {}).get('full_name', 'unknown'),
        'sender': payload.get('sender', {}).get('login', 'unknown'),
    }

    if event_type == 'push':
        log_entry.update({
            'action': 'push',
            'branch': payload.get('ref', '').replace('refs/heads/', ''),
            'commits': len(payload.get('commits', [])),
            'commit_messages': [c.get('message', '')[:100] for c in payload.get('commits', [])[:5]],
            'pusher': payload.get('pusher', {}).get('name', 'unknown'),
        })
    elif event_type == 'pull_request':
        pr = payload.get('pull_request', {})
        log_entry.update({
            'action': payload.get('action'),
            'pr_number': pr.get('number'),
            'pr_title': pr.get('title', '')[:100],
            'pr_author': pr.get('user', {}).get('login', 'unknown'),
            'pr_state': pr.get('state'),
            'base_branch': pr.get('base', {}).get('ref'),
            'head_branch': pr.get('head', {}).get('ref'),
        })
    elif event_type == 'workflow_run':
        workflow = payload.get('workflow_run', {})
        log_entry.update({
            'action': payload.get('action'),
            'workflow_name': workflow.get('name'),
            'workflow_status': workflow.get('status'),
            'workflow_conclusion': workflow.get('conclusion'),
            'branch': workflow.get('head_branch'),
            'run_number': workflow.get('run_number'),
        })
    elif event_type == 'deployment':
        deployment = payload.get('deployment', {})
        log_entry.update({
            'action': payload.get('action'),
            'environment': deployment.get('environment'),
            'description': deployment.get('description', '')[:100],
            'creator': deployment.get('creator', {}).get('login', 'unknown'),
        })
    elif event_type == 'deployment_status':
        status = payload.get('deployment_status', {})
        log_entry.update({
            'action': 'deployment_status',
            'state': status.get('state'),
            'environment': status.get('environment'),
            'description': status.get('description', '')[:100],
        })
    elif event_type == 'issues':
        issue = payload.get('issue', {})
        log_entry.update({
            'action': payload.get('action'),
            'issue_number': issue.get('number'),
            'issue_title': issue.get('title', '')[:100],
            'issue_author': issue.get('user', {}).get('login', 'unknown'),
        })
    elif event_type == 'create':
        log_entry.update({
            'action': 'create',
            'ref_type': payload.get('ref_type'),
            'ref': payload.get('ref'),
        })
    elif event_type == 'delete':
        log_entry.update({
            'action': 'delete',
            'ref_type': payload.get('ref_type'),
            'ref': payload.get('ref'),
        })

    # Log to file for Promtail
    log_to_file(LOG_FILE, log_entry)
    logger.info(f"GitHub webhook: {event_type} - {log_entry}")

    return jsonify({'status': 'ok', 'event': event_type})

# ===========================================
# API ENDPOINTS FOR DASHBOARD
# ===========================================

@app.route('/api/logs/recent')
def get_recent_logs():
    """Get recent logs from all sources with time filtering"""
    # Parse time range
    time_range = request.args.get('time_range', '24h')
    limit = request.args.get('limit', 500, type=int)

    # Calculate start time based on time_range
    now = datetime.utcnow()
    if time_range == '1m':
        start = now - timedelta(minutes=1)
    elif time_range == '5m':
        start = now - timedelta(minutes=5)
    elif time_range == '30m':
        start = now - timedelta(minutes=30)
    elif time_range == '1h':
        start = now - timedelta(hours=1)
    elif time_range == '24h':
        start = now - timedelta(hours=24)
    elif time_range == '7d':
        start = now - timedelta(days=7)
    else:
        start = now - timedelta(hours=24)  # default

    start_iso = start.isoformat() + 'Z'
    end_iso = now.isoformat() + 'Z'

    queries = {
        'docker': '{job=~"docker.*"}',
        'nginx': '{job="nginx"}',
        'auth': '{job="auth"}',
        'github': '{job="github"}',
        'cicd': '{job="cicd"}',
        'database': '{job="database"}',
        'errors': '{job=~".+"} |~ "(?i)error|fail|critical"',
        'api': '{job="api"}',
        'git': '{job="git"}',
    }

    results = {}
    for name, query in queries.items():
        data = query_loki(query, start=start_iso, end=end_iso, limit=limit)
        if data.get('status') == 'success':
            # Enrich with team member attribution
            enriched_results = []
            for result in data.get('data', {}).get('result', []):
                values_with_members = []
                for timestamp, message in result.get('values', []):
                    team_member = identify_team_member(message)
                    values_with_members.append({
                        'timestamp': timestamp,
                        'message': message,
                        'team_member': team_member
                    })
                result['values_enriched'] = values_with_members
                enriched_results.append(result)
            results[name] = enriched_results
        else:
            results[name] = []

    return jsonify(results)

@app.route('/api/logs/errors')
def get_errors():
    """Get all error logs"""
    time_range = request.args.get('time_range', '24h')
    query = '{job=~".+"} |~ "(?i)error|exception|fail|critical|fatal"'

    # Parse time range
    now = datetime.utcnow()
    if time_range == '1m':
        start = now - timedelta(minutes=1)
    elif time_range == '5m':
        start = now - timedelta(minutes=5)
    elif time_range == '30m':
        start = now - timedelta(minutes=30)
    elif time_range == '1h':
        start = now - timedelta(hours=1)
    elif time_range == '24h':
        start = now - timedelta(hours=24)
    elif time_range == '7d':
        start = now - timedelta(days=7)
    else:
        start = now - timedelta(hours=24)

    data = query_loki(query, start=start.isoformat() + 'Z', limit=1000)
    return jsonify(data)

@app.route('/api/logs/github')
def get_github_logs():
    """Get GitHub activity logs"""
    time_range = request.args.get('time_range', '24h')
    query = '{job="github"}'

    now = datetime.utcnow()
    if time_range == '24h':
        start = now - timedelta(hours=24)
    elif time_range == '7d':
        start = now - timedelta(days=7)
    else:
        start = now - timedelta(hours=24)

    data = query_loki(query, start=start.isoformat() + 'Z', limit=500)
    return jsonify(data)

@app.route('/api/logs/deployments')
def get_deployments():
    """Get deployment logs"""
    query = '{job="cicd"}'
    data = query_loki(query, limit=200)
    return jsonify(data)

@app.route('/api/logs/auth')
def get_auth_logs():
    """Get authentication/security logs"""
    query = '{job="auth"}'
    data = query_loki(query, limit=500)
    return jsonify(data)

@app.route('/api/logs/database')
def get_database_logs():
    """Get database activity logs with team member attribution"""
    time_range = request.args.get('time_range', '24h')
    query = '{job="database"}'

    now = datetime.utcnow()
    if time_range == '1m':
        start = now - timedelta(minutes=1)
    elif time_range == '5m':
        start = now - timedelta(minutes=5)
    elif time_range == '30m':
        start = now - timedelta(minutes=30)
    elif time_range == '1h':
        start = now - timedelta(hours=1)
    elif time_range == '24h':
        start = now - timedelta(hours=24)
    elif time_range == '7d':
        start = now - timedelta(days=7)
    else:
        start = now - timedelta(hours=24)

    data = query_loki(query, start=start.isoformat() + 'Z', limit=500)
    return jsonify(data)

@app.route('/api/logs/search')
def search_logs():
    """Search all logs"""
    search_term = request.args.get('q', '')
    if not search_term:
        return jsonify({'error': 'Missing search term'}), 400

    query = f'{{job=~".+"}} |~ "(?i){search_term}"'
    data = query_loki(query, limit=1000)
    return jsonify(data)

@app.route('/api/stats')
def get_stats():
    """Get log statistics"""
    stats = {
        'total_errors_24h': 0,
        'total_requests_24h': 0,
        'github_events_24h': 0,
        'deployments_24h': 0,
        'auth_events_24h': 0,
    }

    # Count errors
    error_data = query_loki('{job=~".+"} |~ "(?i)error"', limit=10000)
    if error_data.get('status') == 'success':
        for result in error_data.get('data', {}).get('result', []):
            stats['total_errors_24h'] += len(result.get('values', []))

    # Count nginx requests
    nginx_data = query_loki('{job="nginx",type="access"}', limit=10000)
    if nginx_data.get('status') == 'success':
        for result in nginx_data.get('data', {}).get('result', []):
            stats['total_requests_24h'] += len(result.get('values', []))

    return jsonify(stats)

@app.route('/api/team-members')
def get_team_members():
    """Get list of team members"""
    return jsonify(TEAM_MEMBERS)

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    loki_health = False
    try:
        r = requests.get(f'{LOKI_URL}/ready', timeout=5)
        loki_health = r.status_code == 200
    except:
        pass

    return jsonify({
        'status': 'healthy',
        'loki_connected': loki_health,
        'timestamp': datetime.utcnow().isoformat()
    })

# ===========================================
# WEB INTERFACE
# ===========================================

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7778, debug=False)
