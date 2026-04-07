# End-to-End Test Procedure

## Prerequisites
- Node.js installed
- cloudflared installed
- Netlify frontend deployed at https://claude-web-terminal.netlify.app

## Steps

### 1. Start the backend server
```
cd F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal
npm start
```
Verify: `curl http://localhost:3099/health` returns `{"status":"ok","port":3099}`

### 2. Start cloudflared tunnel
```
cloudflared tunnel --url http://localhost:3099
```
Wait for output like: `https://xxxx.trycloudflare.com`
Copy the tunnel URL.

### 3. Configure frontend
Open: https://claude-web-terminal.netlify.app
Open browser DevTools console and run:
```
localStorage.setItem('wsUrl', 'wss://xxxx.trycloudflare.com')
```
Refresh the page.

### 4. Authenticate
Enter token: `claude-terminal-2026`
Click Connect.

### 5. Verify
- Terminal appears with PowerShell prompt
- Type `whoami` → should show your username
- Type `dir` → should list files
- Ctrl+C → interrupts running process
- Resize window → terminal adapts

## Expected Results
- Connection established within 2 seconds
- Commands execute and output appears in xterm.js
- Colors render correctly (GitHub Dark theme)
- Token persists across refresh via localStorage

## Configuration Reference
- Backend port: 3099 (set in .env)
- Auth token: `claude-terminal-2026` (set in .env)
- Netlify URL: https://claude-web-terminal.netlify.app
