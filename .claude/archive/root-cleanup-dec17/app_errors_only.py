#!/usr/bin/env python3
"""
TovPlay Error-Only Logging Dashboard with Team Attribution & Severity Levels
Shows ONLY errors with team member identification and severity scoring (1-5)
"""

from flask import Flask, render_template, jsonify, request
from flask_cors import CORS
from datetime import datetime, timedelta
import requests
import json
import os
import logging
import re

app = Flask(__name__)
CORS(app)

# Configuration
LOKI_URL = os.getenv('LOKI_URL', 'http://loki:3100')
LOG_FILE = '/var/log/tovplay/github-webhooks.log'

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Team member mapping with roles
TEAM_MEMBERS = {
    # GitHub usernames
    'romanfesu': {'name': 'Roman Fesunenko', 'role': 'DevOps', 'color': '#58a6ff'},
    'lilachHerzog': {'name': 'Lilach Herzog', 'role': 'Frontend', 'color': '#a371f7'},
    'sharon': {'name': 'Sharon Keinar', 'role': 'Backend', 'color': '#3fb950'},
    'yuval': {'name': 'Yuval Zeyger', 'role': 'Contributor', 'color': '#d29922'},
    'michael': {'name': 'Michael Fedorovsky', 'role': 'Contributor', 'color': '#f85149'},
    'avi': {'name': 'Avi Wasserman', 'role': 'Contributor', 'color': '#ff7b72'},
    'itamar': {'name': 'Itamar Bar', 'role': 'Contributor', 'color': '#79c0ff'},

    # Database/email usernames
    'raz@tovtech.org': {'name': 'Roman Fesunenko', 'role': 'DevOps', 'color': '#58a6ff'},
    'lilach': {'name': 'Lilach Herzog', 'role': 'Frontend', 'color': '#a371f7'},
    'herzog': {'name': 'Lilach Herzog', 'role': 'Frontend', 'color': '#a371f7'},
    'roman': {'name': 'Roman Fesunenko', 'role': 'DevOps', 'color': '#58a6ff'},
}

# Severity rules: 1 (blue) to 5 (red) - IMMEDIATE FIX NEEDED
SEVERITY_RULES = [
    # Level 5 - IMMEDIATE FIX (RED)
    {'pattern': r'(?i)(CRITICAL|FATAL|database.*crash|data.*loss|truncate|drop table|security.*breach)', 'level': 5, 'label': 'CRITICAL - FIX NOW'},

    # Level 4 - URGENT (ORANGE)
    {'pattern': r'(?i)(500.*error|connection.*refused|out of memory|disk.*full|authentication.*fail)', 'level': 4, 'label': 'URGENT'},

    # Level 3 - HIGH PRIORITY (YELLOW)
    {'pattern': r'(?i)(error|exception|failed|timeout|not found|unable to)', 'level': 3, 'label': 'HIGH PRIORITY'},

    # Level 2 - MEDIUM (LIGHT BLUE)
    {'pattern': r'(?i)(warning|deprecated|slow.*query)', 'level': 2, 'label': 'MEDIUM'},

    # Level 1 - LOW (BLUE) - default for any error
    {'pattern': r'.*', 'level': 1, 'label': 'LOW'}
]

def identify_team_member(text):
    """Identify team member from log text"""
    if not text:
        return None

    text_lower = text.lower()

    # Check for exact username matches
    for username, info in TEAM_MEMBERS.items():
        if username.lower() in text_lower:
            return info

    # Check for name mentions
    for username, info in TEAM_MEMBERS.items():
        name_lower = info['name'].lower()
        if name_lower in text_lower:
            return info

    return None

def calculate_severity(message):
    """Calculate error severity (1-5) based on message content"""
    message_lower = message.lower() if message else ''

    for rule in SEVERITY_RULES:
        if re.search(rule['pattern'], message_lower):
            return {
                'level': rule['level'],
                'label': rule['label'],
                'color': get_severity_color(rule['level'])
            }

    return {'level': 1, 'label': 'LOW', 'color': '#58a6ff'}

def get_severity_color(level):
    """Get color for severity level"""
    colors = {
        5: '#dc3545',  # Red - IMMEDIATE
        4: '#fd7e14',  # Orange - URGENT
        3: '#ffc107',  # Yellow - HIGH
        2: '#17a2b8',  # Light Blue - MEDIUM
        1: '#58a6ff'   # Blue - LOW
    }
    return colors.get(level, '#58a6ff')

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
        response = requests.get(f'{LOKI_URL}/loki/api/v1/query_range', params=params, timeout=5)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        logger.error(f"Loki query failed: {e}")
        return {'status': 'error', 'error': str(e)}

# ===========================================
# API ENDPOINTS
# ===========================================

@app.route('/api/errors')
def get_errors():
    """Get ONLY error logs with team attribution and severity"""
    time_range = request.args.get('time_range', '5m')
    limit = request.args.get('limit', 500, type=int)

    # Calculate start time
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
        start = now - timedelta(minutes=5)

    start_iso = start.isoformat() + 'Z'
    end_iso = now.isoformat() + 'Z'

    # Query for errors only
    error_query = '{job=~".+"} |~ "(?i)error|exception|fail|critical|fatal"'

    data = query_loki(error_query, start=start_iso, end=end_iso, limit=limit)

    if data.get('status') != 'success':
        return jsonify({'errors': [], 'error': data.get('error', 'Unknown error')})

    # Process and enrich errors
    enriched_errors = []
    for result in data.get('data', {}).get('result', []):
        for timestamp, message in result.get('values', []):
            team_member = identify_team_member(message)
            severity = calculate_severity(message)

            enriched_errors.append({
                'timestamp': timestamp,
                'message': message,
                'team_member': team_member,
                'severity': severity,
                'job': result.get('stream', {}).get('job', 'unknown')
            })

    # Sort by timestamp (newest first) and severity (highest first)
    enriched_errors.sort(key=lambda x: (x['timestamp'], -x['severity']['level']), reverse=True)

    return jsonify({
        'errors': enriched_errors,
        'total': len(enriched_errors),
        'time_range': time_range
    })

@app.route('/api/team-members')
def get_team_members():
    """Get list of team members"""
    return jsonify(TEAM_MEMBERS)

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    loki_health = False
    try:
        r = requests.get(f'{LOKI_URL}/ready', timeout=2)
        loki_health = r.status_code == 200
    except:
        pass

    return jsonify({
        'status': 'healthy',
        'loki_connected': loki_health,
        'timestamp': datetime.utcnow().isoformat()
    })

@app.route('/api/stats')
def get_stats():
    """Get error statistics by severity"""
    time_range = request.args.get('time_range', '24h')

    # Get errors
    error_data = get_errors().json
    errors = error_data.get('errors', [])

    # Count by severity
    severity_counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0}
    team_error_counts = {}

    for error in errors:
        severity_counts[error['severity']['level']] += 1

        if error.get('team_member'):
            name = error['team_member']['name']
            team_error_counts[name] = team_error_counts.get(name, 0) + 1

    return jsonify({
        'total_errors': len(errors),
        'by_severity': severity_counts,
        'by_team_member': team_error_counts,
        'time_range': time_range
    })

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('errors_dashboard.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7778, debug=False)
