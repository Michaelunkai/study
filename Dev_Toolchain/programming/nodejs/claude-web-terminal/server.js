require('dotenv').config();
const express = require('express');
const { WebSocketServer } = require('ws');
const http = require('http');
const path = require('path');
const { spawn } = require('child_process');
const fs = require('fs');
const multer = require('multer');

const app = express();
const PORT = process.env.PORT || 3099;
const AUTH_TOKEN = process.env.AUTH_TOKEN || 'claude-terminal-2026';

// File upload setup
const uploadsDir = path.join(__dirname, 'claude-terminal-uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir);
const storage = multer.diskStorage({
  destination: uploadsDir,
  filename: (req, file, cb) => cb(null, Date.now() + '-' + file.originalname)
});
const upload = multer({ storage, limits: { fileSize: 50 * 1024 * 1024 } });

// Rotating log setup
const LOG_FILE = path.join(__dirname, 'server.log');
const MAX_LOG_SIZE = 1024 * 1024; // 1MB
const MAX_LOG_FILES = 3;

function rotateLog() {
  try {
    if (fs.existsSync(LOG_FILE) && fs.statSync(LOG_FILE).size > MAX_LOG_SIZE) {
      for (let i = MAX_LOG_FILES - 1; i >= 1; i--) {
        const old = LOG_FILE + '.' + i;
        const newer = i === 1 ? LOG_FILE : LOG_FILE + '.' + (i - 1);
        if (fs.existsSync(newer)) fs.renameSync(newer, old);
      }
      fs.writeFileSync(LOG_FILE, '');
    }
  } catch (e) {}
}

function log(msg) {
  const line = new Date().toISOString() + ' ' + msg + '\n';
  process.stdout.write(line);
  try { rotateLog(); fs.appendFileSync(LOG_FILE, line); } catch (e) {}
}

// CORS headers for all origins (Netlify support)
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/health', (req, res) => res.json({ status: 'ok', uptime: process.uptime() }));

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

// Rate limiting: track failed auth attempts by IP
const failedAttempts = new Map();
const MAX_FAILURES = 3;

// #81: /status endpoint
app.get('/status', (req, res) => {
  res.json({ clientCount: wss.clients.size, uptime: process.uptime(), status: 'running', port: PORT });
});

// #86: /sessions endpoint - list session log files
app.get('/sessions', (req, res) => {
  const sessDir = path.join(__dirname, 'sessions');
  if (!fs.existsSync(sessDir)) return res.json([]);
  const files = fs.readdirSync(sessDir).filter(f => f.endsWith('.log'));
  res.json(files);
});

// #87: /upload endpoint - file drag-drop upload
app.post('/upload', upload.single('file'), (req, res) => {
  if (!req.file) { res.status(400).json({ error: 'No file' }); return; }
  log('File uploaded: ' + req.file.filename + ' (' + req.file.size + ' bytes)');
  res.json({ filename: req.file.filename, originalname: req.file.originalname, size: req.file.size });
});

// #86: /session/:filename - get session content for replay
app.get('/session/:filename', (req, res) => {
  const filename = path.basename(req.params.filename);
  const filePath = path.join(__dirname, 'sessions', filename);
  if (!fs.existsSync(filePath)) return res.status(404).json({ error: 'Not found' });
  res.setHeader('Content-Type', 'text/plain');
  res.send(fs.readFileSync(filePath));
});

wss.on('connection', (ws, req) => {
  const ip = req.socket.remoteAddress;

  // Rate limiting check
  const attempts = failedAttempts.get(ip) || 0;
  if (attempts >= MAX_FAILURES) {
    log(`[BLOCKED] IP ${ip} exceeded max failed auth attempts`);
    ws.close(1008, 'Too many failed attempts');
    return;
  }

  // Auth check via query param
  const url = new URL(req.url, 'http://localhost');
  const token = url.searchParams.get('token');
  if (token !== AUTH_TOKEN) {
    failedAttempts.set(ip, attempts + 1);
    log(`[AUTH FAIL] IP ${ip} attempt ${attempts + 1}/${MAX_FAILURES}`);
    ws.send(JSON.stringify({ type: 'error', data: 'Unauthorized' }));
    ws.close();
    return;
  }

  // Reset failed attempts on success
  failedAttempts.delete(ip);
  log(`[+] Client connected from ${ip}`);

  // Spawn powershell via child_process
  const shell = spawn('powershell.exe', ['-NoLogo', '-NoProfile'], {
    cwd: process.env.USERPROFILE || process.env.HOME || 'C:\\',
    env: process.env,
    stdio: ['pipe', 'pipe', 'pipe']
  });

  // Session recording
  const sessionsDir = path.join(__dirname, 'sessions');
  if (!fs.existsSync(sessionsDir)) fs.mkdirSync(sessionsDir);
  const sessionFile = path.join(sessionsDir, 'session-' + new Date().toISOString().replace(/[:.]/g, '_') + '.log');
  const sessionStream = fs.createWriteStream(sessionFile, { flags: 'a' });

  let alive = true;

  shell.stdout.on('data', d => {
    sessionStream.write(d);
    if (ws.readyState === 1) ws.send(JSON.stringify({ type: 'output', data: d.toString() }));
  });
  shell.stderr.on('data', d => {
    sessionStream.write(d);
    if (ws.readyState === 1) ws.send(JSON.stringify({ type: 'output', data: d.toString() }));
  });
  shell.on('exit', code => {
    alive = false;
    log(`[-] Shell exited with code ${code} for ${ip}`);
    try {
      ws.send(JSON.stringify({ type: 'exit', code }));
      ws.close();
    } catch (e) {}
  });

  ws.on('message', msg => {
    try {
      const m = JSON.parse(msg);
      if (m.type === 'input' && alive && shell.stdin.writable) shell.stdin.write(m.data);
    } catch (e) {
      // raw text fallback
      if (alive && shell.stdin.writable) shell.stdin.write(msg);
    }
  });

  ws.on('close', () => {
    alive = false;
    log(`[-] Client disconnected from ${ip}`);
    if (!shell.killed) shell.kill();
    if (sessionStream) { try { sessionStream.end(); } catch (e) {} }
  });

  ws.on('error', err => {
    console.error(`[WS ERROR] ${ip}: ${err.message}`);
  });

  // Ping/pong keepalive every 30s
  const pingInterval = setInterval(() => {
    if (ws.readyState === 1) {
      ws.ping();
    } else {
      clearInterval(pingInterval);
    }
  }, 30000);

  ws.on('pong', () => { /* client alive */ });
});

server.listen(PORT, () => {
  log('Claude Web Terminal running on http://localhost:' + PORT);
  log('Auth token: ' + AUTH_TOKEN);
  log('Status: http://localhost:' + PORT + '/status');
  log('To expose publicly: cloudflared tunnel --url http://localhost:' + PORT);
});
