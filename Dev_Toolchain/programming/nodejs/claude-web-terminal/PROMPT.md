You are a master full-stack developer specializing in real-time terminal streaming, Node.js, WebSocket protocols, cloud tunneling, static hosting, and CI/CD deployment on Windows.

Complete this entire task autonomously from start to finish. Do NOT ask me for input, confirmation, or clarification at any point. If anything is ambiguous, make the best technical decision and proceed. Never pause for manual steps.

CRITICAL EXECUTION RULE — RANKED FALLBACK PROTOCOL:
Every step below has 10 ranked options. ALWAYS start with Option 1 (the best). If it fails for ANY reason (error, timeout, missing dependency, permission denied, network issue), IMMEDIATELY move to Option 2. If that fails, Option 3, and so on through Option 10. Do NOT stop. Do NOT ask for help. Do NOT report failure until ALL 10 options for a step have been exhausted. After completing a step (by any option), move to the next step. Continue until the entire task is 100% complete.

## TASK
Build and deploy a web application that mirrors my local Windows PC terminal running Claude Code (`claude` CLI). When I open the web URL from any device anywhere in the world, I see my exact terminal with Claude Code already running — same shell, same environment, fully interactive. The app stays live as long as my PC is on.

## ARCHITECTURE
- **Backend** (Node.js on local PC): Real terminal via `node-pty`, streams I/O over WebSocket, token-based auth, auto-launches `claude` on connect.
- **Frontend** (static site on Netlify): xterm.js terminal emulator, GitHub Dark theme, login screen for server URL + token.
- **Tunnel**: Exposes local backend to the internet with a persistent public URL.

---

## STEP 1 — CREATE PROJECT DIRECTORY
Target: `F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal`

1. `mkdir -p F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal` (PowerShell: `New-Item -ItemType Directory -Force -Path "F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal"`)
2. `md "F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal"` (cmd)
3. Use Node.js `fs.mkdirSync('F:\\study\\Dev_Toolchain\\programming\\nodejs\\claude-web-terminal', {recursive:true})`
4. `[System.IO.Directory]::CreateDirectory("F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal")`
5. Python: `import os; os.makedirs(r"F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal", exist_ok=True)`
6. Create at `C:\Users\micha\claude-web-terminal` instead (shorter path, avoids deep nesting issues)
7. Create at `C:\temp\claude-web-terminal` as temp location, move later
8. Create at `F:\claude-web-terminal` (root of F drive)
9. Create at `%USERPROFILE%\Desktop\claude-web-terminal`
10. Create at current working directory `.\claude-web-terminal`

After creation, `cd` into the project directory for all subsequent steps.

---

## STEP 2 — INITIALIZE PACKAGE.JSON

1. Write `package.json` directly with this content:
```json
{
  "name": "claude-web-terminal",
  "version": "1.0.0",
  "description": "Access local Claude Code terminal from anywhere via the web",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js"
  },
  "dependencies": {
    "express": "^4.21.0",
    "ws": "^8.18.0",
    "node-pty": "^1.0.0",
    "dotenv": "^16.4.5"
  },
  "engines": { "node": ">=18.0.0" }
}
```
2. `npm init -y` then manually add dependencies to the generated file
3. `echo '{"name":"claude-web-terminal",...}' > package.json`
4. Use `Set-Content -Path package.json -Value '...'` (PowerShell)
5. Use `[System.IO.File]::WriteAllText("package.json", $jsonContent)` (.NET via PS)
6. Use Python: `open('package.json','w').write(json.dumps(...))`
7. Use Node.js one-liner: `node -e "require('fs').writeFileSync('package.json', JSON.stringify({...}, null, 2))"`
8. Copy a template package.json from another project, edit in-place
9. Use `npx create-express-app` as scaffolding then modify
10. Write the file byte-by-byte using `Add-Content` line-by-line

---

## STEP 3 — CREATE .env FILE

Content:
```
PORT=3099
AUTH_TOKEN=claude-terminal-2026
```

