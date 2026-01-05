# GitHub Secrets Setup Guide

## ⚠️ REQUIRED ACTION TO ENABLE CI/CD

The CI/CD pipeline requires a Docker Hub access token to be configured as a GitHub secret.

## Step-by-Step Setup

### 1. Create Docker Hub Access Token

1. Go to https://hub.docker.com/settings/security
2. Click "New Access Token"
3. Name: `github-actions-tovplay` (or any descriptive name)
4. Permissions: **Read, Write, Delete**
5. Click "Generate"
6. **IMPORTANT**: Copy the token immediately - you won't be able to see it again!

### 2. Add Secret to GitHub Repository (Frontend)

1. Go to: https://github.com/TovTechOrg/tovplay-frontend/settings/secrets/actions
2. Click "New repository secret"
3. Name: `DOCKERHUB_TOKEN`
4. Value: Paste the Docker Hub access token from step 1
5. Click "Add secret"

### 3. Add Secret to GitHub Repository (Backend)

1. Go to: https://github.com/TovTechOrg/tovplay-backend/settings/secrets/actions (adjust URL if different org)
2. Click "New repository secret"
3. Name: `DOCKERHUB_TOKEN`
4. Value: Paste the same Docker Hub access token from step 1
5. Click "Add secret"

## Verification

After adding the secrets, the CI/CD pipeline will automatically trigger on:
- Push to `main` branch → Production deployment
- Push to `develop` branch → Staging deployment

### Test the Pipeline

1. Make a small change (e.g., add a comment to README.md)
2. Commit and push to `main` branch
3. Go to GitHub Actions tab to monitor the workflow
4. Verify deployment succeeds

## Docker Hub Credentials

- **Username**: `tovtech`
- **Password**: `professor-default-glade-smartly-rogue-reverb7`
- **Images**:
  - Frontend: `tovtech/tovplayfrontend:latest` (production), `tovtech/tovplayfrontend:staging` (staging)
  - Backend: `tovtech/tovplaybackend:latest` (production), `tovtech/tovplaybackend:staging` (staging)

## What the CI/CD Pipeline Does

### Frontend Workflow (.github/workflows/main.yml)

1. **Test Job**:
   - Install dependencies
   - Run linting
   - Run type checking
   - Run tests
   - Build application
   - Verify build output

2. **Build-and-Deploy Job** (after tests pass):
   - Build Docker image
   - Push to Docker Hub with appropriate tag
   - SSH to server
   - Pull latest image
   - Restart Docker container via docker-compose
   - Verify deployment health

### Backend Workflow (.github/workflows/deploy.yml)

1. Build Docker image
2. Push to Docker Hub
3. SSH to server
4. Pull latest image
5. Restart Docker container
6. Verify backend is healthy

## Troubleshooting

### If CI/CD Fails

1. **Check GitHub Actions logs**:
   - Frontend: https://github.com/TovTechOrg/tovplay-frontend/actions
   - Backend: (adjust URL for backend repo)

2. **Common Issues**:
   - Missing `DOCKERHUB_TOKEN` secret → Add as described above
   - Docker Hub login failure → Verify token is correct
   - Deployment failure → Check server SSH access and docker-compose files

3. **Manual Deployment** (fallback):
   - See `CI-CD-SETUP.md` for manual deployment commands

## Security Notes

- Never commit the Docker Hub access token to git
- The token is stored encrypted in GitHub secrets
- Only repository administrators can view/edit secrets
- Rotate the token periodically for security

## Next Steps After Setup

1. Add the `DOCKERHUB_TOKEN` secret to both repositories
2. Push a small change to test the pipeline
3. Monitor the GitHub Actions tab
4. Verify deployment on production: https://app.tovplay.org
5. Verify deployment on staging: https://staging.tovplay.org

## Support

If you encounter issues:
1. Check `CI-CD-SETUP.md` for detailed troubleshooting
2. Review GitHub Actions logs for error messages
3. Verify server access and docker-compose configurations
4. Test manual deployment to isolate issues
