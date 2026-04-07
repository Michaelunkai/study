# Claude Web Terminal Architecture

## Components

### Backend (server.js)
- Express HTTP server on PORT (default 3099)
- WebSocket server (ws library) on same port
- child_process spawn of powershell.exe (node-pty optional)
- Rate limiting: 3 failed auth per IP, 5min reset
- Ping/pong keepalive every 30s (server) + 25s (client)
- CORS headers for all origins
- Session recording to sessions/session-TIMESTAMP.log
- File upload endpoint POST /upload (multer, 50MB limit)
- Rotating log (max 1MB, keep 3 files)
- Endpoints: GET /health, GET /status, GET /sessions, POST /upload

### Frontend (public/index.html)
- xterm.js v5.3.0 + FitAddon + SearchAddon
- GitHub Dark theme (16 ANSI colors)
- Auth overlay with token + wsUrl (Advanced collapsible)
- Topbar: title, Split button, Replay button, font controls (A-/A/A+), elapsed timer, status
- Keyboard: Ctrl+F (search), Ctrl+= (font+), Ctrl+- (font-), Ctrl+0 (reset), Escape (close search)
- Drag-drop file upload with visual overlay
- Split view: two independent PTY panes with drag-resize divider
- localStorage: authToken, wsUrl, fontSize

### Tunnel (cloudflared)
- Cloudflare Quick Tunnel (trycloudflare.com) to localhost:3099
- Script: start-tunnel.ps1
- Installed at: C:\Program Files (x86)\cloudflared\cloudflared.exe v2025.8.1

### Frontend Hosting (Netlify)
- URL: https://claude-web-terminal.netlify.app
- Static files from public/ directory

### Startup
- Task Scheduler: ClaudeWebTerminal (node server.js at logon, elevated)
- Quick launch: start-all.bat (server + cloudflared)
- Desktop shortcut: Claude Web Terminal.lnk -> start-all.bat

## Data Flow
Phone/Browser -> Netlify (static HTML/JS) -> wss://xxxx.trycloudflare.com -> localhost:3099 -> powershell.exe PTY

## Security
- Token auth (AUTH_TOKEN in .env, never committed)
- Rate limiting (3 attempts / IP, 5min reset)
- .env in .gitignore / .env.example has placeholders

## Verified (2026-04-02)
- Task Scheduler task ClaudeWebTerminal: EXISTS (State=Ready, runs node server.js at logon, elevated)
- Manual task run: node starts on port 3099 successfully
- Health endpoint GET /health: HTTP 200 {"status":"ok"}
- multer dependency installed (was missing from node_modules, npm install resolved)
- LastTaskResult 3221225786 (0xC000013A = STATUS_CONTROL_C_EXIT) is expected for manual stop

## Auto-Start Test Results (2026-04-02 — Todo #73)
- `Get-ScheduledTask -TaskName 'ClaudeWebTerminal'` returns `State: Ready` — task exists and is registered
- `Start-ScheduledTask -TaskName 'ClaudeWebTerminal'` executed successfully (no error)
- Port 3099 bind verified after scheduler task trigger
- Netlify frontend URL: https://claude-web-terminal.netlify.app (see NETLIFY_URL.txt)
- cloudflared tunnel task: ClaudeWebTerminalTunnel (start-tunnel.ps1 at logon)
- Both tasks run at logon without interactive window
