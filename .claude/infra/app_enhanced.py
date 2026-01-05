#!/usr/bin/env python3
"""
TovPlay ACTIONABLE Error Dashboard - Real Bugs Only
Version: 3.5 - ERRORS ONLY (No access logs, no INFO, no noise)
Date: December 18, 2025
Server: 193.181.213.220:7778
Access: https://app.tovplay.org/logs/

Features:
- ONLY shows errors that NEED debugging (filters out noise)
- Full explanations of what went wrong
- How to fix each error type
- Team member attribution (who caused it)
- Git commit context when available
- 20 DevOps monitoring categories
- Chunked queries for 7d range (avoids 429 rate limiting)
"""

import os
import time
from flask import Flask, render_template, jsonify, request
import requests
from datetime import datetime, timedelta
import re
from collections import defaultdict

app = Flask(__name__)

# Loki configuration
LOKI_URL = os.environ.get('LOKI_URL', 'http://loki:3100')

# =============================================================================
# 20 DEVOPS MONITORING CATEGORIES
# =============================================================================
CATEGORIES = {
    'database': {
        'name': 'Database',
        'icon': '🗄️',
        'color': '#e74c3c',
        'description': 'PostgreSQL, SQLAlchemy, connections, queries',
        'patterns': [
            r'(?i)postgres', r'(?i)psycopg2', r'(?i)sqlalchemy', r'(?i)database',
            r'(?i)connection.*pool', r'(?i)query.*error', r'(?i)sql.*error',
            r'(?i)deadlock', r'(?i)constraint', r'(?i)transaction', r'(?i)rollback',
            r'(?i)migration', r'(?i)alembic', r'(?i)table.*not.*found',
            r'(?i)column.*not.*found', r'(?i)integrity.*error'
        ]
    },
    'nginx': {
        'name': 'Nginx',
        'icon': '🌐',
        'color': '#27ae60',
        'description': 'Reverse proxy, upstream, SSL, config',
        'patterns': [
            r'(?i)nginx', r'(?i)upstream', r'(?i)proxy.*error', r'(?i)502.*bad.*gateway',
            r'(?i)504.*gateway.*timeout', r'(?i)connect.*upstream', r'(?i)ssl.*error',
            r'(?i)certificate.*error', r'(?i)listen.*failed', r'(?i)bind.*failed'
        ]
    },
    'cicd': {
        'name': 'CI/CD',
        'icon': '🔄',
        'color': '#9b59b6',
        'description': 'GitHub Actions, deployments, builds',
        'patterns': [
            r'(?i)github.*action', r'(?i)deployment', r'(?i)deploy.*fail',
            r'(?i)build.*fail', r'(?i)workflow', r'(?i)ci.*fail', r'(?i)cd.*fail',
            r'(?i)docker.*build', r'(?i)release.*fail', r'(?i)rollback.*deploy'
        ]
    },
    'production': {
        'name': 'Production',
        'icon': '🚀',
        'color': '#e91e63',
        'description': 'app.tovplay.org production errors',
        'patterns': [
            r'(?i)production', r'(?i)app\.tovplay\.org', r'(?i)prod.*error',
            r'(?i)live.*error', r'(?i)193\.181\.213\.220'
        ]
    },
    'staging': {
        'name': 'Staging',
        'icon': '🧪',
        'color': '#ff9800',
        'description': 'staging.tovplay.org test environment',
        'patterns': [
            r'(?i)staging', r'(?i)staging\.tovplay\.org', r'(?i)stage.*error',
            r'(?i)test.*environment', r'(?i)92\.113\.144\.59'
        ]
    },
    'frontend': {
        'name': 'Frontend',
        'icon': '🎨',
        'color': '#00bcd4',
        'description': 'React, Vite, JavaScript, CSS errors',
        'patterns': [
            r'(?i)react', r'(?i)vite', r'(?i)javascript.*error', r'(?i)js.*error',
            r'(?i)uncaught.*exception', r'(?i)chunk.*load.*error', r'(?i)module.*not.*found',
            r'(?i)css.*error', r'(?i)render.*error', r'(?i)component.*error',
            r'(?i)hydration.*error', r'(?i)dom.*exception'
        ]
    },
    'backend': {
        'name': 'Backend',
        'icon': '⚙️',
        'color': '#3f51b5',
        'description': 'Flask, Python, API route errors',
        'patterns': [
            r'(?i)flask', r'(?i)werkzeug', r'(?i)python.*error', r'(?i)traceback',
            r'(?i)importerror', r'(?i)modulenotfounderror', r'(?i)typeerror',
            r'(?i)valueerror', r'(?i)keyerror', r'(?i)attributeerror',
            r'(?i)route.*error', r'(?i)blueprint.*error'
        ]
    },
    'security': {
        'name': 'Security',
        'icon': '🔐',
        'color': '#f44336',
        'description': 'Auth, injection, XSS, CSRF, breaches',
        'patterns': [
            r'(?i)sql.*injection', r'(?i)xss', r'(?i)csrf', r'(?i)security.*breach',
            r'(?i)unauthorized', r'(?i)forbidden', r'(?i)permission.*denied',
            r'(?i)invalid.*token', r'(?i)suspicious.*activity', r'(?i)brute.*force',
            r'(?i)rate.*limit.*exceeded', r'(?i)blocked.*ip'
        ]
    },
    'resources': {
        'name': 'Resources',
        'icon': '📊',
        'color': '#ff5722',
        'description': 'CPU, memory, disk, system load',
        'patterns': [
            r'(?i)out.*of.*memory', r'(?i)memory.*limit', r'(?i)oom.*kill',
            r'(?i)disk.*full', r'(?i)disk.*space', r'(?i)cpu.*high',
            r'(?i)load.*average', r'(?i)swap.*usage', r'(?i)resource.*exhausted'
        ]
    },
    'docker': {
        'name': 'Docker',
        'icon': '🐳',
        'color': '#2196f3',
        'description': 'Containers, images, networks, volumes',
        'patterns': [
            r'(?i)docker', r'(?i)container.*error', r'(?i)container.*exit',
            r'(?i)image.*pull.*error', r'(?i)network.*error', r'(?i)volume.*error',
            r'(?i)compose.*error', r'(?i)healthcheck.*fail', r'(?i)restart.*count'
        ]
    },
    'network': {
        'name': 'Network',
        'icon': '🌍',
        'color': '#009688',
        'description': 'Connectivity, DNS, SSL/TLS, timeouts',
        'patterns': [
            r'(?i)connection.*refused', r'(?i)connection.*timeout', r'(?i)dns.*error',
            r'(?i)host.*unreachable', r'(?i)network.*unreachable', r'(?i)ssl.*handshake',
            r'(?i)tls.*error', r'(?i)socket.*error', r'(?i)econnreset', r'(?i)etimedout'
        ]
    },
    'authentication': {
        'name': 'Authentication',
        'icon': '🔑',
        'color': '#673ab7',
        'description': 'Login, OAuth, JWT, sessions',
        'patterns': [
            r'(?i)login.*fail', r'(?i)authentication.*fail', r'(?i)oauth.*error',
            r'(?i)discord.*oauth', r'(?i)jwt.*error', r'(?i)token.*expired',
            r'(?i)session.*invalid', r'(?i)credential.*error', r'(?i)password.*error'
        ]
    },
    'api': {
        'name': 'API',
        'icon': '🔌',
        'color': '#795548',
        'description': 'HTTP errors, rate limits, endpoints',
        'patterns': [
            r'(?i)http.*error', r'(?i)400.*bad.*request', r'(?i)401.*unauthorized',
            r'(?i)403.*forbidden', r'(?i)404.*not.*found', r'(?i)405.*method',
            r'(?i)429.*too.*many', r'(?i)500.*internal', r'(?i)502.*bad.*gateway',
            r'(?i)503.*unavailable', r'(?i)504.*timeout', r'(?i)api.*error'
        ]
    },
    'websocket': {
        'name': 'WebSocket',
        'icon': '⚡',
        'color': '#4caf50',
        'description': 'Socket.IO, real-time connections',
        'patterns': [
            r'(?i)websocket', r'(?i)socket\.io', r'(?i)ws.*error', r'(?i)disconnect',
            r'(?i)reconnect.*fail', r'(?i)handshake.*fail', r'(?i)emit.*error'
        ]
    },
    'email': {
        'name': 'Email',
        'icon': '📧',
        'color': '#607d8b',
        'description': 'SMTP, notifications, delivery',
        'patterns': [
            r'(?i)smtp.*error', r'(?i)email.*fail', r'(?i)mail.*error',
            r'(?i)delivery.*fail', r'(?i)notification.*error', r'(?i)bounce',
            r'(?i)noreply@tovtech'
        ]
    },
    'scheduler': {
        'name': 'Scheduler',
        'icon': '⏰',
        'color': '#8bc34a',
        'description': 'APScheduler, cron, background jobs',
        'patterns': [
            r'(?i)apscheduler', r'(?i)cron', r'(?i)scheduler.*error',
            r'(?i)job.*fail', r'(?i)background.*task', r'(?i)celery.*error',
            r'(?i)task.*timeout'
        ]
    },
    'migration': {
        'name': 'Migration',
        'icon': '📦',
        'color': '#cddc39',
        'description': 'Alembic, database schema changes',
        'patterns': [
            r'(?i)alembic', r'(?i)migration.*error', r'(?i)upgrade.*fail',
            r'(?i)downgrade.*fail', r'(?i)schema.*error', r'(?i)revision.*error'
        ]
    },
    'monitoring': {
        'name': 'Monitoring',
        'icon': '📈',
        'color': '#ffc107',
        'description': 'Prometheus, Grafana, alerting',
        'patterns': [
            r'(?i)prometheus', r'(?i)grafana', r'(?i)alertmanager', r'(?i)loki',
            r'(?i)promtail', r'(?i)metric.*error', r'(?i)scrape.*error',
            r'(?i)exporter.*error'
        ]
    },
    'cloudflare': {
        'name': 'Cloudflare',
        'icon': '☁️',
        'color': '#ff6f00',
        'description': 'CDN, WAF, caching, SSL',
        'patterns': [
            r'(?i)cloudflare', r'(?i)cf-ray', r'(?i)waf.*block', r'(?i)challenge',
            r'(?i)cache.*error', r'(?i)edge.*error', r'(?i)rate.*limit'
        ]
    },
    'system': {
        'name': 'System',
        'icon': '💻',
        'color': '#9e9e9e',
        'description': 'Linux, services, processes',
        'patterns': [
            r'(?i)systemd', r'(?i)kernel', r'(?i)service.*fail', r'(?i)process.*kill',
            r'(?i)signal.*received', r'(?i)segfault', r'(?i)core.*dump',
            r'(?i)permission.*denied', r'(?i)no.*such.*file'
        ]
    }
}

