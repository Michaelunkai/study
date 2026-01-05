#!/bin/bash
# ============================================================================
# TOVPLAY BULLETPROOF DEPLOYMENT SCRIPT
# ============================================================================
# This script deploys all configurations to make services bulletproof:
# - Docker daemon config for auto-restart
# - Docker compose with restart: always
# - Watchdog service
# - Firewall rules
# - Nginx configuration
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $1"; }

# Determine server type
detect_server() {
    local ip=$(hostname -I | awk '{print $1}')
    if [[ "$ip" == "193.181.213.220"* ]]; then
        echo "production"
    elif [[ "$ip" == "92.113.144.59"* ]]; then
        echo "staging"
    else
        echo "unknown"
    fi
}

SERVER_TYPE=$(detect_server)
log "Detected server type: $SERVER_TYPE"

# ============================================================================
# 1. Docker Daemon Configuration
# ============================================================================
configure_docker_daemon() {
    log "Configuring Docker daemon..."

    mkdir -p /etc/docker

    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "live-restore": true,
  "storage-driver": "overlay2",
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  },
  "features": {
    "buildkit": true
  },
  "metrics-addr": "0.0.0.0:9323",
  "experimental": false
}
EOF

    log "Docker daemon configured with live-restore enabled"
}

# ============================================================================
# 2. Enable Docker service
# ============================================================================
enable_docker_service() {
    log "Enabling Docker service..."

    systemctl enable docker
    systemctl start docker

    log "Docker service enabled and started"
}

# ============================================================================
# 3. Deploy Watchdog Service
# ============================================================================
deploy_watchdog() {
    log "Deploying watchdog service..."

    mkdir -p /opt/tovplay/scripts
    mkdir -p /var/log/tovplay

    cat > /opt/tovplay/scripts/docker-watchdog.sh << 'WATCHDOG_EOF'
#!/bin/bash
# Docker Watchdog - Ensures all containers stay running
LOG_FILE="/var/log/tovplay/docker-watchdog.log"
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

get_containers() {
    if [ "$SERVER_TYPE" = "production" ]; then
        echo "tovplay-backend-production tovplay-frontend-production tovplay-postgres-production tovplay-prometheus tovplay-grafana tovplay-loki tovplay-promtail tovplay-alertmanager tovplay-node-exporter-production tovplay-cadvisor tovplay-postgres-exporter tovplay-blackbox-exporter"
    else
        echo "tovplay-backend-staging"
    fi
}

check_container() {
    local container=$1
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)

    if [ "$status" != "running" ]; then
        log "Container $container is $status, starting..."
        docker start "$container" 2>/dev/null || true
    fi

    local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container" 2>/dev/null)
    if [ "$health" = "unhealthy" ]; then
        log "Container $container is unhealthy, restarting..."
        docker restart "$container" 2>/dev/null || true
    fi
}

log "=== Watchdog Started ==="
while true; do
    for container in $(get_containers); do
        check_container "$container"
    done
    sleep 30
done
WATCHDOG_EOF

    chmod +x /opt/tovplay/scripts/docker-watchdog.sh

    cat > /etc/systemd/system/tovplay-watchdog.service << 'SERVICE_EOF'
[Unit]
Description=TovPlay Docker Watchdog
After=docker.service
Requires=docker.service

[Service]
Type=simple
ExecStart=/opt/tovplay/scripts/docker-watchdog.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    systemctl daemon-reload
    systemctl enable tovplay-watchdog
    systemctl start tovplay-watchdog

    log "Watchdog service deployed and started"
}

# ============================================================================
# 4. Update Container Restart Policies
# ============================================================================
update_restart_policies() {
    log "Updating container restart policies to 'always'..."

    for container in $(docker ps -a --format '{{.Names}}'); do
        # Skip one-shot containers (frontend-staging is intentionally exit 0)
        if [[ "$container" == *"frontend-staging"* ]]; then
            continue
        fi

        local current_policy=$(docker inspect --format='{{.HostConfig.RestartPolicy.Name}}' "$container" 2>/dev/null)

        if [ "$current_policy" != "always" ]; then
            log "Updating $container from '$current_policy' to 'always'"
            docker update --restart=always "$container" 2>/dev/null || warn "Could not update $container"
        fi
    done

    log "All container restart policies updated"
}

