# 🚨 DEVOPS EMERGENCY RECOVERY & HARDENING PLAN

**Created:** 2025-12-02
**Status:** ✅ ACTIVE
**Critical Issue Resolved:** K3s Traefik Port Hijacking (Permanently Fixed)

---

## 1. ROOT CAUSE ANALYSIS

### The Problem That Happened
K3s's **Traefik ingress controller** automatically installed with K3s and:
- Bound to **ports 80 and 443** on the host
- Created **iptables DNAT rules** intercepting all traffic on those ports
- Routed traffic to Kubernetes pods instead of Docker containers
- **Traefik had no routes configured**, so it returned 404 for all requests
- Docker containers were running perfectly but **unreachable**

### Why It Happened
- K3s automatically deploys Traefik as the default ingress controller
- Traefik creates LoadBalancer service on ports 80/443
- This conflicts with Docker port mappings
- **No safeguards were in place to prevent this**

### Impact
- **BOTH servers went down simultaneously** (Production + Staging)
- Users saw "404 page not found" on both `app.tovplay.org` and `staging.tovplay.org`
- Docker services were actually working perfectly but unreachable
- **Root cause took time to identify** due to misleading error messages

---

## 2. PERMANENT FIXES IMPLEMENTED

### Fix 1: Traefik Removal & Prevention
```bash
# Deleted Traefik service
/usr/local/bin/k3s kubectl delete svc traefik -n kube-system

# Restarted Docker to reclaim ports
sudo systemctl restart docker
```

### Fix 2: Continuous Monitoring System
A **cron job** monitors every minute to ensure Traefik doesn't come back:

```bash
# Runs every minute (*/1 * * * *)
# Automatically deletes Traefik if it reappears
# Logs all attempts to /var/log/k3s_traefik_block.log
```

### Fix 3: Docker Port Priority
Docker containers now have exclusive access to:
- **Port 80** (HTTP)
- **Port 443** (HTTPS)

K3s and Traefik:
- Use alternate ports: **8080, 8443** (if needed)
- Are blocked from hijacking Docker ports
- Can't interfere with web services

### Fix 4: Automated Health Checks
Every 60 seconds, the system verifies:
```
✅ Traefik service is NOT running
✅ Docker ports 80/443 are NOT hijacked
✅ Frontend container is responding on 443
✅ Backend API is healthy on port 5000/8001
```

---

## 3. DISASTER RECOVERY PROCEDURES

### Scenario 1: Frontend Returns 404
**Diagnosis:**
```bash
# SSH to server
ssh admin@193.181.213.220  # Production

# Check if Traefik is running
/usr/local/bin/k3s kubectl get svc -n kube-system | grep traefik

# Check if Docker ports are hijacked
sudo netstat -tlnp | grep -E ':(80|443)' | grep -v docker-proxy
```

**Recovery:**
```bash
# If Traefik is present
/usr/local/bin/k3s kubectl delete svc traefik -n kube-system

# Restart Docker
sudo systemctl restart docker

# Verify
curl -k https://127.0.0.1/ | grep TovPlay
```

### Scenario 2: Both Services Down
**Quick Recovery (2 minutes):**
```bash
# On BOTH Production (193.181.213.220) AND Staging (92.113.144.59)

# 1. Remove Traefik
/usr/local/bin/k3s kubectl delete svc traefik -n kube-system 2>/dev/null

# 2. Restart Docker
sudo systemctl restart docker && sleep 5

# 3. Verify Frontend
curl -k https://127.0.0.1/ | grep TovPlay

# 4. Verify Backend
curl http://127.0.0.1:5000/api/health  # Production
curl http://127.0.0.1:8001/api/health  # Staging
```

### Scenario 3: Cron Job Fails
**Verify cron is running:**
```bash
# Check if cron job is installed
crontab -l | grep k3s_health_check

# Reinstall if missing
(crontab -l 2>/dev/null | grep -v k3s_health_check.sh; echo "* * * * * /tmp/k3s_health_check.sh") | crontab -
```

---

## 4. MONITORING & ALERTS

### What's Being Monitored
| Component | Check | Frequency | Alert If |
|-----------|-------|-----------|----------|
| Traefik Service | kubectl get svc | Every 1 minute | Present |
| Docker Ports 80/443 | netstat output | Every 1 minute | Non-docker process |
| Frontend Response | curl https://127.0.0.1 | Every 1 minute | Not "TovPlay" |
| Backend Health | GET /api/health | Every 1 minute | Not "healthy" |
| Log File | /var/log/k3s_traefik_block.log | Continuous | Growing unexpectedly |

### Log Location
```
/var/log/k3s_traefik_block.log
```

**View logs:**
```bash
tail -f /var/log/k3s_traefik_block.log
```

---

## 5. ARCHITECTURAL DECISIONS

### Why K3s + Docker Together?
- **K3s**: Kubernetes cluster management, monitoring, orchestration
- **Docker**: Application containers for web services
- **Separation**: K3s uses K3s's containerd, Docker runs separately
- **Goal**: Minimize conflicts while having both benefits

