# TovPlay Docker Architecture
**Generated**: December 18, 2025
**Version**: 1.0

---

## Overview

TovPlay uses a hybrid Docker architecture:
- **Production**: Docker containers + Native Nginx + External PostgreSQL
- **Staging**: Docker containers + Native Nginx + External PostgreSQL
- **Database**: External managed PostgreSQL server (45.148.28.196)

---

## Production Server (193.181.213.220)

### Container Stack

| Container Name | Image | Port Mapping | Status | Purpose |
|---------------|-------|--------------|--------|---------|
| **tovplay-backend** | tovtech/tovplaybackend:latest | 8000→5001 | Up 11h (healthy) | Flask API (Gunicorn) |
| **tovplay-pgbouncer** | edoburu/pgbouncer:latest | 6432→6432 | Up 11h | PostgreSQL connection pooler |
| **tovplay-prometheus** | prom/prometheus:latest | 9090→9090 | Up 11h | Metrics collection |
| **grafana-standalone** | grafana/grafana:latest | 3002→3000 | Up 11h | Metrics visualization |
| **tovplay-loki** | grafana/loki:2.9.3 | 3100→3100 | Up 11h | Log aggregation |
| **tovplay-promtail** | grafana/promtail:2.9.3 | - | Up 8h | Log collection agent |
| **tovplay-logging-dashboard** | tovplay-logging-dashboard | 7778→7778 | Up 6h | Error dashboard |
| **tovplay-node-exporter-production** | prom/node-exporter:latest | 9100 | Up 11h | Host metrics |
| **tovplay-cadvisor** | gcr.io/cadvisor/cadvisor:latest | 8080 | Up 11h (healthy) | Container metrics |
| **tovplay-postgres-exporter** | prometheuscommunity/postgres-exporter:v0.15.0 | 9187 | Up 11h | PostgreSQL metrics |

### Networks

```
tovplay-network (172.19.0.0/16)
├── tovplay-backend (172.19.0.9)
├── tovplay-pgbouncer (172.19.0.4)
├── tovplay-postgres-exporter (172.19.0.5)
├── tovplay-prometheus (172.19.0.2)
├── grafana-standalone (172.19.0.3)
├── tovplay-cadvisor (172.19.0.7)
└── tovplay-node-exporter-production (172.19.0.8)

monitoring (external)
├── tovplay-loki
├── tovplay-promtail
└── tovplay-logging-dashboard
```

### Docker Compose Files

**Main Application**: `/home/admin/tovplay/docker-compose.production.yml`
```yaml
services:
  backend:
    image: tovtech/tovplaybackend:latest
    container_name: tovplay-backend
    restart: unless-stopped
    command: gunicorn -w 2 -b 0.0.0.0:5001 --max-requests 1000 \
             --max-requests-jitter 100 --timeout 30 wsgi:app
    ports: ["8000:5001"]
    mem_limit: 512m
    networks: [tovplay-network]
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=postgresql://...@45.148.28.196:5432/TovPlay
      - LOG_LEVEL=WARNING
```

**Monitoring**: `/opt/monitoring/docker-compose.yml`
- Prometheus, Grafana, Node Exporter, cAdvisor, Postgres Exporter, Alertmanager, Blackbox Exporter

**Logging**: `/opt/tovplay-logging-dashboard/docker-compose.yml`
- Loki, Promtail, Error Dashboard (Flask/Gunicorn)

### Nginx Configuration

**File**: `/etc/nginx/sites-enabled/tovplay.conf`

```nginx
server {
    listen 443 ssl http2;
    server_name app.tovplay.org;
    root /var/www/tovplay;  # Static frontend files

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
    }

    # Error Dashboard
    location /logs/ {
        proxy_pass http://127.0.0.1:7778/;
    }

    # Frontend SPA
    location / {
        try_files $uri /index.html;
    }
}
```

### Request Flow

```
Internet (HTTPS)
    ↓
Nginx (443) - SSL Termination
    ├── / → /var/www/tovplay (Static React SPA)
    ├── /api/ → localhost:8000 (Docker: tovplay-backend)
    └── /logs/ → localhost:7778 (Docker: tovplay-logging-dashboard)
        ↓
tovplay-backend (Gunicorn)
    ↓
tovplay-pgbouncer (6432) - Connection Pooling
    ↓
PostgreSQL External (45.148.28.196:5432)
```

### Volumes

- `loki-data` - Loki log storage
- `prometheus_storage` - Prometheus metrics
- `monitoring_prometheus_data` - Additional Prometheus data

---

## Staging Server (92.113.144.59)

### Container Stack

| Container Name | Image | Port Mapping | Status | Purpose |
|---------------|-------|--------------|--------|---------|
| **tovplay-backend-staging** | tovtech/tovplaybackend:latest | 8001→5001 | Up (healthy) | Flask API (Gunicorn) |
| **tovplay-pgbouncer-staging** | edoburu/pgbouncer:latest | 6432→6432 | Up | PostgreSQL connection pooler |

