const fs = require("fs");
const path = require("path");
const http = require("http");
const https = require("https");
let WebSocket;
try {
  WebSocket = require("ws");
} catch {
  WebSocket = require("C:\\Users\\micha\\.codex\\tools\\tv\\node_modules\\ws");
}

const host = process.env.SAMSUNG_TV_HOST || "192.168.1.173";
const port = Number(process.env.RCC_TV_BRIDGE_PORT || 8781);
const clientName = process.env.SAMSUNG_TV_CLIENT_NAME || "Codex Samsung Remote";
const tokenPath = process.env.SAMSUNG_TV_TOKEN_PATH || path.join(
  process.env.USERPROFILE || "C:\\Users\\micha",
  ".codex",
  "state",
  "tv",
  "samsung-tv-token.json",
);
const logPath = process.env.RCC_TV_BRIDGE_LOG || path.join(
  process.env.RCC_LOG_DIR || path.join(process.cwd(), "runtime", "logs"),
  "tv-bridge.log",
);

let ws = null;
let connectPromise = null;
let ready = false;
let lastConnectError = "";

function log(message) {
  fs.mkdirSync(path.dirname(logPath), { recursive: true });
  fs.appendFileSync(logPath, `[${new Date().toISOString()}] ${message}\n`);
}

function readToken() {
  try {
    if (!fs.existsSync(tokenPath)) return "";
    return JSON.parse(fs.readFileSync(tokenPath, "utf8")).token || "";
  } catch {
    return "";
  }
}

function saveToken(token) {
  fs.mkdirSync(path.dirname(tokenPath), { recursive: true });
  fs.writeFileSync(
    tokenPath,
    JSON.stringify({ host, clientName, token, savedAt: new Date().toISOString() }, null, 2),
  );
}

function websocketUrl() {
  const encodedName = Buffer.from(clientName, "utf8").toString("base64");
  const params = new URLSearchParams({ name: encodedName });
  const token = readToken();
  if (token) params.set("token", token);
  return `wss://${host}:8002/api/v2/channels/samsung.remote.control?${params}`;
}

function requestJson(url, timeoutMs = 1800) {
  const lib = url.startsWith("https:") ? https : http;
  return new Promise((resolve, reject) => {
    const req = lib.get(url, { rejectUnauthorized: false, timeout: timeoutMs }, (res) => {
      let body = "";
      res.setEncoding("utf8");
      res.on("data", chunk => { body += chunk; });
      res.on("end", () => {
        try {
          resolve(JSON.parse(body || "{}"));
        } catch (err) {
          reject(err);
        }
      });
    });
    req.on("timeout", () => req.destroy(new Error(`Timeout ${url}`)));
    req.on("error", reject);
  });
}

function connectTv() {
  if (ws && ready && ws.readyState === WebSocket.OPEN) return Promise.resolve(ws);
  if (connectPromise) return connectPromise;

  ready = false;
  connectPromise = new Promise((resolve, reject) => {
    const next = new WebSocket(websocketUrl(), { rejectUnauthorized: false });
    const timer = setTimeout(() => {
      try { next.terminate(); } catch {}
      reject(new Error("TV websocket authorization/connect timeout"));
    }, 4500);

    next.on("message", (data) => {
      const text = data.toString();
      let msg = {};
      try { msg = JSON.parse(text); } catch {}
      if (msg.event === "ms.channel.connect") {
        const token = msg.data && msg.data.token;
        if (token) saveToken(token);
        clearTimeout(timer);
        ws = next;
        ready = true;
        lastConnectError = "";
        log(`TV_WS_READY host=${host} token=${readToken() ? "yes" : "no"}`);
        resolve(next);
      }
    });

    next.on("error", (err) => {
      clearTimeout(timer);
      lastConnectError = err && (err.message || String(err));
      log(`TV_WS_ERROR ${lastConnectError}`);
      reject(err);
    });

    next.on("close", () => {
      if (ws === next) {
        ready = false;
        ws = null;
      }
      connectPromise = null;
      log("TV_WS_CLOSED");
    });
  }).finally(() => {
    connectPromise = null;
  });

  return connectPromise;
}

function sendFrame(socket, key, cmd = "Click") {
  socket.send(JSON.stringify({
    method: "ms.remote.control",
    params: {
      Cmd: cmd,
      DataOfCmd: key,
      Option: "false",
      TypeOfRemote: "SendRemoteKey",
    },
  }));
}

async function sendKey(key, cmd = "Click", holdMs = 0) {
  const socket = await connectTv();
  if (holdMs > 0) {
    sendFrame(socket, key, "Press");
    await new Promise(resolve => setTimeout(resolve, Math.max(500, Math.min(Number(holdMs) || 6500, 20000))));
    sendFrame(socket, key, "Release");
  } else {
    sendFrame(socket, key, cmd || "Click");
  }
  log(`TV_KEY_SENT key=${key} cmd=${cmd || "Click"} holdMs=${holdMs || 0}`);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.setEncoding("utf8");
    req.on("data", chunk => { body += chunk; });
    req.on("end", () => resolve(body));
    req.on("error", reject);
  });
}

function writeJson(res, status, body) {
  const text = JSON.stringify(body);
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "content-length": Buffer.byteLength(text),
  });
  res.end(text);
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === "GET" && req.url === "/status") {
      let api = null;
      try { api = await requestJson(`http://${host}:8001/api/v2/`, 1400); } catch {}
      writeJson(res, 200, {
        ok: true,
        bridge: "ready",
        tvHost: host,
        tvApi: !!api,
        wsReady: !!(ws && ready && ws.readyState === WebSocket.OPEN),
        token: !!readToken(),
        lastConnectError,
      });
      return;
    }

    if (req.method === "POST" && req.url === "/key") {
      const payload = JSON.parse(await readBody(req) || "{}");
      const key = String(payload.key || "KEY_HOME");
      const cmd = String(payload.cmd || "Click");
      const holdMs = Number(payload.holdMs || 0);
      await sendKey(key, cmd, holdMs);
      writeJson(res, 200, { ok: true, key, cmd, holdMs });
      return;
    }

    writeJson(res, 404, { ok: false, error: "not found" });
  } catch (err) {
    writeJson(res, 500, { ok: false, error: err && (err.message || String(err)) });
  }
});

server.listen(port, "127.0.0.1", () => {
  log(`TV_BRIDGE_LISTEN port=${port} host=${host} clientName=${clientName}`);
  connectTv().catch(err => log(`TV_BRIDGE_INITIAL_CONNECT_FAILED ${err.message || err}`));
});

setInterval(() => {
  connectTv().catch(err => log(`TV_BRIDGE_RECONNECT_FAILED ${err.message || err}`));
}, 15000).unref();
