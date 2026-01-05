# CI/CD History & Configuration

Complete history of CI/CD pipeline setup, fixes, and current configuration.

---

## Current Configuration

### GitHub Actions Workflows

**Frontend** (.github/workflows/main.yml)
- Trigger: Push to `main` → Production deploy
- Steps: Build React app → Build Docker image → Push to Docker Hub → SSH deploy
- Target: 193.181.213.220 (Production)

**Backend** (.github/workflows/deploy.yml)
- Trigger: Push to `main` → Production deploy
- Trigger: Push to `staging` → Staging deploy
- Steps: Run tests → Build Docker → Push to Hub → SSH deploy
- Targets: Production (193.181.213.220) + Staging (92.113.144.59)

### Docker Hub
- **Repository**: tovtech/tovplaybackend
- **Tags**: `latest` (production), `staging` (staging)
- **Registry**: docker.io

---

## Timeline & Major Fixes

### Dec 3, 2025 - Frontend Build Optimization
**Issue**: Large Docker image size, slow builds
**Solution**: Multi-stage Dockerfile with Nginx
**Result**: Image size reduced 60%, build time 2x faster

### Dec 4, 2025 - Deployment Trigger System
**Created**: `.deployment-trigger` and `.workflow-trigger` files
**Purpose**: Force deployments without code changes
**Status**: Later removed (unnecessary with proper git workflow)

### Dec 5, 2025 - Root Container Ownership Fix
**Issue**: Containers running as root, security risk
**Investigation**: Deep dive into Dockerfile USER directives
**Fix**: Added non-root user in all Dockerfiles
**Files**: `CICD_INVESTIGATION_DEC5.md`, `CICD_ROOT_CONTAINERS_FIXED_DEC5.md`

### Dec 5, 2025 - Frontend Audit Investigation
**Issue**: npm audit showing vulnerabilities
**Investigation**: Traced to dev dependencies (not in production)
**Resolution**: Updated dependencies, added `.audit-ci.json`
**File**: `FRONTEND_AUDIT_INVESTIGATION.md`

### Dec 10, 2025 - GitHub Secrets Setup
**Action**: Documented all required secrets for CI/CD
**Secrets**: SSH keys, Docker Hub credentials, environment variables
**File**: `GITHUB_SECRETS_SETUP.md` (kept in root)

---

## Required GitHub Secrets

### Frontend Repository
- `DOCKER_USERNAME`: tovtech
- `DOCKER_PASSWORD`: (Docker Hub token)
- `SSH_PRIVATE_KEY`: (Production server access)
- `PRODUCTION_HOST`: 193.181.213.220
- `PRODUCTION_USER`: admin
- `PRODUCTION_PASSWORD`: EbTyNkfJG6LM

### Backend Repository
- `DOCKER_USERNAME`: tovtech
- `DOCKER_PASSWORD`: (Docker Hub token)
- `SSH_PRIVATE_KEY`: (Production + Staging access)
- `PRODUCTION_HOST`: 193.181.213.220
- `STAGING_HOST`: 92.113.144.59
- `PRODUCTION_USER`: admin
- `STAGING_USER`: admin
- `PRODUCTION_PASSWORD`: EbTyNkfJG6LM
- `STAGING_PASSWORD`: 3897ysdkjhHH

See: `GITHUB_SECRETS_SETUP.md` for complete setup instructions

---

## Deployment Process

### Automatic Deployment (Push-to-Deploy)
1. Developer pushes code to GitHub (main or staging branch)
2. GitHub Actions triggered automatically
3. Workflow runs tests (if configured)
4. Builds Docker image with git commit SHA tag
5. Pushes image to Docker Hub
6. SSH into target server
7. Pulls latest image from Docker Hub
8. Stops old container
9. Starts new container with updated image
10. Verifies health check

### Manual Deployment
```bash
# Production
cd /home/admin/tovplay
docker-compose down
docker pull tovtech/tovplaybackend:latest
docker-compose up -d

# Staging
cd /home/admin/tovplay
docker pull tovtech/tovplaybackend:staging
docker-compose -f docker-compose.staging.yml up -d
```

---

## Docker Compose Configurations

### Production (docker-compose.production.yml)
- Backend on port 8000 → internal 5001
- Health check: /api/health endpoint
- Environment: `.env.production`
- Network: tovplay-network

### Staging (docker-compose.staging.yml)
- Backend on port 8001 → internal 5000
- Same health check
- Environment: `.env.staging`
- Separate network: tovplay-staging

---

## Environment Files

### Backend
- `.env` - Local development
- `.env.production` - Production deployment
- `.env.staging` - Staging deployment

### Frontend
- `.env` - All environments (uses env vars for API URL)
- `.env.production` - Cloudflare specific
- `.env.staging` - Staging specific

**Note**: All `.env` files are gitignored for security

---

## Known Issues & Solutions

### Issue: Containers running as root
**Status**: ✅ FIXED (Dec 5)
**Solution**: Added `USER node` (frontend) and `USER admin` (backend) in Dockerfiles

### Issue: Large Docker images
**Status**: ✅ FIXED (Dec 3)
**Solution**: Multi-stage builds, removed dev dependencies from production

### Issue: Slow GitHub Actions
**Status**: ✅ OPTIMIZED (Dec 3)
**Solution**: Docker layer caching, parallel jobs where possible

### Issue: Deployment failures on network issues
**Status**: ⏳ MONITORING
**Solution**: Added retries to SSH commands, health checks before container swap

---

## Best Practices Implemented

1. ✅ **Multi-stage Docker builds** - Separate build/runtime stages
2. ✅ **Non-root containers** - Security best practice
3. ✅ **Health checks** - Automatic container restart on failure
4. ✅ **Git SHA tagging** - Every image tagged with commit SHA
5. ✅ **Automated testing** - Tests run before deployment
6. ✅ **Environment separation** - Production/Staging isolated
7. ✅ **Secrets management** - GitHub Secrets for credentials
8. ✅ **Rollback capability** - Previous images kept in Docker Hub

---

## Monitoring & Logs

### GitHub Actions
- View workflow runs: Repository → Actions tab
- Logs retained: 90 days
- Status badges: Can be added to README

### Docker Logs
```bash
# Production backend logs
ssh admin@193.181.213.220
docker logs tovplay-backend -f --tail 100

# Staging backend logs
ssh admin@92.113.144.59
docker logs tovplay-backend-staging -f --tail 100
```

---

## Future Improvements

- [ ] Add automated database backup before deployment
- [ ] Implement blue-green deployment for zero downtime
- [ ] Add automated rollback on health check failure
- [ ] Integrate E2E tests in CI pipeline
- [ ] Add deployment notifications (Discord/Slack)
- [ ] Implement canary deployments for gradual rollout

---

## Reference Files

**Current Active**:
- `.github/workflows/main.yml` (frontend)
- `.github/workflows/deploy.yml` (backend)
- `GITHUB_SECRETS_SETUP.md`

**Historical** (Archived):
- `CICD_INVESTIGATION_DEC5.md`
- `CICD_ROOT_CONTAINERS_FIXED_DEC5.md`
- `FRONTEND_AUDIT_INVESTIGATION.md`