# ============================================================================
# 5. Configure Firewall (UFW)
# ============================================================================
configure_firewall() {
    log "Configuring firewall..."

    # Enable UFW if not already
    ufw --force enable || true

    # Allow SSH
    ufw allow 22/tcp

    # Allow HTTP/HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp

    if [ "$SERVER_TYPE" = "production" ]; then
        # Backend API
        ufw allow 5000/tcp

        # Monitoring
        ufw allow 3002/tcp  # Grafana
        ufw allow 9090/tcp  # Prometheus
        ufw allow 9093/tcp  # Alertmanager
        ufw allow 3100/tcp  # Loki

        # Exporters (limit to internal)
        ufw allow from 127.0.0.1 to any port 9100  # Node exporter
        ufw allow from 127.0.0.1 to any port 8080  # cAdvisor
        ufw allow from 127.0.0.1 to any port 9187  # Postgres exporter
    fi

    if [ "$SERVER_TYPE" = "staging" ]; then
        # Backend API
        ufw allow 8001/tcp
    fi

    ufw reload
    log "Firewall configured"
}

# ============================================================================
# 6. Configure Nginx (for staging)
# ============================================================================
configure_nginx_staging() {
    if [ "$SERVER_TYPE" != "staging" ]; then
        return
    fi

    log "Configuring nginx for staging..."

    # Ensure nginx is installed and enabled
    systemctl enable nginx
    systemctl start nginx

    # Add health check endpoint
    if ! grep -q "nginx_status" /etc/nginx/sites-enabled/default 2>/dev/null; then
        cat >> /etc/nginx/conf.d/status.conf << 'NGINX_EOF'
server {
    listen 127.0.0.1:81;
    location /nginx_status {
        stub_status on;
        allow 127.0.0.1;
        deny all;
    }
}
NGINX_EOF
    fi

    nginx -t && systemctl reload nginx
    log "Nginx configured for staging"
}

# ============================================================================
# 7. Configure Log Rotation
# ============================================================================
configure_log_rotation() {
    log "Configuring log rotation..."

    cat > /etc/logrotate.d/tovplay << 'LOGROTATE_EOF'
/var/log/tovplay/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
}
LOGROTATE_EOF

    log "Log rotation configured"
}

# ============================================================================
# 8. Setup Cron for Health Checks
# ============================================================================
setup_health_cron() {
    log "Setting up health check cron..."

    cat > /etc/cron.d/tovplay-health << 'CRON_EOF'
# TovPlay Health Checks - Every 5 minutes
*/5 * * * * root /opt/tovplay/scripts/health-check.sh >> /var/log/tovplay/health-check.log 2>&1
CRON_EOF

    cat > /opt/tovplay/scripts/health-check.sh << 'HEALTH_EOF'
#!/bin/bash
# Quick health check script

check_url() {
    local url=$1
    local name=$2
    if curl -sf "$url" > /dev/null 2>&1; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $name: OK"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $name: FAILED"
        # Try to recover
        docker restart "$name" 2>/dev/null || true
    fi
}

# Check based on server type
IP=$(hostname -I | awk '{print $1}')
if [[ "$IP" == "193.181.213.220"* ]]; then
    check_url "http://localhost:5000/health" "tovplay-backend-production"
    check_url "http://localhost:80/health.json" "tovplay-frontend-production"
    check_url "http://localhost:9090/-/healthy" "tovplay-prometheus"
    check_url "http://localhost:3002/api/health" "tovplay-grafana"
else
    check_url "http://localhost:8001/health" "tovplay-backend-staging"
fi
HEALTH_EOF

    chmod +x /opt/tovplay/scripts/health-check.sh
    log "Health check cron configured"
}

# ============================================================================
# Main Deployment
# ============================================================================
main() {
    log "=============================================="
    log "TOVPLAY BULLETPROOF DEPLOYMENT"
    log "Server: $SERVER_TYPE"
    log "=============================================="

    configure_docker_daemon
    enable_docker_service
    deploy_watchdog
    update_restart_policies
    configure_firewall
    configure_nginx_staging
    configure_log_rotation
    setup_health_cron

    log "=============================================="
    log "DEPLOYMENT COMPLETE!"
    log "=============================================="
    log "Services are now bulletproof with:"
    log "  ✓ Docker live-restore enabled"
    log "  ✓ All containers set to restart: always"
    log "  ✓ Watchdog service monitoring containers"
    log "  ✓ Health checks running every 5 minutes"
    log "  ✓ Firewall configured"
    log "  ✓ Log rotation enabled"
    log "=============================================="
}

main "$@"
