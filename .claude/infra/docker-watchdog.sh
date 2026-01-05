#!/bin/bash
# ============================================================================
# TOVPLAY DOCKER WATCHDOG SERVICE
# ============================================================================
# This script monitors all Docker containers and ensures they are running.
# It performs automatic recovery if containers are down or unhealthy.
# Install as a systemd service for maximum reliability.
# ============================================================================

set -e

# Configuration
LOG_FILE="/var/log/tovplay/docker-watchdog.log"
SLACK_WEBHOOK="${SLACK_WEBHOOK_URL:-}"
CHECK_INTERVAL=30

# Color codes for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Send Slack notification (if configured)
notify_slack() {
    local message=$1
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -s -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🐳 TovPlay Watchdog: $message\"}" \
            "$SLACK_WEBHOOK" > /dev/null 2>&1 || true
    fi
}

# Check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log "ERROR" "Docker daemon is not running!"
        notify_slack "⚠️ CRITICAL: Docker daemon is not running on $(hostname)"

        # Try to start Docker
        systemctl start docker || true
        sleep 5

        if ! docker info > /dev/null 2>&1; then
            log "ERROR" "Failed to start Docker daemon"
            return 1
        fi
        log "INFO" "Docker daemon restarted successfully"
        notify_slack "✅ Docker daemon restarted successfully on $(hostname)"
    fi
    return 0
}

# Get list of expected containers
get_expected_containers() {
    # List containers that should always be running
    local containers=(
        "tovplay-backend-production"
        "tovplay-frontend-production"
        "tovplay-postgres-production"
        "tovplay-prometheus"
        "tovplay-grafana"
        "tovplay-loki"
        "tovplay-promtail"
        "tovplay-alertmanager"
        "tovplay-node-exporter-production"
        "tovplay-cadvisor"
        "tovplay-postgres-exporter"
        "tovplay-blackbox-exporter"
        "nginx-exporter-production"
        "nginx-exporter-staging"
    )
    echo "${containers[@]}"
}

# Check container health and restart if needed
check_container() {
    local container=$1

    # Check if container exists
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
        log "WARNING" "Container $container does not exist"
        return 1
    fi

    # Get container status
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
    local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null)

    case "$status" in
        "running")
            if [ "$health" = "unhealthy" ]; then
                log "WARNING" "Container $container is unhealthy, restarting..."
                notify_slack "⚠️ Container $container is unhealthy, restarting..."
                docker restart "$container"
                sleep 10
                log "INFO" "Container $container restarted"
                notify_slack "✅ Container $container restarted"
            fi
            ;;
        "exited"|"dead"|"created")
            log "WARNING" "Container $container is $status, starting..."
            notify_slack "⚠️ Container $container is $status, starting..."
            docker start "$container"
            sleep 10
            log "INFO" "Container $container started"
            notify_slack "✅ Container $container started"
            ;;
        "paused")
            log "WARNING" "Container $container is paused, unpausing..."
            docker unpause "$container"
            log "INFO" "Container $container unpaused"
            ;;
        "restarting")
            log "INFO" "Container $container is restarting..."
            ;;
        *)
            log "ERROR" "Unknown status for container $container: $status"
            ;;
    esac
}

# Check all compose stacks
check_compose_stacks() {
    local stacks=(
        "/home/admin/tovplay:docker-compose.production.yml"
        "/opt/monitoring:docker-compose.yml"
    )

    for stack in "${stacks[@]}"; do
        local dir="${stack%%:*}"
        local file="${stack##*:}"

        if [ -d "$dir" ] && [ -f "$dir/$file" ]; then
            log "INFO" "Checking compose stack: $dir/$file"
            cd "$dir"
            docker compose -f "$file" up -d --remove-orphans 2>/dev/null || \
            docker-compose -f "$file" up -d --remove-orphans 2>/dev/null || true
        fi
    done
}

# Cleanup old logs (keep last 7 days)
cleanup_logs() {
    find /var/log/tovplay -name "*.log" -mtime +7 -delete 2>/dev/null || true
}

# Main watchdog loop
main() {
    log "INFO" "=== TovPlay Docker Watchdog Started ==="
    notify_slack "🚀 Docker Watchdog started on $(hostname)"

    while true; do
        # Check Docker daemon
        if ! check_docker; then
            sleep "$CHECK_INTERVAL"
            continue
        fi

        # Check compose stacks (this will start any stopped services)
        check_compose_stacks

        # Check individual containers
        for container in $(get_expected_containers); do
            check_container "$container"
        done

        # Cleanup old logs periodically
        if [ "$(date +%H)" = "03" ] && [ "$(date +%M)" -lt "2" ]; then
            cleanup_logs
        fi

        sleep "$CHECK_INTERVAL"
    done
}

# Handle signals
trap 'log "INFO" "Watchdog received SIGTERM, shutting down..."; exit 0' SIGTERM
trap 'log "INFO" "Watchdog received SIGINT, shutting down..."; exit 0' SIGINT

# Run main function
main
