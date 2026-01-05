# CI/CD Setup and Troubleshooting Guide

## Current Status

### ✅ Working Components
- **Production Backend**: Running and healthy with correct database connection
- **Production Frontend**: Running (container-based deployment)
- **Staging Backend**: Running and healthy
- **Staging Frontend**: Static file deployment to `/var/www/tovplay-staging/`
- **Login**: Both production and staging successfully authenticate users

### ⚠️ CI/CD Issue Identified

The GitHub Actions workflows push failed because the `DOCKERHUB_TOKEN` secret is not configured in the repository settings.

## Required GitHub Secrets

Both frontend and backend repos need these secrets configured:

1. **DOCKERHUB_TOKEN**
   - Go to: Repository Settings > Secrets and variables > Actions
   - Create new secret: `DOCKERHUB_TOKEN`
   - Value: Docker Hub access token for `tovtech` account
   - Generate at: https://hub.docker.com/settings/security

## Frontend CI/CD Workflow Issue

**Problem**: The current `.github/workflows/main.yml` production deployment script extracts files to `/var/www/tovplay/` but production actually uses a Docker container.

**Solution**: The deployment script should restart the Docker container, not extract files.

### Correct Production Deployment Method

```bash
cd /home/admin/tovplay
docker pull tovtech/tovplayfrontend:latest
docker compose -f docker-compose.production.yml --env-file .env.production up -d --force-recreate --no-deps frontend
```

**This method has been tested and works perfectly.**

### Staging Deployment Method (Currently Correct)

```bash
docker pull tovtech/tovplayfrontend:staging
# Extract files to /var/www/tovplay-staging/
# (Static file serving by host nginx)
```

## Manual Deployment Steps

### Production Frontend Manual Deployment

```bash
# SSH to production server
wsl -d ubuntu bash -c "sshpass -p 'EbTyNkfJG6LM' ssh admin@193.181.213.220"

# Navigate to deployment directory
cd /home/admin/tovplay

# Pull latest image
docker pull tovtech/tovplayfrontend:latest

# Restart container
docker compose -f docker-compose.production.yml --env-file .env.production up -d --force-recreate --no-deps frontend

# Verify
docker ps | grep tovplay-frontend-production
curl -f https://app.tovplay.org/
```

### Production Backend Manual Deployment

```bash
# SSH to production server
wsl -d ubuntu bash -c "sshpass -p 'EbTyNkfJG6LM' ssh admin@193.181.213.220"

cd /home/admin/tovplay
docker pull tovtech/tovplaybackend:latest
docker compose -f docker-compose.production.yml --env-file .env.production up -d --force-recreate --no-deps backend

# Verify
docker ps | grep tovplay-backend-production
docker logs tovplay-backend-production --tail 20
```

## Critical Production Environment Configuration

**MUST HAVE** in `/home/admin/tovplay/.env.production`:

```bash
# Database connection - CRITICAL!
POSTGRES_USER=your-postgres-user
POSTGRES_PASSWORD=your-postgres-password
POSTGRES_DB=TovPlay
POSTGRES_HOST=your-db-host
POSTGRES_PORT=5432
DATABASE_URL=postgresql://your-user%40domain:your-password@your-db-host:5432/TovPlay

# Note: The @ symbol in username MUST be URL-encoded as %40
# Without the DATABASE_URL, the backend will try to connect to hostname "postgres" and fail
# Contact project admin for actual production credentials
```

## Testing Deployment

### Test Production Login

```bash
curl -X POST https://app.tovplay.org/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"Email":"a@a","Password":"Password3^"}'
```

**Expected Response:**
```json
{
  "jwt_token": "eyJ...",
  "message": "User signed in successfully!",
  "user_id": "125e7f86-5810-416f-be49-45da321c4bf3"
}
```

### Test Staging Login

```bash
curl -X POST https://staging.tovplay.org/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"Email":"a@a","Password":"Password3^"}'
```

## GitHub Actions Workflow Fixes Needed

### Frontend Workflow (.github/workflows/main.yml)

Replace lines 202-243 (production deployment section) with:

```yaml
          echo "🚀 Starting PRODUCTION Frontend Deployment..."

          cd /home/admin/tovplay || { echo "❌ Directory not found"; exit 1; }

          echo "📦 Pulling latest frontend Docker image..."
          docker pull tovtech/tovplayfrontend:latest

          echo "🔄 Restarting PRODUCTION frontend container..."

          if docker compose version &> /dev/null; then
            COMPOSE_CMD="docker compose"
          elif command -v docker-compose &> /dev/null; then
            COMPOSE_CMD="docker-compose"
          else
            echo "Installing docker-compose..."
            sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
            sudo chmod +x /usr/local/bin/docker-compose
            COMPOSE_CMD="docker-compose"
          fi

          $COMPOSE_CMD -f docker-compose.production.yml --env-file .env.production up -d --force-recreate --no-deps frontend

          echo "⏳ Waiting for frontend container to start..."
          sleep 15

          if docker ps | grep -q tovplay-frontend-production; then
            echo "✅ PRODUCTION frontend container is running!"
            docker logs tovplay-frontend-production --tail 20
          else
            echo "❌ PRODUCTION frontend container failed to start"
            docker ps -a | grep tovplay
            exit 1
          fi

          curl -f https://app.tovplay.org/ 2>/dev/null && echo "✅ Frontend is accessible"
```

## Docker Images

- **Production Frontend**: `tovtech/tovplayfrontend:latest`
- **Production Backend**: `tovtech/tovplaybackend:latest`
- **Staging Frontend**: `tovtech/tovplayfrontend:staging`
- **Staging Backend**: `tovtech/tovplaybackend:staging`

## Deployment URLs

- **Production**: https://app.tovplay.org
- **Production API**: https://app.tovplay.org/api/
- **Staging**: https://staging.tovplay.org
- **Staging API**: https://staging.tovplay.org/api/

## Server Access

### Production Server: 193.181.213.220
```bash
wsl -d ubuntu bash -c "sshpass -p 'EbTyNkfJG6LM' ssh admin@193.181.213.220"
```

### Staging Server: 92.113.144.59
```bash
wsl -d ubuntu bash -c "sshpass -p '3897ysdkjhHH' ssh admin@92.113.144.59"
```

## Next Steps to Fix CI/CD

1. **Configure DOCKERHUB_TOKEN secret** in both repos (frontend & backend)
   - GitHub Repository > Settings > Secrets and variables > Actions
   - New repository secret: `DOCKERHUB_TOKEN`

2. **Update frontend workflow** to use docker-compose restart method for production

3. **Test the workflow** by pushing a small change to trigger the pipeline

4. **Monitor** the GitHub Actions tab to verify successful deployment

## Verified Working Configurations

- ✅ Production database connection fixed and tested
- ✅ Production login working (test user: a@a / Password3^)
- ✅ Staging login working (same credentials)
- ✅ Docker container restart method tested and verified
- ✅ Backend CI/CD workflow structure is correct (needs secret only)
- ⚠️ Frontend CI/CD workflow needs deployment method update + secret

---

**Last Updated**: 2025-11-03
**Tested By**: Claude Code
