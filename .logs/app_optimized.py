#!/usr/bin/env python3
"""
TovPlay Error-Only Dashboard with Team Attribution & Severity Levels
Deployed: December 17, 2025
Server: 193.181.213.220:7778
Access: https://app.tovplay.org/logs/

CRITICAL: Shows ONLY error logs with team attribution and severity (1-5)
Special emphasis on database errors with comprehensive detection
"""

import os
from flask import Flask, render_template, jsonify, request
import requests
from datetime import datetime, timedelta
import re
from collections import defaultdict

app = Flask(__name__)

# Loki configuration (use Docker service name for inter-container communication)
LOKI_URL = os.environ.get('LOKI_URL', 'http://loki:3100')

# Team member identification with expanded patterns
TEAM_MEMBERS = {
    'romanfesu': {'name': 'Roman Fesunenko', 'role': 'DevOps', 'color': '#58a6ff'},
    'roman': {'name': 'Roman Fesunenko', 'role': 'DevOps', 'color': '#58a6ff'},
    'lilachHerzog': {'name': 'Lilach Herzog', 'role': 'Frontend', 'color': '#a371f7'},
    'lilach': {'name': 'Lilach Herzog', 'role': 'Frontend', 'color': '#a371f7'},
    'sharon': {'name': 'Sharon Keinar', 'role': 'Backend', 'color': '#3fb950'},
    'sharonkeinar': {'name': 'Sharon Keinar', 'role': 'Backend', 'color': '#3fb950'},
    'michael': {'name': 'Michael Fedorovsky', 'role': 'Backend', 'color': '#d29922'},
    'michaelfedorovsky': {'name': 'Michael Fedorovsky', 'role': 'Backend', 'color': '#d29922'},
    'yuval': {'name': 'Yuval Zeyger', 'role': 'Backend', 'color': '#f85149'},
    'yuvalzeyger': {'name': 'Yuval Zeyger', 'role': 'Backend', 'color': '#f85149'},
    'avi': {'name': 'Avi Wasserman', 'role': 'Backend', 'color': '#8957e5'},
    'aviwasserman': {'name': 'Avi Wasserman', 'role': 'Backend', 'color': '#8957e5'},
    'itamar': {'name': 'Itamar Bar', 'role': 'Backend', 'color': '#1f6feb'},
    'itamarbar': {'name': 'Itamar Bar', 'role': 'Backend', 'color': '#1f6feb'},
    'admin': {'name': 'System Admin', 'role': 'DevOps', 'color': '#6e7681'},
    'root': {'name': 'Root User', 'role': 'DevOps', 'color': '#6e7681'},
}

# ENHANCED DATABASE ERROR PATTERNS - Special emphasis on DB issues
SEVERITY_RULES = [
    {
        'pattern': r'(?i)(CRITICAL|FATAL|database.*crash|database.*corrupt|data.*loss|truncate.*table|drop.*table|delete.*from.*where|security.*breach|sql.*injection|unauthorized.*access|permission.*denied.*database|deadlock.*detected|transaction.*rollback.*failed|replication.*lag.*critical|disk.*full.*database|backup.*failed|restore.*failed|connection.*pool.*exhausted)',
        'level': 5,
        'label': 'CRITICAL - FIX NOW',
        'color': '#ff0000'
    },
    {
        'pattern': r'(?i)(500.*error|internal.*server.*error|connection.*refused|database.*connection.*failed|out of memory|disk.*full|authentication.*fail|ssl.*error|certificate.*error|timeout.*database|query.*timeout|lock.*timeout|too.*many.*connections|max.*connections.*reached|connection.*leak|pool.*timeout|unable.*to.*connect.*database|postgres.*error|psycopg2.*error|sqlalchemy.*error|migration.*failed|alembic.*error)',
        'level': 4,
        'label': 'URGENT',
        'color': '#ff6b00'
    },
    {
        'pattern': r'(?i)(error|exception|failed|failure|unable to|cannot|timeout|not found|404|403|401|connection.*error|network.*error|database.*error|query.*error|constraint.*violation|foreign.*key.*violation|unique.*constraint|null.*constraint|integrity.*error|operational.*error|programming.*error|data.*error|database.*locked|table.*not.*found|column.*not.*found|syntax.*error.*sql|invalid.*query)',
        'level': 3,
        'label': 'HIGH PRIORITY',
        'color': '#ffcc00'
    },
    {
        'pattern': r'(?i)(warning|deprecated|slow.*query|performance.*issue|memory.*warning|disk.*warning|rate.*limit|retry|rollback|conflict|stale.*data)',
        'level': 2,
        'label': 'MEDIUM',
        'color': '#66ccff'
    },
    {
        'pattern': r'.*',
        'level': 1,
        'label': 'LOW',
        'color': '#0066ff'
    }
]

def identify_team_member(log_text):
    """Identify team member from log text"""
    log_lower = log_text.lower()
    for username, info in TEAM_MEMBERS.items():
        if username in log_lower:
            return info
    return None

def calculate_severity(log_text):
    """Calculate severity level (1-5) based on log content"""
    for rule in SEVERITY_RULES:
        if re.search(rule['pattern'], log_text):
            return {
                'level': rule['level'],
                'label': rule['label'],
                'color': rule['color']
            }
    return {'level': 1, 'label': 'LOW', 'color': '#0066ff'}

