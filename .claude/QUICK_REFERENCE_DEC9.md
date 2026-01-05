# TovPlay Dashboard - Quick Reference Guide
**Last Updated**: December 9, 2025 11:45 UTC

---

## Quick Links

| Resource | Link |
|----------|------|
| **Production Dashboard** | https://app.tovplay.org/logs/ |
| **API Health Check** | http://localhost:7778/api/health |
| **Internal Port** | http://193.181.213.220:7778 |
| **Docker Container** | tovplay-logging-dashboard |
| **Dashboard File** | F:\tovplay\logging-dashboard\templates\index.html |

---

## Quick Status Check

### Check If Dashboard Is Up
```bash
curl http://localhost:7778/api/health
```
✅ Expected: `{"status": "healthy", "loki_connected": true}`

### Check Container Status
```bash
docker ps | grep logging-dashboard
```
✅ Expected: Container should show "Up"

### View Recent Logs
```bash
docker logs tovplay-logging-dashboard | tail -20
```

---

## Filter Quick Reference

### Time Filters (7 options)
- Last 1m (1 minute)
- Last 5m (5 minutes)
- Last 15m (15 minutes)
- Last 1h (1 hour)
- Last 6h (6 hours)
- Last 24h (24 hours) - **DEFAULT**
- Last 7d (7 days)

### Source Filters (7 options)
- All (all sources)
- Errors (error logs)
- GitHub (GitHub activity)
- Docker (Docker logs)
- Nginx (Nginx logs)
- Auth (Authentication logs)
- Database (Database logs)

### Error Type Filters (10 options)
- Prod SSH Errors
- Staging SSH Errors
- DB Errors
- DB SSH Errors
- Frontend Repo Issues
- Backend Repo Issues
- CI/CD Errors
- Staging (main) Issues
- Production (develop) Issues
- Code Issues

### Team Member Filters (7 options)
- All Members (default)
- IrronRoman19
- Michaelunkai
- Yuvalzeyger
- avi12
- lilachHerzog

---

## Common Filter Combinations

### Scenario 1: Find Docker Errors from Last 5 Minutes
1. Click "Docker" (source filter)
2. Click "Errors" (error type filter)
3. Click "Last 5m" (time filter)
4. **Result**: Only Docker container errors from last 5 minutes

### Scenario 2: Check Team Member Activity
1. Click team member name (e.g., "avi12")
2. Keep all other filters at defaults
3. **Result**: All activity by that team member

### Scenario 3: Find CI/CD Issues in Last 7 Days
1. Click "CI/CD Errors" (error type filter)
2. Click "Last 7d" (time filter)
3. **Result**: All CI/CD failures from past 7 days

### Scenario 4: Monitor Production Deployment
1. Click "Production (develop) Issues" (error type filter)
2. Click "Last 1h" (time filter)
3. **Result**: Recent production deployment issues

---

## File Locations

### Local Files
```
F:\tovplay\logging-dashboard\templates\index.html    (Main dashboard)
F:\tovplay\.claude\learned.md                         (Lessons & patterns)
F:\tovplay\.claude\MASTER_STATUS_DEC9_2025.md        (Full status report)
```

### Production Files (in Docker)
```
/app/templates/index.html                            (Dashboard in container)
/opt/tovplay-dashboard/app.py                        (Flask backend)
```

---

## Troubleshooting

### Dashboard Not Loading
1. Check container: `docker ps | grep logging-dashboard`
2. Check API: `curl http://localhost:7778/api/health`
3. Check logs: `docker logs tovplay-logging-dashboard`

### Filters Not Working
1. Check browser console for errors (F12)
2. Check API returns data: `curl http://localhost:7778/api/logs/recent?timeframe=24h`
3. Check filter logic in renderLogs() function

### No Logs Showing
1. Check Loki connection: `docker exec tovplay-logging-dashboard curl http://localhost:3100/ready`
2. Verify Loki is running and has data
3. Check API returns log streams

### Button Styling Broken
1. Clear browser cache (Ctrl+Shift+Delete)
2. Hard refresh (Ctrl+F5)
3. Check CSS variables in index.html

---

## Performance Tips

✅ **What's Fast**:
- Filter combinations (instant)
- API responses (<500ms)
- Page load (<2 seconds)
- Button clicks (no lag)

