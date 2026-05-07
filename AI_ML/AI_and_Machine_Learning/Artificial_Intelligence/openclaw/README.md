# OpenClaw Local Runtime Harness

This folder is the local Windows home for OpenClaw on this machine. It keeps the scripts, live configuration surface, tray-manager source, and helper docs needed to run OpenClaw bots and the local gateway.

The goal of this harness is simple: keep the folder as small as possible in Git and on disk, while still making the runtime rebuildable whenever it is needed.

## What OpenClaw Is Supposed To Achieve

OpenClaw is a local AI gateway and bot runtime. On this machine it is used to run the local gateway, keep Telegram bot workspaces mapped, expose browser/tool capabilities, and keep the tray-managed OpenClaw process available without duplicate tray managers or duplicate bot sessions.

The durable files are source, scripts, configuration, and docs. The heavy files are generated runtime installs, rollback payloads, version snapshots, reports, browser/media caches, .NET build output, npm `node_modules`, and old executable backups. Those heavy files can be recreated or are not required for the source of truth.

## Start Or Rebuild Everything

Run this whenever OpenClaw needs to be rebuilt and started:

```powershell
cd F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw
.\Rebuild-AndRun-OpenClaw.ps1
```

To force a clean rebuild first:

```powershell
.\Rebuild-AndRun-OpenClaw.ps1 -CleanFirst
```

What it does:

- reinstalls `openclaw@2026.4.21` and `clawdbot@2026.1.24-3` into the local `npm-global` prefix
- rebuilds `ClawdBot\ClawdBotManager.exe` from the local .NET source
- downloads a disposable local .NET SDK cache only if the system .NET SDK cannot publish the tray manager
- sets `OPENCLAW_HOME` to this folder's `openclaw-home`
- starts/restarts the gateway through the existing OpenClaw profile restart script when available

## Clean To Smallest Safe Size

Run this when you want this folder to use the smallest practical amount of space:

```powershell
cd F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw
.\Cleanup-OpenClawSpace.ps1 -Force
```

The cleanup script removes only explicit generated targets inside this project, including:

- `Setup\payload`
- `versions`
- heavy rollback report folders
- `npm-global\node_modules`
- `.NET` build output under `ClawdBot\src`
- generated tray-manager executables and executable backups
- temporary SDK downloads
- the disposable `.openclaw-cache` rebuild cache
- browser/media/tmp/log caches under `openclaw-home`
- nested project dependency/deployment outputs such as `node_modules`, `.next`, `.netlify`, `dist`, and `build`

It does not remove:

- `openclaw-home\openclaw.json`
- scripts under `scripts` and `ProfileFunctions`
- tray-manager source under `ClawdBot\src`
- workspace source/config folders
- Git metadata
- anything outside this folder

## Verify Current Runtime Truth

After rebuilding or starting, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Test-OpenClawCurrentTruth.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Invoke-OpenClawSmoke.ps1 -SkipTelegramNetwork -Json
```

Those checks are the first proof points for gateway/process/listener health. For deeper operational details, read `RUNBOOK.md`.

## Git Policy

This repo intentionally ignores generated runtime state and secrets. The live `openclaw-home\openclaw.json` is local machine configuration and must stay out of Git.
