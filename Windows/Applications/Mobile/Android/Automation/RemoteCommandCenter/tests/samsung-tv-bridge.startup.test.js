"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");
const { spawn } = require("node:child_process");
const { test } = require("node:test");
const { WebSocketServer } = require("../scripts/node_modules/ws");

const bridgePath = path.join(__dirname, "..", "scripts", "samsung-tv-bridge.js");

function listen(server, host = "127.0.0.1") {
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, host, () => resolve(server.address().port));
  });
}

function close(server) {
  return new Promise((resolve, reject) => {
    server.close(error => error ? reject(error) : resolve());
  });
}

function delay(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function waitForLog(logPath, text, child) {
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    if (child.exitCode !== null) throw new Error(`Bridge exited early with ${child.exitCode}.`);
    if (fs.existsSync(logPath) && fs.readFileSync(logPath, "utf8").includes(text)) return;
    await delay(50);
  }
  throw new Error(`Timed out waiting for bridge log: ${text}`);
}

function requestJson(port, method, pathname, body) {
  return new Promise((resolve, reject) => {
    const payload = body === undefined ? "" : JSON.stringify(body);
    const request = http.request({
      host: "127.0.0.1",
      port,
      method,
      path: pathname,
      headers: body === undefined ? {} : {
        "content-type": "application/json",
        "content-length": Buffer.byteLength(payload),
      },
    }, response => {
      let text = "";
      response.setEncoding("utf8");
      response.on("data", chunk => { text += chunk; });
      response.on("end", () => {
        try { resolve({ status: response.statusCode, body: JSON.parse(text || "{}") }); }
        catch (error) { reject(error); }
      });
    });
    request.on("error", reject);
    request.end(payload);
  });
}

test("TV bridge stays local and idle until a command, then uses the private config token", async () => {
  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "rcc-tv-bridge-"));
  const logPath = path.join(tempDir, "tv-bridge.log");
  const configPath = path.join(tempDir, "rcc-config.json");
  const tokenPath = path.join(tempDir, "samsung-tv-token.json");
  fs.writeFileSync(configPath, JSON.stringify({ TvHost: "127.0.0.1", TvToken: "test-config-token" }));

  let restRequests = 0;
  let websocketConnections = 0;
  let websocketToken = "";
  const remoteCommands = [];
  const tvHttp = http.createServer((request, response) => {
    restRequests += 1;
    response.writeHead(200, { "content-type": "application/json" }).end("{}");
  });
  const tvHttpPort = await listen(tvHttp);
  const tvWebSocket = new WebSocketServer({ host: "127.0.0.1", port: 0 });
  await new Promise(resolve => tvWebSocket.once("listening", resolve));
  const tvWebSocketPort = tvWebSocket.address().port;
  tvWebSocket.on("connection", (socket, request) => {
    websocketConnections += 1;
    websocketToken = new URL(request.url, "http://localhost").searchParams.get("token") || "";
    socket.on("message", data => remoteCommands.push(JSON.parse(data.toString())));
    socket.send(JSON.stringify({ event: "ms.channel.connect", data: { token: "mock-issued-token" } }));
  });

  const portProbe = http.createServer();
  const bridgePort = await listen(portProbe);
  await close(portProbe);

  const child = spawn(process.execPath, [bridgePath], {
    env: {
      ...process.env,
      NODE_ENV: "test",
      RCC_CONFIG_PATH: configPath,
      RCC_LOG_DIR: tempDir,
      RCC_TV_BRIDGE_LOG: logPath,
      RCC_TV_BRIDGE_PORT: String(bridgePort),
      SAMSUNG_TV_CLIENT_NAME: "RCC test client",
      SAMSUNG_TV_HOST: "127.0.0.1",
      SAMSUNG_TV_HTTP_PORT: String(tvHttpPort),
      SAMSUNG_TV_TOKEN_PATH: tokenPath,
      RCC_TEST_TV_WS_PROTOCOL: "ws",
      SAMSUNG_TV_WS_PORT: String(tvWebSocketPort),
    },
    stdio: "ignore",
    windowsHide: true,
  });

  try {
    await waitForLog(logPath, "TV_BRIDGE_LISTEN", child);
    await delay(200);
    assert.equal(websocketConnections, 0, "startup must not open a TV control channel");
    assert.equal(restRequests, 0, "startup must not probe the TV");

    const status = await requestJson(bridgePort, "GET", "/status");
    assert.equal(status.status, 200);
    assert.equal(status.body.bridge, "ready");
    assert.equal(status.body.tvApi, true);
    assert.equal(status.body.wsReady, false);
    assert.equal(status.body.token, true);
    assert.equal(websocketConnections, 0, "status must not pair or open a remote-control channel");

    const command = await requestJson(bridgePort, "POST", "/key", { key: "KEY_HOME" });
    assert.equal(command.status, 200, JSON.stringify(command.body));
    assert.deepEqual(command.body, { ok: true, key: "KEY_HOME", cmd: "Click", holdMs: 0 });
    assert.equal(websocketConnections, 1);
    assert.equal(websocketToken, "test-config-token");
    assert.deepEqual(remoteCommands.map(item => item.params.DataOfCmd), ["KEY_HOME"]);
    assert.equal(JSON.parse(fs.readFileSync(tokenPath, "utf8")).token, "mock-issued-token");
  } finally {
    if (child.exitCode === null) {
      await new Promise(resolve => {
        child.once("exit", resolve);
        child.kill();
      });
    }
    await close(tvWebSocket);
    await close(tvHttp);
    fs.rmSync(tempDir, { recursive: true, force: true });
  }
});
