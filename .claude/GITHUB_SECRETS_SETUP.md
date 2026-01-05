# GitHub Secrets Setup Guide

This document lists all required GitHub Secrets for CI/CD workflows to function properly.

## Required Secrets for Both Repositories

Both `tovplay-frontend` and `tovplay-backend` repositories require the following secrets to be configured in GitHub Actions.

### How to Add Secrets

1. Go to repository Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret listed below

### Docker Hub Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `DOCKERHUB_TOKEN` | Docker Hub access token for `tovtech` account | `dckr_pat_xxxxx` |

### Server Access Secrets - Production

| Secret Name | Description | Actual Value |
|-------------|-------------|---------------|
| `PRODUCTION_HOST` | Production server IP | `193.181.213.220` |
| `PRODUCTION_USERNAME` | SSH username for production | `admin` |
| `PRODUCTION_PASSWORD` | SSH password for production | Contact admin for value |

### Server Access Secrets - Staging

| Secret Name | Description | Actual Value |
|-------------|-------------|---------------|
| `STAGING_HOST` | Staging server IP | `92.113.144.59` |
| `STAGING_USERNAME` | SSH username for staging | `admin` |
| `STAGING_PASSWORD` | SSH password for staging | Contact admin for value |

## Verification

After adding all secrets, verify they appear in:
- https://github.com/TovTechOrg/tovplay-frontend/settings/secrets/actions
- https://github.com/TovTechOrg/tovplay-backend/settings/secrets/actions

You should see **7 secrets** in total for each repository:
1. DOCKERHUB_TOKEN
2. PRODUCTION_HOST
3. PRODUCTION_USERNAME
4. PRODUCTION_PASSWORD
5. STAGING_HOST
6. STAGING_USERNAME
7. STAGING_PASSWORD

## Security Notes

- Never commit actual secret values to the repository
- Secrets are encrypted by GitHub and only exposed to workflow runs
- Rotate secrets periodically for enhanced security
- Use different passwords for staging and production environments

## Troubleshooting

If CI/CD workflows fail with authentication errors:
1. Verify all 7 secrets are configured in repository settings
2. Check secret names match exactly (case-sensitive)
3. Confirm Docker Hub token has push permissions
4. Test SSH credentials manually before adding as secrets

## Contact

For actual secret values, contact the project administrator or refer to secure credential storage.

Last Updated: December 10, 2025
