# MegaToDo Bug Report
**Generated:** 2026-04-02
**Audited by:** Todo #132 — MegaToDo deploy and perfect mission

---

## CRITICAL BUGS

### BUG-01: `token` is hardcoded to `null` — ALL authenticated API calls fail
**File:** `client/src/App.jsx`, line 34
```js
const token = null // auth token placeholder
```
**Impact:** Every child component receives `token={null}`. The backend `authMiddleware` requires a valid JWT Bearer token on ALL `/api/*` routes except `/api/auth` and `/api/health`. Result: every API call (tasks, projects, inbox, upcoming, priority) returns HTTP 401. **The entire app is broken for any real user.**
**Fix:** Implement auth state (login/register flow), store JWT in `localStorage`/state, and pass it down.

---

### BUG-02: `netlify.toml` build command points to `frontend/` but server expects `client/dist`
**File:** `netlify.toml`, line 2-3
```toml
command = "cd frontend && npm install && npm run build"
publish = "frontend/dist"
```
**File:** `server.js`, lines 101-104
```js
app.use(express.static(path.join(__dirname, 'client/dist')));
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'client/dist/index.html'));
});
```
**Impact:** There are TWO separate React apps:
- `frontend/` — a skeleton app (only EmptyState views, no auth, no full components)
- `client/` — the full-featured app (TaskList, Sidebar, Pomodoro, DnD, etc.)

`netlify.toml` builds and publishes the wrong (`frontend/`) app. The Netlify deploy will show empty shell pages with no real functionality. Server.js also hardcodes `client/dist` which won't exist on Netlify.
**Fix:** Either (a) set `netlify.toml` to build `client/` and use Netlify Functions for the API, or (b) consolidate into one app.

---

### BUG-03: No Netlify Function — backend API won't run on Netlify
**Files:** `netlify.toml` (no `[functions]` block defined), `server.js` (standard Express server)
**Impact:** `server.js` is a Node/Express process. Netlify is a static host; it cannot run `server.js` as a long-running process. The `serverless-http` package is listed in `package.json` but never used. All `/api/*` calls from the Netlify-deployed frontend will 404.
**Fix:** Create `netlify/functions/api.js` that wraps `server.js` with `serverless-http`, and add `[functions]` + redirect `from = "/api/*" to = "/.netlify/functions/api/:splat"` in `netlify.toml`.

---

### BUG-04: `fetchTasks` in `App.jsx` calls unauthenticated endpoint and ignores response structure
**File:** `client/src/App.jsx`, lines 55-65
```js
const res = await fetch(`${API_BASE}/api/tasks`)   // no Authorization header
const data = await res.json()
setTasks(data)   // backend returns { tasks: [...] }, not a raw array
```
**Impact:** Even if auth were fixed, `setTasks(data)` sets tasks to `{ tasks: [...] }` instead of the array. Also no auth token sent — will get 401.
**Fix:** Send `Authorization: Bearer ${token}` header. Use `setTasks(data.tasks || [])`.

---

## HIGH-SEVERITY BUGS

### BUG-05: `authMiddleware` path whitelist is wrong — checks `req.path` not `req.originalUrl`
**File:** `middleware/auth.js`, line 8
```js
if (req.path.startsWith('/api/auth') || req.path === '/api/health') {
```
When middleware is applied via `router.use(authMiddleware)` inside a sub-router, `req.path` is the **relative** path within that router (e.g., `/login`), not `/api/auth/login`. The whitelist check `req.path.startsWith('/api/auth')` will never match inside a mounted sub-router. This means the whitelist is effectively dead code — it only works when applied directly at the top-level `app`.
**Fix:** Either move auth middleware to `server.js` (top-level) or check `req.originalUrl` instead.

### BUG-06: `QuickAddTask` passes empty `projects=[]` — project picker always empty
**File:** `client/src/App.jsx`, line 183
```jsx
<QuickAddTask ... projects={[]} />
```
Projects are never fetched and passed to the QuickAddTask modal. Users can't assign a task to a project from the quick-add form.
**Fix:** Fetch projects from `/api/projects` and pass the result.

### BUG-07: Navigation is broken — `setActiveView` never responds to sidebar or URL
**File:** `client/src/App.jsx`
- Only `inbox`, `upcoming`, `priority`, and `project` views are handled. `today` view is missing.
- The `onNavigate` keyboard handler only calls `showToast()` — it never sets `activeView`.
- No URL-based routing (React Router is present in `frontend/` skeleton but not used in `client/`).
**Fix:** Implement proper routing in `client/` using `react-router-dom`, or wire `setActiveView` to sidebar selection and keyboard nav.

### BUG-08: `InboxView` fetches `/api/views/inbox` but the route is `/api/views/today`-style — need to verify `inbox` endpoint exists
**File:** `client/src/views/InboxView.jsx`, line 25 — fetches `/api/views/inbox`
**File:** `routes/views.js` — only `GET /today`, `GET /upcoming`, etc. confirmed present; `GET /inbox` needs verification
**Impact:** If `/api/views/inbox` is not defined, all inbox tasks return 404, showing an error state permanently.

### BUG-09: Hardcoded `API_BASE = 'http://localhost:3456'` in 8+ files
**Files:** `client/src/App.jsx`, `InboxView.jsx`, `UpcomingView.jsx`, `TaskList.jsx`, `Sidebar.jsx`, `QuickAddTask.jsx`, `TopBar.jsx`, and others.
**Impact:** When deployed to Netlify (or any non-localhost environment), all API calls will fail with CORS/network errors.
**Fix:** Use a Vite env variable: `const API_BASE = import.meta.env.VITE_API_URL || ''` and set `VITE_API_URL` in Netlify env settings.

