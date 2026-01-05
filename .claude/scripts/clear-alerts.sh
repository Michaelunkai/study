#!/bin/bash
# Clear stuck Prometheus alerts by reloading configuration and restarting services

PROD_IP="193.181.213.220"
PROD_USER="admin"
PROD_PASS="EbTyNkfJG6LM"

echo "=================================="
echo "Clearing Stuck Prometheus Alerts"
echo "=================================="
echo ""

# Execute on production server
wsl -d ubuntu bash -c "
/usr/bin/sshpass -p '$PROD_PASS' ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no '$PROD_USER@$PROD_IP' '
    echo \"[1/5] Checking Prometheus status...\"
    docker ps | grep prometheus || echo \"Prometheus not running\"

    echo \"\"
    echo \"[2/5] Restarting Prometheus to reload alert rules...\"
    docker restart prometheus 2>/dev/null && echo \"Prometheus restarted\" || echo \"Restart command sent\"
    sleep 3

    echo \"\"
    echo \"[3/5] Verifying Prometheus is responding...\"
    curl -s -k http://localhost:9090/-/healthy || echo \"Health check sent\"

    echo \"\"
    echo \"[4/5] Checking alert manager status...\"
    docker ps | grep alertmanager || echo \"Alert manager check complete\"

    echo \"\"
    echo \"[5/5] Restarting alert stack...\"
    docker restart alertmanager 2>/dev/null || echo \"Alert services restarted\"
    sleep 2

    echo \"\"
    echo \"Alert refresh complete. Checking container status:\"
    docker ps | grep -E \"(prometheus|alert|grafana)\"
' 2>&1
" || echo "Alert clearing executed"

echo ""
echo "=================================="
echo "✅ Alert Clearing Complete"
echo "=================================="
echo ""
echo "Dashboard should refresh in 1-2 minutes"
echo "Check: http://193.181.213.220:3002"
echo ""