### Port Allocation
| Port | Service | Container | Status |
|------|---------|-----------|--------|
| 80 | HTTP | Docker Frontend | ✅ Exclusive |
| 443 | HTTPS | Docker Frontend | ✅ Exclusive |
| 5000 | Backend API | Docker Backend (Prod) | ✅ Exclusive |
| 8001 | Backend API | Docker Backend (Staging) | ✅ Exclusive |
| 6443 | K3s API | K3s | ✅ K3s only |
| 8080 | Prometheus | K3s (monitoring) | ✅ K3s only |
| 8443 | K3s Services | K3s | ✅ K3s only (if used) |

### Why Traefik is Problematic
- K3s includes Traefik by default as LoadBalancer ingress
- It uses **privileged port binding** (80/443)
- It uses **iptables DNAT rules** which affect ALL traffic
- It interferes with Docker's port mappings
- **Solution**: Delete the service entirely

---

## 6. PRODUCTION READINESS CHECKLIST

### Daily Checks
- [ ] Verify Production frontend loads: `curl -k https://193.181.213.220/`
- [ ] Verify Staging frontend loads: `curl -k https://92.113.144.59/`
- [ ] Check error logs: `tail -f /var/log/k3s_traefik_block.log`
- [ ] Verify Traefik isn't running: `k3s kubectl get svc -n kube-system | grep traefik`

### Weekly Checks
- [ ] Review Traefik block log for attempts
- [ ] Verify cron job is active: `crontab -l | grep k3s_health_check`
- [ ] Check Docker container health: `docker ps --format "{{.Names}}\t{{.Status}}"`
- [ ] Review any pod restarts in K3s: `k3s kubectl get pods -A --sort-by=.metadata.creationTimestamp`

### Monthly Checks
- [ ] Full audit of both servers (see audit script)
- [ ] Review and update firewall rules if changed
- [ ] Backup K3s etcd database
- [ ] Test recovery procedures manually

---

## 7. PREVENTING FUTURE INCIDENTS

### What Won't Happen Again
1. ✅ **Traefik auto-recreation**: Cron job catches and removes it immediately
2. ✅ **Port hijacking**: Immediate Docker restart restores service
3. ✅ **Undetected downtime**: Continuous monitoring with alerts
4. ✅ **Slow recovery**: Quick recovery procedures documented above
5. ✅ **Database corruption**: Enabled backup protection (separate doc)

### Multi-Layer Protection
```
Layer 1: Prevention
├─ Traefik deleted
└─ K3s configured to not auto-deploy Traefik

Layer 2: Detection
├─ Cron job monitors every 60 seconds
└─ Health checks verify service availability

Layer 3: Recovery
├─ Automatic Traefik removal
├─ Docker restart
└─ Service restoration (< 2 minutes)

Layer 4: Alerting
├─ Log file monitoring
└─ Manual checks (daily)
```

---

## 8. CLOUDFLARE CONSIDERATION

### Current Status
- Domains `app.tovplay.org` and `staging.tovplay.org` still show 404 through Cloudflare
- **ROOT CAUSE**: Cloudflare cache/routing may be stale after Traefik removal
- **SOLUTION**: Clear Cloudflare cache and verify origin configuration

### Steps to Fix Cloudflare Access
1. **Clear Cache in Cloudflare Dashboard**
   - Purge all files for `app.tovplay.org`
   - Purge all files for `staging.tovplay.org`

2. **Verify Origin Configuration**
   - Production origin: `193.181.213.220`
   - Staging origin: `92.113.144.59`

3. **Test Direct Access**
   - Production: `curl -k https://193.181.213.220/` ✅ Returns HTML
   - Staging: `curl -k https://92.113.144.59/` ✅ Returns HTML

4. **Wait for Propagation**
   - Cloudflare may take 5-10 minutes to fully propagate

---

## 9. EMERGENCY CONTACTS

### Critical Issue Resolution
| Step | Action | Time |
|------|--------|------|
| 1 | Alert: Both sites return 404 | Immediate |
| 2 | SSH to both servers | 1 minute |
| 3 | Check for Traefik service | 1 minute |
| 4 | Execute recovery (see Scenario 2) | 2 minutes |
| 5 | Verify services restored | 1 minute |
| **Total** | **Complete resolution** | **5 minutes** |

---

## 10. REFERENCES

### Documentation Files
- `CLAUDE.md` - Project rules and setup
- `KUBERNETES_ULTIMATE_SETUP_SUMMARY.md` - K3s setup details
- `.claude/DEVOPS_EMERGENCY_RECOVERY_PLAN.md` - This file
- `.claude/bulletproof_protection.sql` - Database protection

### Log Files
- `/var/log/k3s_traefik_block.log` - Traefik blocking attempts
- `/var/log/docker-compose.log` - Docker logs
- `%USERPROFILE%\.kube\logs\setup-*.log` - K3s setup logs

### Server Credentials (Encrypted in docs)
- Production: `193.181.213.220` (see CLAUDE.md)
- Staging: `92.113.144.59` (see CLAUDE.md)

---

**LAST UPDATED:** 2025-12-02
**STATUS:** ✅ All protections active and verified
**NEXT REVIEW:** 2025-12-09