def query_loki(query, start=None, end=None, limit=1000):
    """Query Loki with OPTIMIZED ERROR-ONLY filter"""
    try:
        # OPTIMIZED: ERROR-ONLY FILTER - Simplified to reduce Loki query load
        # Removed complex wildcards (.*) that caused HTTP 429 rate limiting
        # Original: 15+ alternations with wildcards - New: 9 simple keywords
        # Covers: errors, database issues, connection problems, critical events
        error_query = '{job=~".+"} |~ "(?i)(error|exception|critical|fatal|500|database|psycopg2|sqlalchemy|timeout|refused)"'

        if not end:
            end = datetime.now()
        if not start:
            start = end - timedelta(hours=1)

        params = {
            'query': error_query,
            'start': int(start.timestamp() * 1e9),
            'end': int(end.timestamp() * 1e9),
            'limit': limit,
            'direction': 'backward'
        }

        response = requests.get(
            f"{LOKI_URL}/loki/api/v1/query_range",
            params=params,
            timeout=10
        )
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error querying Loki: {e}")
        return {'status': 'error', 'data': {'result': []}}

def enrich_logs(loki_response):
    """Enrich logs with team attribution and severity"""
    enriched = []

    if loki_response.get('status') != 'success':
        return enriched

    results = loki_response.get('data', {}).get('result', [])

    for stream in results:
        labels = stream.get('stream', {})
        values = stream.get('values', [])

        for timestamp_ns, log_line in values:
            # Convert nanosecond timestamp to datetime
            timestamp = datetime.fromtimestamp(int(timestamp_ns) / 1e9)

            # Identify team member
            team_member = identify_team_member(log_line)

            # Calculate severity
            severity = calculate_severity(log_line)

            enriched.append({
                'timestamp': timestamp.isoformat(),
                'log': log_line,
                'labels': labels,
                'team_member': team_member,
                'severity': severity
            })

    return enriched

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('errors_dashboard.html')

@app.route('/api/errors')
def get_errors():
    """Get error logs with team attribution and severity"""
    try:
        # Parse time range from query params
        time_range = request.args.get('range', '1h')
        end = datetime.now()

        time_map = {
            '1m': timedelta(minutes=1),
            '5m': timedelta(minutes=5),
            '30m': timedelta(minutes=30),
            '1h': timedelta(hours=1),
            '24h': timedelta(hours=24),
            '7d': timedelta(days=7)
        }

        start = end - time_map.get(time_range, timedelta(hours=1))

        # Query Loki
        loki_response = query_loki("", start=start, end=end)

        # Enrich logs
        enriched_logs = enrich_logs(loki_response)

        return jsonify({
            'status': 'success',
            'count': len(enriched_logs),
            'errors': enriched_logs
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/api/health')
def health():
    """Health check endpoint"""
    try:
        # Check Loki connectivity
        response = requests.get(f"{LOKI_URL}/ready", timeout=5)
        loki_status = "healthy" if response.status_code == 200 else "unhealthy"
    except:
        loki_status = "unreachable"

    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'loki': loki_status,
        'dashboard': 'error-only-mode'
    })

@app.route('/api/stats')
def get_stats():
    """Get error statistics"""
    try:
        time_range = request.args.get('range', '1h')
        end = datetime.now()

        time_map = {
            '1m': timedelta(minutes=1),
            '5m': timedelta(minutes=5),
            '30m': timedelta(minutes=30),
            '1h': timedelta(hours=1),
            '24h': timedelta(hours=24),
            '7d': timedelta(days=7)
        }

        start = end - time_map.get(time_range, timedelta(hours=1))

        # Query Loki
        loki_response = query_loki("", start=start, end=end)
        enriched_logs = enrich_logs(loki_response)

        # Calculate statistics
        stats = {
            'total_errors': len(enriched_logs),
            'severity_breakdown': defaultdict(int),
            'team_breakdown': defaultdict(int),
            'database_errors': 0,
            'critical_errors': 0
        }

        for log in enriched_logs:
            severity_level = log['severity']['level']
            stats['severity_breakdown'][severity_level] += 1

            if severity_level == 5:
                stats['critical_errors'] += 1

            # Count database-specific errors
            if re.search(r'(?i)database|postgres|psycopg2|sqlalchemy|sql|connection.*pool|query|table|column', log['log']):
                stats['database_errors'] += 1

            if log['team_member']:
                stats['team_breakdown'][log['team_member']['name']] += 1

        return jsonify({
            'status': 'success',
            'stats': {
                'total_errors': stats['total_errors'],
                'critical_errors': stats['critical_errors'],
                'database_errors': stats['database_errors'],
                'severity_breakdown': dict(stats['severity_breakdown']),
                'team_breakdown': dict(stats['team_breakdown'])
            }
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/api/team-members')
def get_team_members():
    """Get team member list"""
    return jsonify({
        'status': 'success',
        'team_members': [
            {'username': k, **v}
            for k, v in TEAM_MEMBERS.items()
        ]
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7778, debug=False)
