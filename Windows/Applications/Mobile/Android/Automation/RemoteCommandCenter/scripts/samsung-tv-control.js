"use strict";

const http = require("node:http");

const tvHost = (process.env.SAMSUNG_TV_HOST || "").trim();
const tvPort = Number(process.env.SAMSUNG_TV_HTTP_PORT || 8001);
const bridgeUrl = process.env.RCC_TV_BRIDGE_URL ||
  `http://127.0.0.1:${Number(process.env.RCC_TV_BRIDGE_PORT || 8781)}`;
const keyPattern = /^KEY_[A-Z0-9_]+$/;
const appIdPattern = /^[A-Za-z0-9._-]+$/;

function postJson(urlText, payload, timeoutMs = 7000) {
  const url = new URL(urlText);
  if (url.protocol !== "http:") throw new Error("Only local/private HTTP endpoints are supported.");

  const body = JSON.stringify(payload);
  return new Promise((resolve, reject) => {
    const request = http.request(url, {
      method: "POST",
      timeout: timeoutMs,
      headers: {
        "content-type": "application/json",
        "content-length": Buffer.byteLength(body),
      },
    }, response => {
      let responseBody = "";
      response.setEncoding("utf8");
      response.on("data", chunk => { responseBody += chunk; });
      response.on("end", () => {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          reject(new Error(`HTTP ${response.statusCode} from ${url.host}${url.pathname}`));
          return;
        }
        resolve({ statusCode: response.statusCode, body: responseBody });
      });
    });
    request.on("timeout", () => request.destroy(new Error(`Request timed out: ${url.host}${url.pathname}`)));
    request.on("error", reject);
    request.end(body);
  });
}

function validateKey(key) {
  if (!keyPattern.test(key)) throw new Error(`Invalid Samsung remote key: ${key}`);
  return key;
}

async function sendKey(key, holdMs = 0) {
  validateKey(key);
  if (!Number.isInteger(holdMs) || holdMs < 0 || holdMs > 20000) {
    throw new Error("Key hold duration must be an integer from 0 to 20000 milliseconds.");
  }
  const response = await postJson(new URL("/key", bridgeUrl).toString(), {
    key,
    cmd: "Click",
    holdMs,
  }, Math.max(5000, holdMs + 4000));
  const result = JSON.parse(response.body || "{}");
  if (result.ok !== true) throw new Error(result.error || "TV bridge did not acknowledge the key.");
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function parseDelay(args) {
  const option = args.find(value => value.startsWith("--delay-ms="));
  if (!option) return 0;
  const value = Number(option.slice("--delay-ms=".length));
  if (!Number.isInteger(value) || value < 0 || value > 5000) {
    throw new Error("Sequence delay must be an integer from 0 to 5000 milliseconds.");
  }
  return value;
}

async function main() {
  const [command, ...args] = process.argv.slice(2);

  if (command === "app") {
    const appId = args[0] || "";
    if (!appIdPattern.test(appId)) throw new Error("A valid Samsung TV application ID is required.");
    if (!tvHost) throw new Error("SAMSUNG_TV_HOST is required for the app command.");
    const appUrl = `http://${tvHost}:${tvPort}/api/v2/applications/${encodeURIComponent(appId)}`;
    await postJson(appUrl, {}, 8000);
    return;
  }

  if (command === "sequence") {
    const delayMs = parseDelay(args);
    const keys = args.filter(value => !value.startsWith("--"));
    if (keys.length === 0) throw new Error("At least one remote key is required for a sequence.");
    for (let index = 0; index < keys.length; index += 1) {
      if (index > 0 && delayMs > 0) await sleep(delayMs);
      await sendKey(keys[index]);
    }
    return;
  }

  if (command === "send") {
    await sendKey(args[0] || "");
    return;
  }

  if (command === "hold") {
    const holdMs = Number(args[1]);
    if (!Number.isInteger(holdMs)) throw new Error("A key hold duration in milliseconds is required.");
    await sendKey(args[0] || "", holdMs);
    return;
  }

  throw new Error("Usage: samsung-tv-control.js app <appId> | sequence [--delay-ms=N] <keys...> | send <key> | hold <key> <milliseconds>");
}

main().catch(error => {
  process.stderr.write(`Samsung TV helper failed: ${error.message || String(error)}\n`);
  process.exitCode = 1;
});
