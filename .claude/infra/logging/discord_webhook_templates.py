"""
============================================================================
DISCORD WEBHOOK TEMPLATES - TovPlay Production
============================================================================
Real-time alert notifications to Discord channels
Use these functions to send formatted alerts to Discord

Setup:
1. Create webhooks in Discord server settings
2. Set DISCORD_WEBHOOK_* environment variables
3. Import and call functions as needed

Usage:
    from discord_webhook_templates import send_critical_alert, send_security_alert

    send_critical_alert(
        title="Database Connection Exhaustion",
        description="Connection pool at 95% capacity",
        severity="CRITICAL"
    )
============================================================================
"""

import os
import json
import requests
from datetime import datetime
from typing import Optional, Dict, List

# ============================================================================
# CONFIGURATION
# ============================================================================

WEBHOOK_GENERAL = os.getenv('DISCORD_WEBHOOK_GENERAL', 'https://discord.com/api/webhooks/1432633014071853108/...')
WEBHOOK_CRITICAL = os.getenv('DISCORD_WEBHOOK_CRITICAL', '')
WEBHOOK_SECURITY = os.getenv('DISCORD_WEBHOOK_SECURITY', '')
WEBHOOK_DATABASE = os.getenv('DISCORD_WEBHOOK_DATABASE', '')
WEBHOOK_PERFORMANCE = os.getenv('DISCORD_WEBHOOK_PERFORMANCE', '')

# Color codes
COLOR_RED = 0xFF0000      # Critical
COLOR_ORANGE = 0xFFA500   # Warning
COLOR_YELLOW = 0xFFFF00   # Info
COLOR_GREEN = 0x00FF00    # Success
COLOR_BLUE = 0x0000FF     # Info
COLOR_PURPLE = 0x800080   # Security

# ============================================================================
# BASE WEBHOOK FUNCTION
# ============================================================================