1. Write file directly with file-write tool / `Set-Content .env "PORT=3099`nAUTH_TOKEN=claude-terminal-2026"`
2. `echo PORT=3099> .env && echo AUTH_TOKEN=claude-terminal-2026>> .env`
3. PowerShell `@("PORT=3099","AUTH_TOKEN=claude-terminal-2026") | Out-File .env -Encoding ascii`
4. Node.js: `require('fs').writeFileSync('.env', 'PORT=3099\nAUTH_TOKEN=claude-terminal-2026\n')`
5. Python: `open('.env','w').write('PORT=3099\nAUTH_TOKEN=claude-terminal-2026\n')`
6. Hardcode PORT and AUTH_TOKEN directly in server.js as defaults (skip .env entirely)
7. Use `process.env` via system environment variables: `[System.Environment]::SetEnvironmentVariable('AUTH_TOKEN','claude-terminal-2026','User')`
8. Create a `config.json` instead: `{"port":3099,"authToken":"claude-terminal-2026"}`
9. Pass as CLI args: `node server.js --port=3099 --token=claude-terminal-2026`
10. Use Windows registry to store config, read with `reg query`

---

## STEP 4 — CREATE .gitignore

Content: `node_modules/`, `.env`, `*.log`

1. Write file directly
2. `echo node_modules/> .gitignore & echo .env>> .gitignore`
3. `npx gitignore node` (downloads Node.js template)
4. Node.js: `require('fs').writeFileSync('.gitignore', 'node_modules/\n.env\n*.log\n')`
5. Copy from `~/.gitignore_global` and append
6. `curl -o .gitignore https://raw.githubusercontent.com/github/gitignore/main/Node.gitignore`
7. Python: `open('.gitignore','w').write(...)`
8. PowerShell `[IO.File]::WriteAllLines(".gitignore", @("node_modules/",".env","*.log"))`
9. Use `git config core.excludesFile` with global ignore
10. Create manually using notepad redirect

---

## STEP 5 — INSTALL DEPENDENCIES

1. `npm install` (reads package.json, installs all deps including node-pty)
2. `npm install express ws node-pty dotenv` (explicit)
3. `npm install --build-from-source` (forces native compilation for node-pty)
4. `yarn install`
5. `pnpm install`
6. `npm install express ws dotenv && npm install node-pty --build-from-source` (split native from JS)
7. `npm install` with `npm config set msvs_version 2022` first
8. Install build prerequisites first: `npm install --global windows-build-tools` then retry
9. `npm install express ws dotenv` + use `node-pty-prebuilt-multiarch` instead of `node-pty`
10. `npm install express ws dotenv` + use `child_process.spawn` instead of node-pty (pure Node.js fallback — no native deps, less features but zero build issues). If this option is used, adapt server.js to use `child_process.spawn('powershell.exe', [], { shell: false, stdio: ['pipe','pipe','pipe'] })`.

---

## STEP 6 — CREATE SERVER.JS