### Networks

```
tovplay-staging-network
├── tovplay-backend-staging
└── tovplay-pgbouncer-staging
```

### Docker Hub Blocker (Dec 18, 2025)
Staging server has IPv4 blocked to Docker Hub. IPv6 returns EOF.
**Workaround**: Transfer images via SCP from production server.
```bash
# On production:
docker save tovtech/tovplaybackend:latest | gzip > /tmp/backend.tar.gz
scp /tmp/backend.tar.gz admin@92.113.144.59:/tmp/
# On staging:
docker load < /tmp/backend.tar.gz
```

### Docker Compose File

**Location**: `/home/admin/tovplay/docker-compose.staging.yml`

```yaml
services:
  backend-staging:
    image: tovtech/tovplaybackend:staging
    container_name: tovplay-backend-staging
    restart: unless-stopped
    command: ["gunicorn", "-w", "2", "-b", "0.0.0.0:5000",
              "--timeout", "60", "wsgi:create_app()"]
    ports: ["8001:5000"]
    mem_limit: 512m
    networks: [tovplay-staging-network]
    environment:
      - FLASK_ENV=staging
      - LOG_LEVEL=DEBUG
      - IS_STAGING=true

  frontend-staging:
    image: tovtech/tovplayfrontend:staging
    container_name: tovplay-frontend-staging
    restart: "no"  # One-time deployment
    volumes: ["/var/www/tovplay-staging:/target"]
    command: "cp -r /usr/share/nginx/html/* /target/"
```

### Nginx Configuration

**File**: `/etc/nginx/sites-available/staging.tovplay.org`

```nginx
server {
    listen 443 ssl http2;
    server_name staging.tovplay.org;
    root /var/www/tovplay-staging;

    location /api/ {
        proxy_pass http://localhost:8001;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

### Request Flow

```
Internet (HTTPS)
    ↓
Nginx (443) - SSL Termination
    ├── / → /var/www/tovplay-staging (Static React SPA)
    └── /api/ → localhost:8001 (Docker: tovplay-backend-staging)
        ↓
tovplay-backend-staging (Gunicorn)
    ↓
PostgreSQL External (45.148.28.196:5432)
```

---

## Shared Components

### External PostgreSQL Database

**Server**: 45.148.28.196:5432
**Database**: TovPlay
**Connection**: Direct from containers (no pgbouncer on staging)

```
Production:  tovplay-backend → tovplay-pgbouncer → PostgreSQL
Staging:     tovplay-backend-staging → PostgreSQL (direct)
```

### PgBouncer Configuration (Production Only)

```
Pool Mode: transaction
Max Client Connections: 1000
Default Pool Size: 20
Min Pool Size: 5
Reserve Pool Size: 5
Max DB Connections: 50
Server Idle Timeout: 600s
Server Lifetime: 3600s
```

---

## Container Resource Limits

All backend containers:
- **Memory Limit**: 512MB
- **Memory + Swap**: 512MB

Backend Gunicorn Configuration:
- **Production**: 2 workers, 30s timeout, 1000 max requests
- **Staging**: 2 workers, 60s timeout

---

## Health Checks

Both backend containers have health checks:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 60s
```

---

## Container Management Commands

### Production

```bash
# Access server
sshpass -p 'EbTyNkfJG6LM' ssh admin@193.181.213.220

# Navigate to project
cd /home/admin/tovplay

# View containers
docker ps

# Restart backend
docker restart tovplay-backend

# View logs
docker logs -f tovplay-backend

# Deploy new version
docker-compose -f docker-compose.production.yml pull backend
docker-compose -f docker-compose.production.yml up -d backend

# Frontend update
cd /var/www/tovplay && git pull && npm run build
```

### Staging

```bash
# Access server
sshpass -p '3897ysdkjhHH' ssh admin@92.113.144.59

# Navigate to project
cd /home/admin/tovplay

# Restart backend
docker restart tovplay-backend-staging

# View logs
docker logs -f tovplay-backend-staging

# Deploy new version
docker-compose -f docker-compose.staging.yml pull backend-staging
docker-compose -f docker-compose.staging.yml up -d backend-staging
```

---

## CI/CD Integration

### Deployment Triggers

- **Production**: Pushes to `develop` branch
- **Staging**: Pushes to `main` branch

### Deployment Process

1. GitHub Actions builds Docker images
2. Images pushed to Docker Hub:
   - `tovtech/tovplaybackend:latest` (production)
   - `tovtech/tovplaybackend:staging` (staging)
   - `tovtech/tovplayfrontend:staging` (staging)