⚠️ **Monitor These**:
- Container memory usage
- Loki disk space
- Log volume growth
- API response times

---

## Button Reference

### All 39+ Buttons Are Styled Identically
```
Default State:
  Background: Dark (--bg-tertiary)
  Border: Gray (--border-color)
  Text: Light (--text-primary)

Hover State:
  Border: Blue (--accent-blue)
  Text: Blue (--accent-blue)
  Effect: Slightly lifted (-1px)

Active State:
  Background: Blue (--accent-blue)
  Text: White
  Effect: Glow shadow effect
```

---

## API Endpoints Quick List

```
GET /                           → Dashboard page
GET /api/health                 → Health status
GET /api/logs/recent            → Recent logs with timeframe
GET /api/logs/errors            → Error logs
GET /api/logs/github            → GitHub events
GET /api/logs/deployments       → Deployment logs
GET /api/logs/auth              → Auth logs
GET /api/logs/database          → Database logs
GET /api/logs/search?q=TERM     → Search logs
GET /api/logs/team-activity     → Team member activity
GET /api/stats                  → Statistics
POST /webhook/github            → GitHub webhooks
```

---

## Database Connection

```
Server:   45.148.28.196:5432
Database: database
User:     raz@tovtech.org
Password: CaptainForgotCreatureBreak
```

**Note**: Database name is `database` NOT `TovPlay`

---

## Quick Test Commands

### Test Dashboard Access
```bash
curl -I https://app.tovplay.org/logs/
```
Expected: HTTP 200 OK

### Test API
```bash
curl http://localhost:7778/api/health | python3 -m json.tool
```
Expected: `{"status": "healthy", "loki_connected": true}`

### Test Filter
```bash
curl 'http://localhost:7778/api/logs/recent?timeframe=1h' | python3 -m json.tool | head -50
```
Expected: JSON with log categories

---

## Key Statistics (As of 11:41 UTC)

| Metric | Value |
|--------|-------|
| Errors (24h) | 3.7K |
| Requests (24h) | 5.4K |
| Nginx Streams | 12 |
| GitHub Streams | 1 |
| Auth Streams | 1 |
| Container Uptime | ~1 hour |
| API Response Time | <500ms |
| Dashboard Load Time | <2 seconds |

---

## Emergency Procedures

### Restart Container
```bash
docker restart tovplay-logging-dashboard
```

### Restart from Scratch
```bash
docker stop tovplay-logging-dashboard
docker rm tovplay-logging-dashboard
docker run -d --name tovplay-logging-dashboard \
  --restart unless-stopped \
  -p 7778:7778 \
  -e LOKI_URL=http://localhost:3100 \
  tovplay-logging-dashboard:latest
```

### View Recent Errors
```bash
docker logs tovplay-logging-dashboard | grep -i error | tail -10
```

### Check Disk Space
```bash
docker exec tovplay-logging-dashboard df -h
```

---

## Documentation Reference

| Document | Purpose | Read When |
|----------|---------|-----------|
| `MASTER_STATUS_DEC9_2025.md` | Complete system overview | Need full picture |
| `SESSION_COMPLETE_DEC9_2025.md` | Session completion report | Verify work done |
| `PRODUCTION_STATUS_CONTINUOUS_DEC9.md` | Current operational status | Check dashboard health |
| `QUICK_REFERENCE_DEC9.md` | This file | Need quick answers |
| `learned.md` | Patterns & lessons | Understand how system works |

---

## Contact Information

**Team Members**:
- IrronRoman19 - roman.fesunenko@gmail.com
- Michaelunkai
- Yuvalzeyger
- avi12
- lilachHerzog

**System Owner**: TovPlay Team

---

## Status Summary

🟢 **System Status**: OPERATIONAL
✅ **Last Check**: 2025-12-09 11:41 UTC
✅ **All Filters**: WORKING
✅ **All Buttons**: STYLED
✅ **All Endpoints**: RESPONDING
✅ **No Critical Issues**: CONFIRMED

**Next Action**: Await user instructions or monitor for issues

---

**Quick Reference Guide v1.0**
**Last Updated**: December 9, 2025 11:45 UTC

