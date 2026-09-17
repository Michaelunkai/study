"use strict";

const assert = require("node:assert/strict");
const http = require("node:http");
const path = require("node:path");
const { spawn } = require("node:child_process");
const { test } = require("node:test");

const helperPath = path.join(__dirname, "..", "scripts", "samsung-tv-control.js");

function listen(handler) {
  const server = http.createServer(handler);
  return new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", () => resolve(server));
  });
}

function close(server) {
  return new Promise((resolve, reject) => {
    server.close(error => error ? reject(error) : resolve());
  });
}

function runHelper(args, env) {
  return new Promise((resolve, reject) => {
    const child = spawn(process.execPath, [helperPath, ...args], {
      env: { ...process.env, ...env },
      windowsHide: true,
      stdio: ["ignore", "pipe", "pipe"],
    });
    let stdout = "";
    let stderr = "";
    const timeout = setTimeout(() => child.kill(), 10000);
    child.stdout.setEncoding("utf8").on("data", chunk => { stdout += chunk; });
    child.stderr.setEncoding("utf8").on("data", chunk => { stderr += chunk; });
    child.once("error", error => {
      clearTimeout(timeout);
      reject(error);
    });
    child.once("close", code => {
      clearTimeout(timeout);
      resolve({ code, stdout, stderr });
    });
  });
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let body = "";
    req.setEncoding("utf8");
    req.on("data", chunk => { body += chunk; });
    req.on("end", () => {
      try { resolve(JSON.parse(body || "{}")); } catch (error) { reject(error); }
    });
    req.on("error", reject);
  });
}

test("app command posts only the requested app ID to the Samsung REST endpoint", async () => {
  let observed;
  const server = await listen(async (req, res) => {
    observed = { method: req.method, url: req.url, body: await readJson(req) };
    res.writeHead(200, { "content-type": "application/json" }).end("{}");
  });
  const port = server.address().port;
  try {
    const result = await runHelper(["app", "3202306031311", "NATIVE_LAUNCH"], {
      SAMSUNG_TV_HOST: "127.0.0.1",
      SAMSUNG_TV_HTTP_PORT: String(port),
    });
    assert.equal(result.code, 0, result.stderr);
    assert.deepEqual(observed, {
      method: "POST",
      url: "/api/v2/applications/3202306031311",
      body: {},
    });
  } finally {
    await close(server);
  }
});

test("app command requires an explicit TV host and sends no request when it is missing", async () => {
  let requestCount = 0;
  const server = await listen((req, res) => {
    requestCount += 1;
    res.writeHead(200, { "content-type": "application/json" }).end("{}");
  });
  try {
    const result = await runHelper(["app", "3202306031311"], {
      SAMSUNG_TV_HOST: undefined,
      SAMSUNG_TV_HTTP_PORT: String(server.address().port),
    });
    assert.equal(result.code, 1);
    assert.match(result.stderr, /SAMSUNG_TV_HOST is required for the app command/);
    assert.equal(requestCount, 0);
  } finally {
    await close(server);
  }
});

test("sequence, send, and hold commands are correlated with the local TV bridge", async () => {
  const observed = [];
  const server = await listen(async (req, res) => {
    observed.push({ method: req.method, url: req.url, body: await readJson(req) });
    res.writeHead(200, { "content-type": "application/json" }).end(JSON.stringify({ ok: true }));
  });
  const bridgeUrl = `http://127.0.0.1:${server.address().port}`;
  try {
    const sequence = await runHelper([
      "sequence", "--delay-ms=0", "KEY_DOWN", "KEY_LEFT", "KEY_ENTER",
    ], { RCC_TV_BRIDGE_URL: bridgeUrl });
    assert.equal(sequence.code, 0, sequence.stderr);
    assert.deepEqual(observed.map(item => item.body.key), ["KEY_DOWN", "KEY_LEFT", "KEY_ENTER"]);

    const send = await runHelper(["send", "KEY_MUTE"], { RCC_TV_BRIDGE_URL: bridgeUrl });
    assert.equal(send.code, 0, send.stderr);
    const hold = await runHelper(["hold", "KEY_HOME", "900"], { RCC_TV_BRIDGE_URL: bridgeUrl });
    assert.equal(hold.code, 0, hold.stderr);
    assert.deepEqual(observed.slice(-2).map(item => item.body), [
      { key: "KEY_MUTE", cmd: "Click", holdMs: 0 },
      { key: "KEY_HOME", cmd: "Click", holdMs: 900 },
    ]);
  } finally {
    await close(server);
  }
});

test("invalid keys are rejected before any bridge request", async () => {
  let requestCount = 0;
  const server = await listen((req, res) => {
    requestCount += 1;
    res.writeHead(200, { "content-type": "application/json" }).end("{\"ok\":true}");
  });
  try {
    const result = await runHelper(["send", "KEY_HOME;shutdown"], {
      RCC_TV_BRIDGE_URL: `http://127.0.0.1:${server.address().port}`,
    });
    assert.equal(result.code, 1);
    assert.match(result.stderr, /Invalid Samsung remote key/);
    assert.equal(requestCount, 0);
  } finally {
    await close(server);
  }
});