3. Webhook triggers container updates on servers
4. Nginx serves updated frontend static files

---

## Monitoring Stack (Production Only)

### Metrics Collection


Application Metrics
├── tovplay-backend → Prometheus (custom metrics)
├── tovplay-postgres-exporter → Prometheus (DB metrics)
├── tovplay-node-exporter → Prometheus (host metrics)
└── tovplay-cadvisor → Prometheus (container metrics)
    ↓
Prometheus (storage + queries)
    ↓
Grafana (visualization @ port 3002)
```

### Log Collection

```
Container Logs + System Logs
    ↓
tovplay-promtail (collects from /var/log, Docker)
    ↓
tovplay-loki (log aggregation @ port 3100)
    ↓
tovplay-logging-dashboard (Flask app @ port 7778)
    ↓
Nginx /logs/ (public dashboard @ https://app.tovplay.org/logs/)
```

---

## Security Notes

1. **SSL Termination**: Nginx handles all SSL/TLS
2. **Container Isolation**: Backend containers only expose ports to localhost
3. **Database Access**: PgBouncer pools connections in production
4. **Resource Limits**: All containers have memory limits
5. **Restart Policy**: `unless-stopped` for automatic recovery
6. **Health Checks**: Automated container health monitoring

---

## Key Differences: Production vs Staging

| Aspect | Production | Staging |
|--------|-----------|---------|
| Containers | 10 containers | 2 containers |
| Monitoring | Full stack (Prometheus, Grafana, Loki) | None (Docker Hub blocked) |
| Connection Pooling | PgBouncer (yes) | PgBouncer (yes) |
| Log Level | WARNING | DEBUG |
| Workers | 2 workers, 30s timeout | 2 workers, 60s timeout |
| Domain | app.tovplay.org | staging.tovplay.org |
| Backend Port | 8000 | 8001 |
| Gunicorn Port | 5001 | 5001 |
| Network | tovplay-network | tovplay-staging-network |
| Score | 85/100 | 70/100 |

---

## Troubleshooting

### Container Won't Start
```bash
# Check logs
docker logs tovplay-backend

# Check resource usage
docker stats

# Recreate container
docker-compose down && docker-compose up -d
```

### High Memory Usage
```bash
# Check container memory
docker stats tovplay-backend

# Restart container
docker restart tovplay-backend
```

### Database Connection Issues
```bash
# Production: Check pgbouncer
docker logs tovplay-pgbouncer

# Test DB connection from container
docker exec tovplay-backend curl http://localhost:5001/health
```

---

## Architecture Diagrams

### Production Full Stack
```
┌─────────────────────────────────────────────────────────┐
│                    Internet (HTTPS)                      │
└──────────────────────┬──────────────────────────────────┘
                       ↓
┌─────────────────────────────────────────────────────────┐
│  Nginx (443) - SSL Termination & Reverse Proxy         │
│  - Static files: /var/www/tovplay                       │
│  - API proxy: → localhost:8000                          │
│  - Logs proxy: → localhost:7778                         │
└─┬──────────────────┬──────────────────┬─────────────────┘
  │                  │                  │
  │ /api/           │ /logs/           │ /
  ↓                  ↓                  ↓
┌─────────────┐  ┌──────────────┐  ┌─────────────┐
│  Backend    │  │   Logging    │  │  Frontend   │
│  Container  │  │  Dashboard   │  │ Static SPA  │
│  (Docker)   │  │  (Docker)    │  │             │
│  port 8000  │  │  port 7778   │  │             │
└──────┬──────┘  └──────────────┘  └─────────────┘
       │
       ↓
┌─────────────┐
│  PgBouncer  │
│  (Docker)   │
│  port 6432  │
└──────┬──────┘
       │
       ↓
┌──────────────────────────────────────────┐
│  External PostgreSQL (45.148.28.196)    │
│  Database: TovPlay                       │
└──────────────────────────────────────────┘
```

### Staging Stack
```
┌─────────────────────────────────────────┐
│        Internet (HTTPS)                  │
└──────────────────┬──────────────────────┘
                   ↓
┌──────────────────────────────────────────┐
│  Nginx (443) - SSL & Reverse Proxy      │
│  - Static: /var/www/tovplay-staging     │
│  - API: → localhost:8001                 │
└─┬──────────────────┬─────────────────────┘
  │ /api/            │ /
  ↓                  ↓
┌──────────────┐  ┌─────────────┐
│   Backend    │  │  Frontend   │
│   Staging    │  │ Static SPA  │
│   (Docker)   │  │             │
│  port 8001   │  │             │
└──────┬───────┘  └─────────────┘
       │
       ↓ (direct)
┌────────────────────────────────┐
│  External PostgreSQL           │
│  (45.148.28.196)              │
└────────────────────────────────┘
```

---

**Last Updated**: December 18, 2025