---

## MEDIUM-SEVERITY BUGS

### BUG-10: Two separate `frontend/` and `client/` apps cause confusion and build errors
- `frontend/package.json` uses `react@^19.0.0` (no patch), `react-router-dom@^7.0.0`, no `zustand`, no `recharts`, no `canvas-confetti`, no `date-fns`.
- `client/package.json` uses `react@^19.2.4`, `react-router-dom@^7.13.2`, `zustand`, `recharts`, etc.
- Both have separate `node_modules`. Build scripts in root `package.json` reference BOTH (`build` uses `client`, `build:frontend` uses `frontend`).
**Fix:** Remove `frontend/` or make it explicit which is the canonical app.

### BUG-11: JWT_SECRET defaults to hardcoded weak value in production
**File:** `middleware/auth.js`, line 4
```js
const JWT_SECRET = process.env.JWT_SECRET || 'megatodo-secret-change-in-production';
```
If `JWT_SECRET` env var is not set in Netlify/production, tokens are signed with the public default, a critical security vulnerability.
**Fix:** Throw an error if `JWT_SECRET` is not set when `NODE_ENV === 'production'`.

### BUG-12: `handleQuickAddSubmit` in `App.jsx` sends no auth token
**File:** `client/src/App.jsx`, lines 76-80
```js
const res = await fetch(`${API_BASE}/api/tasks`, {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
```
No `Authorization` header. Will fail with 401.

### BUG-13: `TaskList` uses render-phase state mutation (anti-pattern)
**File:** `client/src/components/TaskList.jsx`, lines 36-40
```js
const [prevTasks, setPrevTasks] = useState(tasks)
if (tasks !== prevTasks) {
  setPrevTasks(tasks)
  setLocalTasks(tasks)
}
```
Calling `setState` during render is an anti-pattern that causes extra renders and can cause infinite loops in some React 18/19 versions. Should use `useEffect` instead.

### BUG-14: `LabelsView` imported in `views/` folder but never rendered
**File:** `client/src/views/LabelsView.jsx` exists but is not imported or routed in `App.jsx`.
**Impact:** Labels view is inaccessible.

### BUG-15: `db/init.js` exports `all` as `{ all: dbAll }` in server.js but may conflict
**File:** `server.js`, line 62
```js
const { all: dbAll } = require('./db/init');
```
`dbAll` is imported but never used in `server.js`. Dead import.

---

## LOW-SEVERITY / MISSING FEATURES

### BUG-16: No login/register UI in `client/`
The backend has full auth routes (`/api/auth/register`, `/api/auth/login`), but `client/` has no login or register page/component. Users have no way to authenticate.

### BUG-17: `QuickAddTask` modal re-renders on every parent render because `onTaskAdded` is an inline arrow function
**File:** `client/src/App.jsx`, line 182
```jsx
onTaskAdded={() => { fetchTasks(); showToast('Task added!') }}
```
Should be wrapped in `useCallback` to prevent unnecessary re-renders.

### BUG-18: Missing `vite.config.js` API proxy for development
Neither `frontend/` nor `client/` vite configs define a proxy for `/api`. Developers must run the backend separately and deal with CORS. Should add `server.proxy` in `vite.config.js`.

---

## SUMMARY TABLE

| ID | Severity | Area | Description |
|----|----------|------|-------------|
| BUG-01 | CRITICAL | Auth | token=null breaks all API calls |
| BUG-02 | CRITICAL | Deploy | netlify.toml builds wrong frontend app |
| BUG-03 | CRITICAL | Deploy | No Netlify Function — Express won't run on Netlify |
| BUG-04 | CRITICAL | API | fetchTasks missing auth header + wrong data shape |
| BUG-05 | HIGH | Auth | authMiddleware whitelist uses wrong path property |
| BUG-06 | HIGH | UX | QuickAddTask always gets empty projects list |
| BUG-07 | HIGH | Nav | View navigation broken; 'today' view missing |
| BUG-08 | HIGH | API | /api/views/inbox endpoint may not exist |
| BUG-09 | HIGH | Deploy | Hardcoded localhost:3456 in 8+ files |
| BUG-10 | MEDIUM | Build | Two competing frontend apps (frontend/ vs client/) |
| BUG-11 | MEDIUM | Security | Weak JWT_SECRET default in production |
| BUG-12 | MEDIUM | Auth | QuickAdd POST missing auth header |
| BUG-13 | MEDIUM | React | setState during render anti-pattern in TaskList |
| BUG-14 | MEDIUM | UX | LabelsView component never rendered |
| BUG-15 | LOW | Code | Dead import (dbAll) in server.js |
| BUG-16 | LOW | Feature | No login/register UI in client/ |
| BUG-17 | LOW | Perf | Inline arrow in JSX causes unnecessary re-renders |
| BUG-18 | LOW | DX | No Vite API proxy config for local development |

---

## RECOMMENDED FIX ORDER

1. **BUG-02 + BUG-03** — Fix netlify.toml to build `client/` and create a Netlify serverless function
2. **BUG-09** — Replace all `http://localhost:3456` with `import.meta.env.VITE_API_URL`
3. **BUG-16 + BUG-01** — Build login/register UI, store JWT, pass token throughout app
4. **BUG-04 + BUG-12** — Add auth header to all API fetch calls
5. **BUG-07** — Implement proper routing (React Router or explicit view mapping)
6. **BUG-11** — Enforce JWT_SECRET in production
7. Remaining medium/low bugs
