# Branch Protection Rules for Playwright E2E Tests

## Overview
Both frontend and backend repositories now have Playwright E2E tests integrated into their CI/CD workflows. These tests run automatically on:
- Push to `main` or `develop` branches
- Pull requests targeting `main` or `develop` branches

## Setting Up Branch Protection Rules

### For Frontend Repository (tovplay-frontend)

1. Go to: `https://github.com/[org]/tovplay-frontend/settings/branches`
2. Click "Add branch protection rule"
3. Configure for `main` branch:
   - Branch name pattern: `main`
   - Check: "Require a pull request before merging"
   - Check: "Require status checks to pass before merging"
   - Search and select: `playwright-e2e`
   - Check: "Require branches to be up to date before merging"
4. Repeat for `develop` branch

### For Backend Repository (tovplay-backend)

1. Go to: `https://github.com/[org]/tovplay-backend/settings/branches`
2. Click "Add branch protection rule"
3. Configure for `main` branch:
   - Branch name pattern: `main`
   - Check: "Require a pull request before merging"
   - Check: "Require status checks to pass before merging"
   - Search and select: `playwright-e2e`
   - Check: "Require branches to be up to date before merging"
4. Repeat for `develop` branch

## Required Status Checks

| Repository | Job Name | Description |
|------------|----------|-------------|
| tovplay-frontend | `playwright-e2e` | Frontend E2E tests with Playwright |
| tovplay-backend | `playwright-e2e` | Backend API E2E tests with Playwright |

## How It Works

### Frontend Workflow
1. Checkout code
2. Install dependencies
3. Install Playwright browsers
4. Build application
5. Start preview server
6. Run Playwright tests against `http://localhost:4173`
7. Upload report on failure
8. If tests pass AND it's a push (not PR), proceed to deploy

### Backend Workflow
1. Checkout code
2. Install Python dependencies
3. Install Node.js and Playwright
4. Start Flask server with test database
5. Run Playwright API tests against `http://localhost:5000`
6. Upload report on failure
7. If tests pass AND it's a push (not PR), proceed to deploy

## Test Files

### Frontend Tests
- Location: `tovplay-frontend/e2e/app.spec.js`
- Config: `tovplay-frontend/playwright.config.js`

Tests include:
- Homepage loads successfully
- Welcome page renders
- Login/Signup pages accessible
- No JavaScript errors
- Responsive viewport test

### Backend Tests
- Location: `tovplay-backend/e2e/api.spec.js`
- Config: `tovplay-backend/playwright.config.js`

Tests include:
- Health endpoint returns healthy status
- Login endpoint exists
- Signup endpoint exists
- Game requests endpoint requires auth
- CORS headers present
- API returns JSON content-type

## Running Tests Locally

### Frontend
```bash
cd tovplay-frontend
npm install
npx playwright install chromium
npm run test:playwright
```

### Backend
```bash
cd tovplay-backend
npm install
npx playwright install chromium
# Start Flask server in another terminal
python run.py
# Run tests
npm run test:playwright
```

## Troubleshooting

### Tests fail in CI but pass locally
- Check if environment variables are set in GitHub Secrets
- Verify the server has time to start (sleep command)
- Check the Playwright report artifact for details

### Branch protection not working
- Ensure the workflow has run at least once after creating the protection rule
- Status check names must match exactly (case-sensitive)
- The workflow must be on the default branch

## Files Modified

### Frontend
- `.github/workflows/main.yml` - Added `playwright-e2e` job as dependency for deploy
- `package.json` - Added `@playwright/test` and scripts
- `playwright.config.js` - Created Playwright configuration
- `e2e/app.spec.js` - Created E2E test file

### Backend
- `.github/workflows/unified-cicd.yml` - Added `playwright-e2e` job as dependency for deploy
- `package.json` - Created for Playwright dependencies
- `playwright.config.js` - Created Playwright configuration
- `e2e/api.spec.js` - Created API E2E test file
