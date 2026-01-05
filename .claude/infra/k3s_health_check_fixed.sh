#!/bin/bash
LOG_FILE="/var/log/k3s_traefik_block.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

log_entry() {
    echo "[$TIMESTAMP] $1" >> $LOG_FILE
}

if /usr/local/bin/k3s kubectl get svc -n kube-system 2>/dev/null | grep -q traefik; then
    log_entry "ALERT: Traefik service detected! Removing..."
    /usr/local/bin/k3s kubectl delete svc traefik -n kube-system 2>/dev/null
    log_entry "ACTION: Traefik service deleted"
fi

# Check for port hijacking - EXCLUDE nginx which legitimately uses 80/443
HIJACKED=$(sudo netstat -tlnp 2>/dev/null | grep -E ':(80|443)' | grep -v docker-proxy | grep -v nginx)
if [ ! -z "$HIJACKED" ]; then
    log_entry "ALERT: Port hijacking detected"
    sudo iptables -t nat -F 2>/dev/null
    sudo iptables -t nat -X 2>/dev/null
    sudo systemctl restart docker 2>/dev/null
    log_entry "ACTION: Docker restarted"
fi

FRONTEND_TEST=$(curl -sk https://127.0.0.1/ 2>/dev/null | grep -c TovPlay)
if [ "$FRONTEND_TEST" -eq 0 ]; then
    log_entry "ALERT: Frontend not responding"
else
    log_entry "OK: Frontend responding"
fi