def send_discord_webhook(
    webhook_url: str,
    content: Optional[str] = None,
    embeds: Optional[List[Dict]] = None,
    username: str = "TovPlay Alerts",
    avatar_url: str = "https://app.tovplay.org/logo.png"
) -> bool:
    """
    Send message to Discord webhook.

    Args:
        webhook_url: Discord webhook URL
        content: Text content (mentions, plain text)
        embeds: List of embed objects (rich formatting)
        username: Bot username to display
        avatar_url: Bot avatar URL

    Returns:
        True if successful, False otherwise
    """
    if not webhook_url:
        print("Discord webhook URL not configured")
        return False

    payload = {
        "username": username,
        "avatar_url": avatar_url
    }

    if content:
        payload["content"] = content

    if embeds:
        payload["embeds"] = embeds

    try:
        response = requests.post(
            webhook_url,
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        response.raise_for_status()
        return True

    except Exception as e:
        print(f"Failed to send Discord webhook: {str(e)}")
        return False

# ============================================================================
# CRITICAL ALERTS
# ============================================================================

def send_critical_alert(
    title: str,
    description: str,
    severity: str = "CRITICAL",
    impact: Optional[str] = None,
    action: Optional[str] = None,
    runbook_url: Optional[str] = None,
    fields: Optional[Dict[str, str]] = None,
    mention_everyone: bool = True
) -> bool:
    """
    Send critical alert to Discord.

    Args:
        title: Alert title
        description: Alert description
        severity: Severity level (CRITICAL, HIGH, etc.)
        impact: Impact description
        action: Required action
        runbook_url: Link to runbook/documentation
        fields: Additional fields to display
        mention_everyone: Whether to @everyone

    Returns:
        True if successful
    """
    embed = {
        "title": f"🔴 {severity}: {title}",
        "description": description,
        "color": COLOR_RED,
        "timestamp": datetime.utcnow().isoformat(),
        "fields": []
    }

    if impact:
        embed["fields"].append({
            "name": "💥 Impact",
            "value": impact,
            "inline": False
        })

    if action:
        embed["fields"].append({
            "name": "🔧 Action Required",
            "value": action,
            "inline": False
        })

    if runbook_url:
        embed["fields"].append({
            "name": "📖 Runbook",
            "value": f"[Click here]({runbook_url})",
            "inline": False
        })

    # Add custom fields
    if fields:
        for key, value in fields.items():
            embed["fields"].append({
                "name": key,
                "value": str(value),
                "inline": True
            })

    embed["footer"] = {
        "text": "TovPlay Monitoring System",
        "icon_url": "https://app.tovplay.org/favicon.ico"
    }

    content = "@everyone 🚨 **CRITICAL ALERT**" if mention_everyone else None

    return send_discord_webhook(
        webhook_url=WEBHOOK_CRITICAL or WEBHOOK_GENERAL,
        content=content,
        embeds=[embed]
    )

# ============================================================================
# SECURITY ALERTS
# ============================================================================

def send_security_alert(
    title: str,
    description: str,
    user_id: Optional[int] = None,
    username: Optional[str] = None,
    ip_address: Optional[str] = None,
    action: Optional[str] = None,
    severity: str = "HIGH",
    mention_here: bool = True
) -> bool:
    """
    Send security alert to Discord.

    Args:
        title: Alert title
        description: Alert description
        user_id: User ID involved
        username: Username involved
        ip_address: IP address involved
        action: Action taken
        severity: Severity level
        mention_here: Whether to @here

    Returns:
        True if successful
    """
    embed = {
        "title": f"🔒 SECURITY ALERT: {title}",
        "description": description,
        "color": COLOR_PURPLE,
        "timestamp": datetime.utcnow().isoformat(),
        "fields": []
    }

    if user_id:
        embed["fields"].append({
            "name": "👤 User ID",
            "value": str(user_id),
            "inline": True
        })

    if username:
        embed["fields"].append({
            "name": "👤 Username",
            "value": username,
            "inline": True
        })

    if ip_address:
        embed["fields"].append({
            "name": "🌐 IP Address",
            "value": ip_address,
            "inline": True
        })

    if action:
        embed["fields"].append({
            "name": "⚡ Action",
            "value": action,
            "inline": False
        })

    embed["fields"].append({
        "name": "⚠️ Severity",
        "value": severity,
        "inline": True
    })

    embed["footer"] = {
        "text": "TovPlay Security Monitoring",
        "icon_url": "https://app.tovplay.org/favicon.ico"
    }

    content = "@here 🚨 **SECURITY ALERT**" if mention_here else None

    return send_discord_webhook(
        webhook_url=WEBHOOK_SECURITY or WEBHOOK_GENERAL,
        content=content,
        embeds=[embed]
    )

# ============================================================================
# DATABASE ALERTS
# ============================================================================

def send_database_alert(
    title: str,
    description: str,
    database: str = "TovPlay",
    severity: str = "WARNING",
    current_value: Optional[str] = None,
    threshold: Optional[str] = None,
    action: Optional[str] = None
) -> bool:
    """
    Send database alert to Discord.

    Args:
        title: Alert title
        description: Alert description
        database: Database name
        severity: Severity level
        current_value: Current metric value
        threshold: Threshold value
        action: Recommended action

    Returns:
        True if successful
    """
    embed = {
        "title": f"🗄️ DATABASE ALERT: {title}",
        "description": description,
        "color": COLOR_ORANGE if severity == "WARNING" else COLOR_RED,
        "timestamp": datetime.utcnow().isoformat(),
        "fields": [
            {
                "name": "💾 Database",
                "value": database,
                "inline": True
            },
            {
                "name": "⚠️ Severity",
                "value": severity,
                "inline": True
            }
        ]
    }

    if current_value:
        embed["fields"].append({
            "name": "📊 Current Value",
            "value": current_value,
            "inline": True
        })

    if threshold:
        embed["fields"].append({
            "name": "🎯 Threshold",
            "value": threshold,
            "inline": True
        })

    if action:
        embed["fields"].append({
            "name": "🔧 Action",
            "value": action,
            "inline": False
        })

    embed["footer"] = {
        "text": "TovPlay Database Monitoring",
        "icon_url": "https://app.tovplay.org/favicon.ico"
    }

    return send_discord_webhook(
        webhook_url=WEBHOOK_DATABASE or WEBHOOK_GENERAL,
        embeds=[embed]
    )

# ============================================================================
# PERFORMANCE ALERTS
# ============================================================================

def send_performance_alert(
    title: str,
    description: str,
    metric_name: str,
    current_value: str,
    threshold: str,
    severity: str = "WARNING"
) -> bool:
    """
    Send performance alert to Discord.

    Args:
        title: Alert title
        description: Alert description
        metric_name: Name of metric
        current_value: Current metric value
        threshold: Threshold value
        severity: Severity level

    Returns:
        True if successful
    """
    embed = {
        "title": f"⚡ PERFORMANCE ALERT: {title}",
        "description": description,
        "color": COLOR_YELLOW if severity == "WARNING" else COLOR_ORANGE,
        "timestamp": datetime.utcnow().isoformat(),
        "fields": [
            {
                "name": "📊 Metric",
                "value": metric_name,
                "inline": True
            },
            {
                "name": "📈 Current Value",
                "value": current_value,
                "inline": True
            },
            {
                "name": "🎯 Threshold",
                "value": threshold,
                "inline": True
            },
            {
                "name": "⚠️ Severity",
                "value": severity,
                "inline": True
            }
        ]
    }

    embed["footer"] = {
        "text": "TovPlay Performance Monitoring",
        "icon_url": "https://app.tovplay.org/favicon.ico"
    }

    return send_discord_webhook(
        webhook_url=WEBHOOK_PERFORMANCE or WEBHOOK_GENERAL,
        embeds=[embed]
    )

# ============================================================================
# SUCCESS NOTIFICATIONS
# ============================================================================

def send_success_notification(
    title: str,
    description: str,
    fields: Optional[Dict[str, str]] = None
) -> bool:
    """
    Send success notification to Discord.

    Args:
        title: Notification title
        description: Notification description
        fields: Additional fields

    Returns:
        True if successful
    """
    embed = {
        "title": f"✅ {title}",
        "description": description,
        "color": COLOR_GREEN,
        "timestamp": datetime.utcnow().isoformat(),
        "fields": []
    }

    if fields:
        for key, value in fields.items():
            embed["fields"].append({
                "name": key,
                "value": str(value),
                "inline": True
            })

    embed["footer"] = {
        "text": "TovPlay Monitoring System",
        "icon_url": "https://app.tovplay.org/favicon.ico"
    }

    return send_discord_webhook(
        webhook_url=WEBHOOK_GENERAL,
        embeds=[embed]
    )

# ============================================================================
# EXAMPLE USAGE
# ============================================================================

if __name__ == "__main__":
    # Test critical alert
    send_critical_alert(
        title="Database Connection Exhaustion",
        description="PostgreSQL connection pool at 95% capacity",
        severity="CRITICAL",
        impact="Application may start rejecting new connections",
        action="Deploy PgBouncer connection pooler immediately",
        runbook_url="https://app.tovplay.org/logs/runbooks/connection-exhaustion",
        fields={
            "Current Connections": "95/100",
            "Database": "TovPlay@45.148.28.196",
            "Server": "production-01"
        }
    )

    # Test security alert
    send_security_alert(
        title="Brute Force Attack Detected",
        description="Multiple failed login attempts from same IP",
        user_id=123,
        username="attacker_user",
        ip_address="192.168.1.100",
        action="Block IP address immediately",
        severity="HIGH"
    )

    # Test database alert
    send_database_alert(
        title="Slow Query Detected",
        description="Query execution time exceeds threshold",
        database="TovPlay",
        severity="WARNING",
        current_value="2500ms",
        threshold="1000ms",
        action="Review and optimize query or add indexes"
    )

    # Test performance alert
    send_performance_alert(
        title="High API Latency",
        description="P95 latency exceeds threshold",
        metric_name="api_latency_p95",
        current_value="1500ms",
        threshold="1000ms",
        severity="WARNING"
    )

    # Test success notification
    send_success_notification(
        title="Deployment Complete",
        description="Backend v1.2.3 deployed successfully",
        fields={
            "Version": "1.2.3",
            "Server": "production-01",
            "Duration": "45s"
        }
    )

    print("Discord webhook tests sent!")