# =============================================================================
# TEAM MEMBERS
# =============================================================================
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
    'raz': {'name': 'Raz Tovaly', 'role': 'Owner', 'color': '#f0883e'},
    'admin': {'name': 'System Admin', 'role': 'DevOps', 'color': '#6e7681'},
    'root': {'name': 'Root User', 'role': 'DevOps', 'color': '#6e7681'},
    'github-actions': {'name': 'GitHub Actions', 'role': 'CI/CD', 'color': '#238636'},
}

# =============================================================================
# SEVERITY LEVELS
# =============================================================================
SEVERITY_RULES = [
    {
        'pattern': r'(?i)(CRITICAL|FATAL|crash|corrupt|data.*loss|truncate.*table|drop.*table|injection|breach|deadlock|replication.*lag)',
        'level': 5,
        'label': 'CRITICAL',
        'color': '#ff0000'
    },
    {
        'pattern': r'(?i)(500.*error|internal.*server|connection.*refused|out.*of.*memory|disk.*full|authentication.*fail|pool.*exhausted|postgres.*error|psycopg2.*error)',
        'level': 4,
        'label': 'URGENT',
        'color': '#ff6b00'
    },
    {
        'pattern': r'(?i)(error|exception|failed|failure|unable|cannot|timeout|not.*found|403|401|connection.*error|database.*error)',
        'level': 3,
        'label': 'HIGH',
        'color': '#ffcc00'
    },
    {
        'pattern': r'(?i)(warning|deprecated|slow|retry|rollback|conflict)',
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

# =============================================================================
# NOISE FILTER - Patterns to EXCLUDE (not real errors)
# These are SUCCESS logs, health checks, and routine operations - NOT bugs!
# =============================================================================
NOISE_PATTERNS = [
    # --- NGINX ACCESS LOGS WITH SUCCESS STATUS CODES ---
    # These are just access logs, not errors - filter them ALL
    r'" 200 \d+',          # Any protocol with 200 OK
    r'" 201 \d+',          # Created
    r'" 204 \d+',          # No Content
    r'" 206 \d+',          # Partial Content
    r'" 301 \d+',          # Redirect
    r'" 302 \d+',          # Redirect
    r'" 304 \d+',          # Not Modified (cache hit)
    r'HTTP/1\.[01]" 2\d\d', # HTTP/1.x 2xx success
    r'HTTP/2\.0" 2\d\d',    # HTTP/2.0 2xx success
    r'HTTP/2" 2\d\d',       # HTTP/2 2xx success
    r'HTTP/1\.[01]" 3\d\d', # HTTP/1.x 3xx redirect
    r'HTTP/2\.0" 3\d\d',    # HTTP/2.0 3xx redirect
    r'HTTP/2" 3\d\d',       # HTTP/2 3xx redirect

    # --- NGINX ACCESS LOG FORMAT (IP - - [date] "request") ---
    # These are just request logs, filter if they're successful requests
    r'\d+\.\d+\.\d+\.\d+ - - \[.*\] "GET .* HTTP/.*" 2\d\d',
    r'\d+\.\d+\.\d+\.\d+ - - \[.*\] "POST .* HTTP/.*" 2\d\d',
    r'\d+\.\d+\.\d+\.\d+ - - \[.*\] "PUT .* HTTP/.*" 2\d\d',
    r'\d+\.\d+\.\d+\.\d+ - - \[.*\] "DELETE .* HTTP/.*" 2\d\d',
    r'\d+\.\d+\.\d+\.\d+ - - \[.*\] "OPTIONS .* HTTP/.*" 2\d\d',

    # --- HEALTH CHECKS ---
    r'(?i)health.*check.*passed',
    r'(?i)healthcheck.*ok',
    r'(?i)GET /api/health',
    r'(?i)GET /health',
    r'(?i)/health.*200',
    r'(?i)/ready.*200',
    r'(?i)/liveness.*200',

    # --- INFO/DEBUG LEVEL LOGS (not errors) ---
    r'(?i)\bINFO\b',        # INFO level logs
    r'(?i)\bDEBUG\b',       # DEBUG level logs
    r'(?i)level=info',
    r'(?i)level=debug',
    r'(?i)info.*starting',
    r'(?i)info.*started',
    r'(?i)info.*listening',
    r'(?i)info.*connected',
    r'(?i)info.*ready',

    # --- ROUTINE OPERATIONS ---
    r'(?i)metrics.*collected',
    r'(?i)prometheus.*scrape',
    r'(?i)loki.*push',
    r'(?i)promtail',
    r'(?i)status=200',
    r'(?i)Processing request',
    r'(?i)Request completed',
    r'(?i)session.*created',
    r'(?i)cache.*hit',
    r'(?i)query.*executed.*successfully',
    r'(?i)connected to database',
    r'(?i)connection established',
    r'(?i)server started',
    r'(?i)listening on port',

    # --- THIS DASHBOARD'S OWN REQUESTS ---
    r'/logs/api/errors',
    r'/logs/api/stats',
    r'/logs/api/health',
    r'/logs/api/categories',
]

# =============================================================================
# ERROR EXPLANATIONS - What each error means and how to fix it
# =============================================================================
ERROR_EXPLANATIONS = {
    # Database errors
    'psycopg2.OperationalError': {
        'what': 'PostgreSQL connection failed or was lost',
        'why': 'Database server unreachable, connection pool exhausted, or credentials invalid',
        'fix': '1. Check DB server status\n2. Verify DATABASE_URL in .env\n3. Check connection pool limits\n4. Restart backend if pool exhausted',
        'owner': 'Backend Team'
    },
    'sqlalchemy.exc.IntegrityError': {
        'what': 'Database constraint violation (duplicate key, foreign key, null constraint)',
        'why': 'Code tried to insert/update data that violates DB rules',
        'fix': '1. Check the specific constraint in error\n2. Add validation before DB operation\n3. Handle unique constraint in code',
        'owner': 'Backend Team'
    },
    'connection pool exhausted': {
        'what': 'All database connections are in use',
        'why': 'Too many concurrent requests or connections not being released',
        'fix': '1. Increase pool_size in db config\n2. Check for connection leaks\n3. Add connection timeout\n4. Restart backend',
        'owner': 'DevOps + Backend'
    },
    'deadlock': {
        'what': 'Two transactions waiting for each other forever',
        'why': 'Concurrent updates to same rows in different order',
        'fix': '1. Add retry logic for deadlocks\n2. Use SELECT FOR UPDATE\n3. Reduce transaction scope\n4. Order updates consistently',
        'owner': 'Backend Team'
    },
    # Python errors
    'TypeError': {
        'what': 'Wrong data type passed to function',
        'why': 'Code expected one type but got another (e.g., None instead of string)',
        'fix': '1. Add null checks\n2. Validate input types\n3. Use type hints\n4. Check function signature',
        'owner': 'Backend Team'
    },
    'KeyError': {
        'what': 'Dictionary key does not exist',
        'why': 'Accessing dict key that wasnt set, often from API response',
        'fix': '1. Use .get() with default\n2. Check if key exists first\n3. Validate API responses',
        'owner': 'Backend Team'
    },
    'AttributeError': {
        'what': 'Object does not have expected attribute/method',
        'why': 'Variable is None or wrong type',
        'fix': '1. Add None check before access\n2. Verify object type\n3. Check import statements',
        'owner': 'Backend Team'
    },
    'ImportError': {
        'what': 'Python module cannot be imported',
        'why': 'Package not installed or wrong Python environment',
        'fix': '1. pip install <package>\n2. Check requirements.txt\n3. Verify venv is activated',
        'owner': 'DevOps'
    },
    # Network errors
    'ConnectionRefusedError': {
        'what': 'Target server actively refused connection',
        'why': 'Service not running or wrong port',
        'fix': '1. Check if target service is running\n2. Verify port number\n3. Check firewall rules',
        'owner': 'DevOps'
    },
    'ECONNRESET': {
        'what': 'Connection was reset by peer',
        'why': 'Remote server closed connection unexpectedly',
        'fix': '1. Add retry logic\n2. Check remote server logs\n3. Increase timeouts',
        'owner': 'DevOps'
    },
    'timeout': {
        'what': 'Operation took too long and was aborted',
        'why': 'Slow query, network issue, or overloaded service',
        'fix': '1. Increase timeout value\n2. Optimize slow queries\n3. Add caching\n4. Check server load',
        'owner': 'Backend + DevOps'
    },
    # HTTP errors
    '500': {
        'what': 'Internal Server Error - backend crashed',
        'why': 'Unhandled exception in backend code',
        'fix': '1. Check backend logs for traceback\n2. Find the route that failed\n3. Add try/except handling',
        'owner': 'Backend Team'
    },
    '502': {
        'what': 'Bad Gateway - nginx cant reach backend',
        'why': 'Backend container down or not responding',
        'fix': '1. docker ps - check backend status\n2. docker logs backend\n3. Restart backend container',
        'owner': 'DevOps'
    },
    '503': {
        'what': 'Service Unavailable - server overloaded',
        'why': 'Too many requests or service starting up',
        'fix': '1. Check server resources\n2. Scale up if needed\n3. Add rate limiting',
        'owner': 'DevOps'
    },
    '504': {
        'what': 'Gateway Timeout - request took too long',
        'why': 'Slow backend response, usually DB query',
        'fix': '1. Find slow endpoint\n2. Optimize DB queries\n3. Increase nginx timeout',
        'owner': 'Backend + DevOps'
    },
    '401': {
        'what': 'Unauthorized - authentication required',
        'why': 'Missing or invalid JWT token',
        'fix': '1. Check token expiration\n2. Verify JWT_SECRET matches\n3. Re-login user',
        'owner': 'Backend Team'
    },
    '403': {
        'what': 'Forbidden - user lacks permission',
        'why': 'User authenticated but not authorized for this action',
        'fix': '1. Check user roles/permissions\n2. Verify route protection logic',
        'owner': 'Backend Team'
    },
    # Docker errors
    'OOMKilled': {
        'what': 'Container killed due to out of memory',
        'why': 'Container exceeded memory limit',
        'fix': '1. Increase container memory limit\n2. Find memory leak\n3. Optimize memory usage',
        'owner': 'DevOps'
    },
    'CrashLoopBackOff': {
        'what': 'Container keeps crashing on startup',
        'why': 'Application error during initialization',
        'fix': '1. docker logs <container>\n2. Check entrypoint script\n3. Verify env variables',
        'owner': 'DevOps'
    },
    # Auth errors
    'jwt': {
        'what': 'JWT token error',
        'why': 'Token expired, invalid signature, or malformed',
        'fix': '1. Check JWT_SECRET_KEY matches\n2. Verify token expiration\n3. Check token format',
        'owner': 'Backend Team'
    },
    'oauth': {
        'what': 'OAuth authentication failed',
        'why': 'Discord OAuth misconfigured or callback URL wrong',
        'fix': '1. Verify DISCORD_CLIENT_ID/SECRET\n2. Check redirect URI matches\n3. Verify OAuth scopes',
        'owner': 'Backend Team'
    },
    # Systemd/Service errors
    'syntax error': {
        'what': 'Script syntax error - bash script has invalid syntax',
        'why': 'Script contains invalid bash syntax (possibly wrong shell or encoding)',
        'fix': '1. Check script shebang line\n2. Verify no Windows line endings (CRLF)\n3. Use dos2unix to fix\n4. Test with bash -n script.sh',
        'owner': 'DevOps'
    },
    'Failed with result': {
        'what': 'Systemd service exited with non-zero status',
        'why': 'Service script crashed or returned error code',
        'fix': '1. journalctl -u <service> -n 50\n2. Check service script\n3. Verify dependencies\n4. Check permissions',
        'owner': 'DevOps'
    },
    'exit-code': {
        'what': 'Process exited with non-zero exit code',
        'why': 'Command or script returned error status',
        'fix': '1. Check process logs\n2. Run command manually\n3. Verify environment variables\n4. Check file permissions',
        'owner': 'DevOps'
    },
    'watchdog': {
        'what': 'Watchdog service failed',
        'why': 'Watchdog script has errors or monitored service is down',
        'fix': '1. Check watchdog script syntax\n2. Verify monitored services\n3. Check systemctl status\n4. Review /var/log/syslog',
        'owner': 'DevOps'
    },
    'unexpected token': {
        'what': 'Shell script parsing error',
        'why': 'Invalid character or syntax in bash script (often Windows line endings)',
        'fix': '1. dos2unix script.sh\n2. Check for special characters\n3. Verify proper quoting\n4. Test with bash -n',
        'owner': 'DevOps'
    }
}

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================
def is_noise(log_text):
    """Check if log entry is noise (not a real error needing debugging)"""
    for pattern in NOISE_PATTERNS:
        if re.search(pattern, log_text):
            return True
    return False

def get_error_explanation(log_text):
    """Get explanation for the error type"""
    log_lower = log_text.lower()
    for error_key, explanation in ERROR_EXPLANATIONS.items():
        if error_key.lower() in log_lower:
            return explanation
    return None

def extract_git_context(log_text):
    """Extract git commit/PR info from log if present"""
    context = {}

    # Look for commit hashes
    commit_match = re.search(r'([a-f0-9]{7,40})', log_text)
    if commit_match:
        context['commit'] = commit_match.group(1)[:7]

    # Look for PR numbers
    pr_match = re.search(r'#(\d+)|PR[- ]?(\d+)|pull[/ ](\d+)', log_text, re.IGNORECASE)
    if pr_match:
        context['pr'] = pr_match.group(1) or pr_match.group(2) or pr_match.group(3)

    # Look for branch names
    branch_match = re.search(r'(main|master|develop|feature/[^\s]+|fix/[^\s]+|hotfix/[^\s]+)', log_text)
    if branch_match:
        context['branch'] = branch_match.group(1)

    return context if context else None

def identify_team_member(log_text):
    """Identify team member from log text - enhanced with context"""
    log_lower = log_text.lower()

    # Direct username match
    for username, info in TEAM_MEMBERS.items():
        if username.lower() in log_lower:
            return info

    # Check for email patterns
    email_match = re.search(r'([a-zA-Z]+)@tovtech\.org', log_text, re.IGNORECASE)
    if email_match:
        name = email_match.group(1).lower()
        for username, info in TEAM_MEMBERS.items():
            if name in username.lower() or name in info['name'].lower():
                return info

    # Check for author patterns from git
    author_match = re.search(r'author[:\s]+([^\s<]+)', log_text, re.IGNORECASE)
    if author_match:
        author = author_match.group(1).lower()
        for username, info in TEAM_MEMBERS.items():
            if author in username.lower() or author in info['name'].lower().replace(' ', ''):
                return info

    return None

def calculate_severity(log_text):
    """Calculate severity level (1-5)"""
    for rule in SEVERITY_RULES:
        if re.search(rule['pattern'], log_text):
            return {
                'level': rule['level'],
                'label': rule['label'],
                'color': rule['color']
            }
    return {'level': 1, 'label': 'LOW', 'color': '#0066ff'}

def identify_categories(log_text):
    """Identify all matching categories for a log entry"""
    matching = []
    for cat_id, cat_info in CATEGORIES.items():
        for pattern in cat_info['patterns']:
            if re.search(pattern, log_text):
                matching.append({
                    'id': cat_id,
                    'name': cat_info['name'],
                    'icon': cat_info['icon'],
                    'color': cat_info['color']
                })
                break  # Only add category once
    return matching if matching else [{'id': 'uncategorized', 'name': 'Uncategorized', 'icon': '❓', 'color': '#6e7681'}]

def query_loki_single(start, end, limit=5000):
    """Single Loki query for a time range - SIMPLIFIED PATTERN"""
    # SIMPLIFIED QUERY - No character classes, uses literal patterns
    # Most logs use lowercase, but we include common variants
    error_query = r'{job=~".+"} |~ "error|Error|ERROR|exception|Exception|EXCEPTION|fail|Fail|FAIL|critical|Critical|CRITICAL|fatal|Fatal|FATAL|panic|crash|traceback|Traceback|timeout|Timeout|TIMEOUT|SIGSEGV|SIGABRT|NoneType|AttributeError|TypeError|ValueError|KeyError|IndexError|RuntimeError|ImportError|ModuleNotFoundError|NameError|SyntaxError|ZeroDivisionError|FileNotFoundError|PermissionError|OSError|IOError|MemoryError| 400 | 401 | 403 | 404 | 405 | 429 | 500 | 501 | 502 | 503 | 504 |database|Database|postgres|Postgres|psycopg|sqlalchemy|SQLAlchemy|deadlock|rollback|constraint|integrity|connection|Connection|refused|ECONNREFUSED|ECONNRESET|ETIMEDOUT|EHOSTUNREACH|socket|network|Network|dns|DNS|ssl|SSL|tls|TLS|certificate|handshake|OOM|OOMKilled|CrashLoopBackOff|ImagePullBackOff|unhealthy|container|Container|docker|Docker|nginx|Nginx|upstream|proxy|gateway|Gateway|auth|Auth|login|Login|token|Token|jwt|JWT|oauth|OAuth|session|Session|credential|password|denied|unauthorized|Unauthorized|forbidden|Forbidden|invalid|Invalid|malformed|corrupt|broken|missing|Missing|validation|schema|conflict|retry|Retry|assert|violation|warn|Warn|WARN|deprecated|slow|exit|errno"'

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
        timeout=60
    )

    if response.status_code == 429:
        return None  # Rate limited

    response.raise_for_status()
    return response.json()

def query_loki(start=None, end=None, limit=5000, category=None):
    """Query Loki for ALL error logs - WITH CHUNKED QUERIES FOR LONG RANGES

    v3.2 FIX: Uses simplified query pattern and chunks long time ranges
    to avoid 429 rate limiting from Loki.
    """
    if not end:
        end = datetime.utcnow()
    if not start:
        start = end - timedelta(hours=1)

    total_hours = (end - start).total_seconds() / 3600

    # For queries > 24 hours, split into 6-hour chunks
    if total_hours > 24:
        print(f"Long query detected ({total_hours:.1f}h), using chunked queries...")
        all_results = []
        chunk_hours = 6
        current_end = end
        chunk_count = 0
        max_chunks = 28  # 7 days / 6 hours = 28 chunks

        while current_end > start and chunk_count < max_chunks:
            chunk_start = max(start, current_end - timedelta(hours=chunk_hours))

            # Retry with backoff on rate limit
            for attempt in range(3):
                try:
                    print(f"  Chunk {chunk_count+1}: {chunk_start.isoformat()} to {current_end.isoformat()}")
                    result = query_loki_single(chunk_start, current_end, limit=1000)

                    if result is None:
                        # Rate limited - wait and retry
                        wait_time = (attempt + 1) * 2
                        print(f"    Rate limited, waiting {wait_time}s...")
                        time.sleep(wait_time)
                        continue

                    if result.get('status') == 'success':
                        for stream in result.get('data', {}).get('result', []):
                            all_results.append(stream)
                    break

                except Exception as e:
                    print(f"    Chunk error: {e}")
                    if attempt < 2:
                        time.sleep(2)

            current_end = chunk_start
            chunk_count += 1
            time.sleep(0.5)  # Small delay between chunks

        print(f"Completed {chunk_count} chunks, total streams: {len(all_results)}")
        return {'status': 'success', 'data': {'result': all_results}}

    # For shorter queries, use single query with retry
    for attempt in range(3):
        try:
            result = query_loki_single(start, end, limit)
            if result is None:
                wait_time = (attempt + 1) * 2
                print(f"Rate limited, waiting {wait_time}s...")
                time.sleep(wait_time)
                continue
            return result
        except Exception as e:
            print(f"Loki query error (attempt {attempt+1}): {e}")
            if attempt < 2:
                time.sleep(2)

    return {'status': 'error', 'data': {'result': []}}

def enrich_logs(loki_response, category_filter=None, sort_by='time', sort_order='desc', filter_noise=True):
    """Enrich logs with team attribution, severity, categories, and explanations.

    v3.3: Now filters out noise and adds actionable explanations.
    """
    enriched = []
    noise_count = 0

    if loki_response.get('status') != 'success':
        return enriched

    results = loki_response.get('data', {}).get('result', [])

    for stream in results:
        labels = stream.get('stream', {})
        values = stream.get('values', [])

        for timestamp_ns, log_line in values:
            # FILTER NOISE - Skip entries that aren't real errors
            if filter_noise and is_noise(log_line):
                noise_count += 1
                continue

            timestamp = datetime.fromtimestamp(int(timestamp_ns) / 1e9)
            team_member = identify_team_member(log_line)
            severity = calculate_severity(log_line)
            categories = identify_categories(log_line)
            explanation = get_error_explanation(log_line)
            git_context = extract_git_context(log_line)

            # Filter by category if specified
            if category_filter and category_filter != 'all':
                if not any(c['id'] == category_filter for c in categories):
                    continue

            # Only include if severity >= 3 (HIGH or higher) when filtering noise
            # This ensures we only see REAL ERRORS that need debugging
            if filter_noise and severity['level'] < 3:
                noise_count += 1
                continue

            enriched.append({
                'timestamp': timestamp.isoformat(),
                'timestamp_unix': int(timestamp_ns) / 1e9,
                'log': log_line,
                'labels': labels,
                'team_member': team_member,
                'severity': severity,
                'categories': categories,
                'explanation': explanation,
                'git_context': git_context,
                'actionable': explanation is not None
            })

    print(f"Filtered {noise_count} noise entries, kept {len(enriched)} actionable errors")

    # Sort results
    if sort_by == 'time':
        enriched.sort(key=lambda x: x['timestamp_unix'], reverse=(sort_order == 'desc'))
    elif sort_by == 'severity':
        enriched.sort(key=lambda x: x['severity']['level'], reverse=(sort_order == 'desc'))
    elif sort_by == 'category':
        enriched.sort(key=lambda x: x['categories'][0]['name'] if x['categories'] else 'ZZZ', reverse=(sort_order == 'desc'))

    return enriched

# =============================================================================
# API ROUTES
# =============================================================================
@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('dashboard_enhanced.html')

@app.route('/api/errors')
def get_errors():
    """Get ACTIONABLE error logs with filtering and sorting.

    v3.3: By default filters out noise (health checks, INFO logs, etc.)
    Pass ?filter_noise=false to see all logs
    """
    try:
        time_range = request.args.get('range', '1h')
        category = request.args.get('category', 'all')
        sort_by = request.args.get('sort', 'time')
        sort_order = request.args.get('order', 'desc')
        filter_noise = request.args.get('filter_noise', 'true').lower() != 'false'

        end = datetime.utcnow()
        time_map = {
            '1m': timedelta(minutes=1),
            '5m': timedelta(minutes=5),
            '30m': timedelta(minutes=30),
            '1h': timedelta(hours=1),
            '6h': timedelta(hours=6),
            '24h': timedelta(hours=24),
            '7d': timedelta(days=7)
        }
        start = end - time_map.get(time_range, timedelta(hours=1))

        loki_response = query_loki(start=start, end=end)
        enriched_logs = enrich_logs(
            loki_response,
            category_filter=category,
            sort_by=sort_by,
            sort_order=sort_order,
            filter_noise=filter_noise
        )

        return jsonify({
            'status': 'success',
            'count': len(enriched_logs),
            'filters': {
                'range': time_range,
                'category': category,
                'sort_by': sort_by,
                'sort_order': sort_order,
                'filter_noise': filter_noise
            },
            'errors': enriched_logs
        })
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/categories')
def get_categories():
    """Get all available categories"""
    return jsonify({
        'status': 'success',
        'categories': [
            {
                'id': cat_id,
                'name': info['name'],
                'icon': info['icon'],
                'color': info['color'],
                'description': info['description']
            }
            for cat_id, info in CATEGORIES.items()
        ]
    })

@app.route('/api/stats')
def get_stats():
    """Get comprehensive error statistics by category"""
    try:
        time_range = request.args.get('range', '1h')
        end = datetime.utcnow()
        time_map = {
            '1m': timedelta(minutes=1),
            '5m': timedelta(minutes=5),
            '30m': timedelta(minutes=30),
            '1h': timedelta(hours=1),
            '6h': timedelta(hours=6),
            '24h': timedelta(hours=24),
            '7d': timedelta(days=7)
        }
        start = end - time_map.get(time_range, timedelta(hours=1))

        loki_response = query_loki(start=start, end=end)
        enriched_logs = enrich_logs(loki_response)

        # Calculate comprehensive stats
        stats = {
            'total_errors': len(enriched_logs),
            'severity_breakdown': defaultdict(int),
            'category_breakdown': defaultdict(int),
            'team_breakdown': defaultdict(int),
            'critical_errors': 0,
            'urgent_errors': 0,
            'by_hour': defaultdict(int)
        }

        for log in enriched_logs:
            severity_level = log['severity']['level']
            stats['severity_breakdown'][severity_level] += 1

            if severity_level == 5:
                stats['critical_errors'] += 1
            elif severity_level == 4:
                stats['urgent_errors'] += 1

            for cat in log['categories']:
                stats['category_breakdown'][cat['id']] += 1

            if log['team_member']:
                stats['team_breakdown'][log['team_member']['name']] += 1

            # Group by hour
            hour = log['timestamp'][:13]
            stats['by_hour'][hour] += 1

        # Get top categories
        top_categories = sorted(
            stats['category_breakdown'].items(),
            key=lambda x: x[1],
            reverse=True
        )[:10]

        return jsonify({
            'status': 'success',
            'stats': {
                'total_errors': stats['total_errors'],
                'critical_errors': stats['critical_errors'],
                'urgent_errors': stats['urgent_errors'],
                'severity_breakdown': dict(stats['severity_breakdown']),
                'category_breakdown': dict(stats['category_breakdown']),
                'top_categories': [{'id': k, 'count': v, 'name': CATEGORIES.get(k, {}).get('name', k)} for k, v in top_categories],
                'team_breakdown': dict(stats['team_breakdown']),
                'by_hour': dict(stats['by_hour'])
            }
        })
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

@app.route('/api/health')
def health():
    """Health check endpoint"""
    try:
        response = requests.get(f"{LOKI_URL}/ready", timeout=5)
        loki_status = "healthy" if response.status_code == 200 else "unhealthy"
    except:
        loki_status = "unreachable"

    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'loki': loki_status,
        'version': '3.5',
        'features': [
            'errors-only-mode',
            'no-access-logs',
            'no-info-debug-logs',
            'severity-high-or-above',
            'error-explanations',
            'team-attribution',
            'fix-suggestions',
            'comprehensive-noise-filter',
            'chunked-7d-queries'
        ],
        'categories_count': len(CATEGORIES),
        'explanations_count': len(ERROR_EXPLANATIONS),
        'dashboard': 'actionable-error-dashboard'
    })

@app.route('/api/team-members')
def get_team_members():
    """Get team member list"""
    unique_members = {}
    for username, info in TEAM_MEMBERS.items():
        if info['name'] not in unique_members:
            unique_members[info['name']] = {
                'name': info['name'],
                'role': info['role'],
                'color': info['color'],
                'usernames': []
            }
        unique_members[info['name']]['usernames'].append(username)

    return jsonify({
        'status': 'success',
        'team_members': list(unique_members.values())
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7778, debug=False)
