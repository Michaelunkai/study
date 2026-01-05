# TovPlay Frontend

**Parent Docs:** See `/CLAUDE.md` for full architecture, credentials, and rules.

---

## LOCAL SETUP

**Requirements:** Node.js 22.21.1 (Volta managed)
```bash
cd F:\tovplay\tovplay-frontend
npm install
cp .env.template .env  # Edit with local backend URL
npm run dev
```

**Test:** `http://localhost:3000` should load app

**Environment Configuration:** `.env.template` contains all settings for local/staging/production - uncomment the section you need

---

## STRUCTURE

```
tovplay-frontend/
├─ src/
│  ├─ components/       # React components
│  │  ├─ ui/           # shadcn/ui components
│  │  ├─ dashboard/    # Dashboard widgets
│  │  └─ lib/          # Component utilities
│  ├─ pages/           # Route pages
│  ├─ api/             # API client
│  ├─ stores/          # Redux slices
│  ├─ context/         # React contexts
│  ├─ hooks/           # Custom hooks
│  ├─ utils/           # Utilities
│  └─ App.jsx          # Root component
├─ public/             # Static assets
├─ package.json        # Dependencies
├─ vite.config.js      # Vite config
├─ Dockerfile          # Multi-stage build
└─ nginx.conf          # Production nginx
```

---

## KEY FILES

**Entry Point:** `src/main.jsx` → `src/App.jsx`

**Pages:** `src/pages/`
- `Welcome.jsx` - Landing/auth
- `SignIn.jsx` - Login
- `Dashboard.jsx` - Main dashboard
- `Profile.jsx` - User profile
- `Schedule.jsx` - Session scheduling

**API:** `src/api/`
- `apiService.js` - Main API client
- `base44Client.js` - Base HTTP client

**State:** `src/stores/`
- `authSlice.js` - Authentication state

**Components:** `src/components/`
- `PlayerCard.jsx` - User card
- `GameRequestCard.jsx` - Game request display
- `RequestModal.jsx` - Request creation modal
- `ui/` - shadcn/ui components (Button, Dialog, Input, etc.)

---

## DOCKER

**Multi-stage build:** Build → nginx serve
```bash
# Build for production
docker build \
  --build-arg VITE_API_BASE_URL=https://app.tovplay.org \
  --build-arg VITE_WS_URL=wss://app.tovplay.org \
  -t tovtech/tovplayfrontend:latest .

# Run locally
docker-compose up

# Deploy production (handled by Cloudflare Pages)
```

---

## DEVELOPMENT

**Scripts:**
```bash
npm run dev              # Start dev server (port 3000)
npm run build            # Production build
npm run preview          # Preview production build
npm run lint             # ESLint check
npm run lint:fix         # ESLint auto-fix
```

**Linting:** ESLint with React, Import, Unused-imports plugins

**Note:** Test configs (Vitest, Playwright) and e2e/ folder removed during Dec 2025 debloat - archived to `.claude/archive/`

---

## DEPLOYMENT

**Method:** Cloudflare Pages (auto-deploy from GitHub)
- Push to main → builds & deploys to https://app.tovplay.org
- Staging branch → https://staging.tovplay.org

**Build Settings:**
```
Framework: Vite
Build command: npm run build
Output directory: dist
Node version: 22.21.1
```

**Environment Variables:** Set in Cloudflare Pages dashboard
- `VITE_API_BASE_URL` - Backend URL
- `VITE_WS_URL` - WebSocket URL
- `VITE_GOOGLE_CLIENT_ID` - Google OAuth
- `VITE_ERROR_REPORTING_ENDPOINT` - Error reporting

---

## TECH STACK

**Core:** React 18, Vite 6, React Router 7

**State:** Redux Toolkit, React Query (TanStack Query)

**UI:** Tailwind CSS, shadcn/ui (Radix UI primitives)

**Forms:** React Hook Form, Formik, Yup validation

**Real-time:** Socket.IO client

**Analytics:** Google Analytics via analytics.js

**Icons:** Lucide React