```javascript
const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const path = require('path');

let pty;
try { pty = require('node-pty'); } catch (e) {
  console.warn('[WARN] node-pty not available, using child_process fallback');
  pty = null;
}

require('dotenv').config();

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

const PORT = process.env.PORT || 3099;
const AUTH_TOKEN = process.env.AUTH_TOKEN || 'claude-terminal-2026';

app.use(express.static(path.join(__dirname, 'public')));
app.get('/health', (req, res) => res.json({ status: 'ok', uptime: process.uptime() }));

wss.on('connection', (ws, req) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const token = url.searchParams.get('token');
  if (token !== AUTH_TOKEN) {
    ws.send(JSON.stringify({ type: 'error', data: 'Unauthorized' }));
    ws.close();
    return;
  }

  console.log('[+] Client connected');
  const shell = process.platform === 'win32' ? 'powershell.exe' : 'bash';
  let proc;

  if (pty) {
    proc = pty.spawn(shell, [], {
      name: 'xterm-256color', cols: 120, rows: 30,
      cwd: process.env.USERPROFILE || process.env.HOME || '.',
      env: { ...process.env, TERM: 'xterm-256color' }
    });
    proc.onData((data) => { try { ws.send(JSON.stringify({ type: 'output', data })); } catch (e) {} });
    proc.onExit(({ exitCode }) => { try { ws.send(JSON.stringify({ type: 'exit', code: exitCode })); ws.close(); } catch (e) {} });
    ws.on('message', (msg) => {
      try {
        const parsed = JSON.parse(msg);
        if (parsed.type === 'input') proc.write(parsed.data);
        else if (parsed.type === 'resize') proc.resize(parsed.cols || 120, parsed.rows || 30);
      } catch (e) { proc.write(msg.toString()); }
    });
    ws.on('close', () => { console.log('[-] Disconnected'); proc.kill(); });
  } else {
    const { spawn } = require('child_process');
    proc = spawn(shell, [], {
      cwd: process.env.USERPROFILE || process.env.HOME || '.',
      env: { ...process.env, TERM: 'xterm-256color' },
      stdio: ['pipe', 'pipe', 'pipe']
    });
    proc.stdout.on('data', (data) => { try { ws.send(JSON.stringify({ type: 'output', data: data.toString() })); } catch (e) {} });
    proc.stderr.on('data', (data) => { try { ws.send(JSON.stringify({ type: 'output', data: data.toString() })); } catch (e) {} });
    proc.on('exit', (code) => { try { ws.send(JSON.stringify({ type: 'exit', code })); ws.close(); } catch (e) {} });
    ws.on('message', (msg) => {
      try {
        const parsed = JSON.parse(msg);
        if (parsed.type === 'input') proc.stdin.write(parsed.data);
      } catch (e) { proc.stdin.write(msg.toString()); }
    });
    ws.on('close', () => { console.log('[-] Disconnected'); proc.kill(); });
  }

  setTimeout(() => {
    if (pty) proc.write('claude\r');
    else proc.stdin.write('claude\r\n');
  }, 2000);
});

server.listen(PORT, () => {
  console.log(`\n🖥️  Claude Web Terminal running on http://localhost:${PORT}`);
  console.log(`🔑 Auth token: ${AUTH_TOKEN}`);
  console.log(`\nExpose publicly: cloudflared tunnel --url http://localhost:${PORT}\n`);
});
```

File writing fallbacks (1-10): same as Step 7.

---

## STEP 7 — CREATE PUBLIC/INDEX.HTML

Create `public/` directory, then write `public/index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Claude Web Terminal</title>
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/css/xterm.min.css">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #0d1117; color: #c9d1d9; font-family: 'Cascadia Code','Fira Code','Consolas',monospace; height: 100vh; display: flex; flex-direction: column; }
    #topbar { display: flex; align-items: center; justify-content: space-between; padding: 8px 16px; background: #161b22; border-bottom: 1px solid #30363d; font-size: 13px; }
    #topbar .title { display: flex; align-items: center; gap: 8px; }
    #topbar .title span { color: #58a6ff; font-weight: 600; }
    .dot { width: 8px; height: 8px; border-radius: 50%; background: #f85149; }
    .dot.connected { background: #3fb950; }
    #terminal-container { flex: 1; padding: 4px; }
    #login-screen { display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; gap: 16px; }
    #login-screen h1 { color: #58a6ff; font-size: 24px; }
    #login-screen input { background: #161b22; border: 1px solid #30363d; color: #c9d1d9; padding: 10px 16px; border-radius: 6px; font-size: 16px; width: 320px; font-family: inherit; }
    #login-screen input:focus { outline: none; border-color: #58a6ff; }
    #login-screen button { background: #238636; color: white; border: none; padding: 10px 24px; border-radius: 6px; font-size: 14px; cursor: pointer; }
    #login-screen button:hover { background: #2ea043; }
    .error { color: #f85149; font-size: 13px; display: none; }
    .hint { color: #8b949e; font-size: 12px; max-width: 320px; text-align: center; }
  </style>
</head>
<body>
  <div id="login-screen">
    <h1>🖥️ Claude Web Terminal</h1>
    <p class="hint">Connect to your local PC terminal running Claude Code</p>
    <input id="server-input" type="text" placeholder="Server URL (e.g. https://abc-xyz.trycloudflare.com)" />
    <input id="token-input" type="password" placeholder="Auth token" />
    <button onclick="connect()">Connect</button>
    <div class="error" id="error-msg"></div>
  </div>
  <div id="topbar" style="display:none">
    <div class="title"><span>🖥️ Claude Web Terminal</span><span style="color:#8b949e" id="server-label"></span></div>
    <div style="display:flex;align-items:center;gap:6px">
      <div class="dot" id="status-dot"></div>
      <span id="status-text">Disconnected</span>
      <button onclick="disconnect()" style="background:#f85149;color:white;border:none;padding:3px 10px;border-radius:4px;cursor:pointer;font-size:12px;margin-left:12px">Disconnect</button>
    </div>
  </div>
  <div id="terminal-container" style="display:none"></div>
  <script src="https://cdn.jsdelivr.net/npm/@xterm/xterm@5.5.0/lib/xterm.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@xterm/addon-fit@0.10.0/lib/addon-fit.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/@xterm/addon-web-links@0.11.0/lib/addon-web-links.min.js"></script>
  <script>
    let ws, term, fitAddon;
    const saved = { server: localStorage.getItem('cwt_server')||'', token: localStorage.getItem('cwt_token')||'' };
    document.getElementById('server-input').value = saved.server;
    document.getElementById('token-input').value = saved.token;
    function setStatus(on, text) { document.getElementById('status-dot').className = on ? 'dot connected' : 'dot'; document.getElementById('status-text').textContent = text || (on ? 'Connected' : 'Disconnected'); }
    function showError(msg) { const el = document.getElementById('error-msg'); el.textContent = msg; el.style.display = msg ? 'block' : 'none'; }
    function disconnect() { if (ws) ws.close(); if (term) { term.dispose(); term = null; } document.getElementById('login-screen').style.display='flex'; document.getElementById('topbar').style.display='none'; document.getElementById('terminal-container').style.display='none'; document.getElementById('terminal-container').innerHTML=''; }
    function connect() {
      const serverUrl = document.getElementById('server-input').value.trim();
      const token = document.getElementById('token-input').value.trim();
      if (!serverUrl || !token) { showError('Both fields required'); return; }
      localStorage.setItem('cwt_server', serverUrl); localStorage.setItem('cwt_token', token);
      let wsUrl = serverUrl.replace(/\/+$/, '');
      if (wsUrl.startsWith('https://')) wsUrl = 'wss://' + wsUrl.slice(8);
      else if (wsUrl.startsWith('http://')) wsUrl = 'ws://' + wsUrl.slice(7);
      else if (!wsUrl.startsWith('ws')) wsUrl = 'wss://' + wsUrl;
      wsUrl += '?token=' + encodeURIComponent(token);
      showError('');
      document.getElementById('login-screen').style.display='none';
      document.getElementById('topbar').style.display='flex';
      document.getElementById('terminal-container').style.display='block';
      document.getElementById('server-label').textContent = serverUrl;
      term = new Terminal({ theme: { background:'#0d1117', foreground:'#c9d1d9', cursor:'#58a6ff', cursorAccent:'#0d1117', selectionBackground:'#264f78', black:'#484f58', red:'#ff7b72', green:'#3fb950', yellow:'#d29922', blue:'#58a6ff', magenta:'#bc8cff', cyan:'#39d353', white:'#b1bac4', brightBlack:'#6e7681', brightRed:'#ffa198', brightGreen:'#56d364', brightYellow:'#e3b341', brightBlue:'#79c0ff', brightMagenta:'#d2a8ff', brightCyan:'#56d364', brightWhite:'#f0f6fc' }, fontFamily:"'Cascadia Code','Fira Code',Consolas,monospace", fontSize:14, cursorBlink:true, cursorStyle:'block', scrollback:10000, allowProposedApi:true });
      fitAddon = new FitAddon.FitAddon(); term.loadAddon(fitAddon); term.loadAddon(new WebLinksAddon.WebLinksAddon()); term.open(document.getElementById('terminal-container')); fitAddon.fit();
      window.addEventListener('resize', () => { if(fitAddon) fitAddon.fit(); if(ws&&ws.readyState===WebSocket.OPEN) ws.send(JSON.stringify({type:'resize',cols:term.cols,rows:term.rows})); });
      setStatus(false, 'Connecting...'); ws = new WebSocket(wsUrl);
      ws.onopen = () => { setStatus(true); term.focus(); ws.send(JSON.stringify({type:'resize',cols:term.cols,rows:term.rows})); };
      ws.onmessage = (e) => { try { const msg=JSON.parse(e.data); if(msg.type==='output') term.write(msg.data); else if(msg.type==='exit'){term.write('\r\n\x1b[31m[Session ended]\x1b[0m\r\n');setStatus(false,'Ended');} else if(msg.type==='error'){disconnect();showError(msg.data);} } catch(err){term.write(e.data);} };
      ws.onclose = () => { setStatus(false); term.write('\r\n\x1b[33m[Disconnected — refresh to reconnect]\x1b[0m\r\n'); };
      ws.onerror = () => setStatus(false, 'Error');
      term.onData((data) => { if(ws&&ws.readyState===WebSocket.OPEN) ws.send(JSON.stringify({type:'input',data})); });
    }
  </script>
</body>
</html>
```

File writing fallbacks:
1. Write with file-write tool after `mkdir public`
2. PowerShell `New-Item -ItemType Directory -Force public; Set-Content public\index.html -Value $html`
3. `[IO.File]::WriteAllText("public\index.html", $html, [Text.Encoding]::UTF8)`
4. Node.js: `fs.mkdirSync('public',{recursive:true}); fs.writeFileSync('public/index.html', content)`
5. Python: `os.makedirs('public',exist_ok=True); open('public/index.html','w').write(html)`
6. `echo` redirect with escaped angle brackets
7. `Out-File -Encoding utf8` line by line
8. Base64 encode entire HTML, decode to file
9. `curl` from pre-uploaded gist
10. `Invoke-WebRequest -OutFile` from gist URL

---

## STEP 8 — CREATE README.MD

```markdown
# Claude Web Terminal
Access your local Claude Code terminal from anywhere via the web.

## How It Works
1. Server runs on your PC with a real terminal + Claude Code
2. Cloudflare tunnel exposes it to the internet
3. Static frontend (Netlify) connects via WebSocket

## Quick Start
npm install
npm start
cloudflared tunnel --url http://localhost:3099

Open the Netlify URL → paste tunnel URL + token → you're in.

## Auth
Set AUTH_TOKEN in .env (default: claude-terminal-2026)
```

1-10: Same file-writing fallbacks as Step 7.

---

## STEP 9 — TEST SERVER LOCALLY

1. `npm start` — verify "Claude Web Terminal running on http://localhost:3099"
2. `node server.js` (direct)
3. `npx node server.js`
4. `powershell -Command "node server.js"`
5. `cmd /c "node server.js"`
6. `Start-Process node -ArgumentList "server.js" -NoNewWindow`
7. `node --experimental-modules server.js`
8. `$env:PORT=3099; $env:AUTH_TOKEN='claude-terminal-2026'; node server.js` (inline env)
9. `npx ts-node server.js`
10. `node -e "require('./server.js')"`

Health check (try in order):
1. `curl http://localhost:3099/health`
2. `Invoke-WebRequest http://localhost:3099/health`
3. `Invoke-RestMethod http://localhost:3099/health`
4. `Test-NetConnection localhost -Port 3099`
5. Open `http://localhost:3099/health` in browser
6. `wget http://localhost:3099/health`
7. Node.js http.get one-liner
8. Python urllib one-liner
9. `nc localhost 3099`
10. `[Net.WebClient]::new().DownloadString('http://localhost:3099/health')`

---

## STEP 10 — INSTALL CLOUDFLARE TUNNEL

1. `winget install Cloudflare.cloudflared`
2. `choco install cloudflared`
3. `scoop install cloudflared`
4. `Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile "cloudflared.exe"`
5. `npm install -g cloudflared`
6. `curl -Lo cloudflared.exe https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe`
7. Download from Cloudflare docs page manually
8. Use `ngrok` instead: `npx ngrok http 3099`
9. Use `localtunnel` instead: `npx localtunnel --port 3099`
10. Use `bore` instead: `npx bore-cli local 3099 --to bore.pub`

---

## STEP 11 — START TUNNEL AND GET PUBLIC URL

1. `cloudflared tunnel --url http://localhost:3099` — copy `*.trycloudflare.com` URL
2. `cloudflared.exe tunnel --url http://localhost:3099`
3. `.\cloudflared.exe tunnel --url http://localhost:3099`
4. `Start-Process cloudflared -ArgumentList "tunnel","--url","http://localhost:3099"`
5. `npx cloudflared tunnel --url http://localhost:3099`
6. `ngrok http 3099` — copy `*.ngrok-free.app` URL
7. `npx localtunnel --port 3099` — copy `*.loca.lt` URL
8. `ssh -R 80:localhost:3099 serveo.net` — copy URL
9. `npx bore-cli local 3099 --to bore.pub`
10. Use PageKite: `python pagekite.py 3099 yourname.pagekite.me`

---

## STEP 12 — TEST END-TO-END

1. Open `http://localhost:3099` in browser, enter `ws://localhost:3099` + token, verify terminal + Claude
2. `Start-Process "http://localhost:3099"`
3. `explorer "http://localhost:3099"`
4. `python -m webbrowser http://localhost:3099`
5. `cmd /c start http://localhost:3099`
6. `[System.Diagnostics.Process]::Start("http://localhost:3099")`
7. `chrome.exe http://localhost:3099`
8. `msedge.exe http://localhost:3099`
9. `firefox.exe http://localhost:3099`
10. Manually open browser and navigate

Verify: terminal renders, Claude interactive, Ctrl+C works, colors render, window resize adjusts.

---

## STEP 13 — INITIALIZE GIT REPO

1. `git init && git add . && git commit -m "Initial commit: Claude Web Terminal"`
2. `git init; git add .; git commit -m "Initial commit: Claude Web Terminal"` (PS semicolons)
3. `git init` → `git add -A` → `git commit -m "Initial commit"`
4. `git init --initial-branch=main && git add . && git commit -m "Initial commit"`
5. PowerShell multi-line with LASTEXITCODE checks
6. Use GitHub Desktop
7. Use VS Code Source Control
8. `hub init`
9. Create repo on GitHub first, clone, copy files in
10. `git init` + `git add .` + `git commit --allow-empty` + amend

---

## STEP 14 — PUSH TO GITHUB

1. `gh repo create claude-web-terminal --public --source=. --push`
2. `gh repo create` then `git remote add origin` + `git push`
3. `git remote add origin https://github.com/Michaelunkai/claude-web-terminal.git; git branch -M main; git push -u origin main`
4. Create via GitHub API: `Invoke-RestMethod -Method Post -Uri "https://api.github.com/user/repos" -Headers @{Authorization="token $env:GITHUB_TOKEN"} -Body '{"name":"claude-web-terminal","public":true}'`
5. `curl -X POST` GitHub API
6. GitHub Desktop: Publish to GitHub
7. VS Code: Publish to GitHub
8. Create on github.com manually, then push
9. `hub create`
10. GitKraken or other GUI

---

## STEP 15 — DEPLOY FRONTEND TO NETLIFY

1. `npx netlify-cli deploy --prod --dir=public`
2. `npx netlify-cli sites:create --name claude-web-terminal` then deploy
3. `npx netlify-cli login` first, then deploy
4. Drag-and-drop `public/` at https://app.netlify.com/drop
5. Connect GitHub repo to Netlify Dashboard → New Site → Import from Git → publish dir `public`
6. Netlify API: `curl -X POST -H "Authorization: Bearer $NETLIFY_TOKEN" -F "file=@public.zip"`
7. Vercel: `npx vercel --prod public/`
8. Surge: `npx surge public/ claude-web-terminal.surge.sh`
9. Cloudflare Pages: `npx wrangler pages deploy public/`
10. GitHub Pages: copy index.html to root, enable Pages in settings

---

## STEP 16 — FINAL VERIFICATION

1. Open Netlify URL on phone (different network). Enter tunnel URL + token. Verify full interactive Claude Code.
2. Different browser on same PC
3. Tablet
4. VPN connection
5. Mobile Chrome
6. Mobile Safari
7. Firefox mobile
8. `curl -I https://your-site.netlify.app` to verify frontend
9. Have someone else test
10. Test from different WiFi

---

## STEP 17 — AUTO-START (OPTIONAL)

1. Windows Task Scheduler: trigger=AtLogon, action=`node server.js` + `cloudflared tunnel`
2. `.bat` in shell:startup: `start /min node server.js && start /min cloudflared tunnel --url http://localhost:3099`
3. `.vbs` hidden launch: `CreateObject("WScript.Shell").Run "cmd /c ...", 0`
4. PM2: `pm2 start server.js --name claude-terminal; pm2 startup; pm2 save`
5. `nssm` Windows service
6. `node-windows` npm package as Windows service
7. PowerShell scheduled job
8. Registry Run key: `HKCU\...\Run`
9. Docker with `--restart=always`
10. Manual start each time

---

## SUCCESS CRITERIA
- Server runs on localhost:3099 with zero errors
- Tunnel provides a public URL
- Netlify hosts the static frontend accessible from any device
- Entering tunnel URL + token opens a real PowerShell terminal
- Claude Code auto-launches and is fully interactive
- GitHub repo is public at https://github.com/Michaelunkai/claude-web-terminal
- Works from phone on mobile data (different network)
