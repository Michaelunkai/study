const { app, BrowserWindow, ipcMain, screen } = require('electron');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { execSync, exec } = require('child_process');

let win;
let trackerInterval = null;

// ── CONFIG ───────────────────────────────────────────────────────────────────
const STEAM_PATH = 'C:\\Program Files (x86)\\Steam';
const STEAM_USER_DATA = path.join(STEAM_PATH, 'userdata');
const SESSIONS_FILE = path.join(__dirname, 'playtime-sessions.json');

// ── LOAD / SAVE SESSIONS ─────────────────────────────────────────────────────
function loadSessions() {
  try { return JSON.parse(fs.readFileSync(SESSIONS_FILE, 'utf8')); } catch { return {}; }
}
function saveSessions(data) {
  fs.writeFileSync(SESSIONS_FILE, JSON.stringify(data, null, 2));
}

// ── PARSE STEAM VDF ──────────────────────────────────────────────────────────
function parseSteamPlaytimes() {
  const playtimes = {}; // appId -> minutes
  try {
    const userDirs = fs.readdirSync(STEAM_USER_DATA);
    for (const uid of userDirs) {
      const vdf = path.join(STEAM_USER_DATA, uid, 'config', 'localconfig.vdf');
      if (!fs.existsSync(vdf)) continue;
      const raw = fs.readFileSync(vdf, 'utf8');
      // Match app blocks: "appId" { ... "Playtime" "minutes" ... }
      const appBlocks = raw.matchAll(/"(\d+)"\s*\{([^{}]*(?:\{[^{}]*\}[^{}]*)*)\}/g);
      for (const m of appBlocks) {
        const appId = m[1];
        const block = m[2];
        const ptMatch = block.match(/"Playtime"\s+"(\d+)"/);
        if (ptMatch) {
          const mins = parseInt(ptMatch[1]);
          if (!playtimes[appId] || playtimes[appId] < mins) {
            playtimes[appId] = mins;
          }
        }
      }
    }
  } catch (e) { /* no steam or no access */ }
  return playtimes;
}

// ── GET RUNNING PROCESSES ────────────────────────────────────────────────────
function getRunningExes() {
  try {
    const out = execSync('powershell -NoProfile -Command "Get-Process | Select-Object -ExpandProperty Name"', {
      timeout: 5000, stdio: ['pipe','pipe','pipe']
    }).toString();
    return new Set(out.split('\n').map(l => l.trim().toLowerCase()).filter(Boolean));
  } catch { return new Set(); }
}

// ── GAME EXE MAP (appId -> known exe names) ──────────────────────────────────
const GAME_EXES = {
  '292030':  ['witcher3.exe'],
  '1517970': ['aeternanoctis.exe', 'aeterna.exe'],
  '1012880': ['60seconds.exe'],
  '1852570': ['arcrunner.exe'],
  '2134630': ['bayonetta2.exe'],
  '1623730': ['bagetter.exe'],
  '1659420': ['uncharted4.exe','uncharted_leg.exe'],
  '1030840': ['mafia.exe'],
  '2131630': ['mgsvtpp.exe','mgs3.exe'],
  '1343400': ['mgsvtpp.exe'],
  '235460':  ['revengeance.exe'],
  '1771950': ['banishers.exe'],
  '1313140': ['cultofthelamb.exe'],
  '960090':  ['btd6.exe'],
  '2305180': ['sparkinzero.exe','dragonballsparkinzero.exe'],
  '1245620': ['eldenring.exe'],
  '1088710': ['yakuza3.exe'],
  '612880':  ['newcolossus_x64vk.exe'],
  '233860':  ['kenshi_x64.exe'],
  '1369970': ['ng2b.exe','ninjagaiden2black.exe'],
  '1899570': ['rogueprince.exe'],
  '2701660': ['riseoftheronin.exe'],
  '368340':  ['crosscode.exe'],
  '1479610': ['blazblue.exe'],
  '1517970': ['aeternanoctis.exe'],
  '1819460': ['bo.exe','bopathtealotus.exe'],
  '1624800': ['tailsofiron.exe'],
};

// ── LIVE TRACKER ─────────────────────────────────────────────────────────────
let activeSessions = {}; // appId -> { startTime, gameName }

function startTracker(games) {
  if (trackerInterval) clearInterval(trackerInterval);
  // Build a reverse map: exeName -> { appId, name }
  const exeMap = {};
  for (const [appId, exes] of Object.entries(GAME_EXES)) {
    const game = games.find(g => g.steamId == appId);
    if (game) {
      for (const exe of exes) exeMap[exe] = { appId, name: game.name };
    }
  }

  trackerInterval = setInterval(() => {
    const running = getRunningExes();
    const sessions = loadSessions();
    const now = Date.now();

    // Check for newly started games
    for (const [exe, info] of Object.entries(exeMap)) {
      if (running.has(exe)) {
        if (!activeSessions[info.appId]) {
          activeSessions[info.appId] = { startTime: now, name: info.name };
          console.log(`[Tracker] Game started: ${info.name} (${info.appId})`);
        }
      } else {
        if (activeSessions[info.appId]) {
          // Game stopped — record session
          const elapsed = (now - activeSessions[info.appId].startTime) / 3600000; // hours
          const key = info.appId;
          sessions[key] = (sessions[key] || 0) + elapsed;
          saveSessions(sessions);
          console.log(`[Tracker] Game stopped: ${info.name}, added ${elapsed.toFixed(2)}h`);
          delete activeSessions[info.appId];
          // Notify renderer
          if (win && !win.isDestroyed()) win.webContents.send('playtime-updated', { appId: key, hours: sessions[key] });
        }
      }
    }
  }, 10000); // check every 10 seconds
}

// ── IPC ───────────────────────────────────────────────────────────────────────
ipcMain.handle('get-steam-playtimes', () => parseSteamPlaytimes());
ipcMain.handle('get-sessions', () => loadSessions());
ipcMain.handle('start-tracker', (_, games) => startTracker(games));
ipcMain.handle('get-active-sessions', () => activeSessions);

// ── WINDOW ───────────────────────────────────────────────────────────────────
app.whenReady().then(() => {
  const displays = screen.getAllDisplays();
  const targetDisplay = displays.length > 1 ? displays[1] : displays[0];
  const { x, y, width, height } = targetDisplay.bounds;

  win = new BrowserWindow({
    x, y, width, height,
    webPreferences: { nodeIntegration: true, contextIsolation: false },
    title: 'GameTime',
    backgroundColor: '#0d0d18',
    show: false,
    frame: true,
  });

  win.loadFile(path.join(__dirname, 'index.html'));
  win.once('ready-to-show', () => {
    win.show();
    win.setFullScreen(true);
  });
});

app.on('window-all-closed', () => {
  if (trackerInterval) clearInterval(trackerInterval);
  app.quit();
});
