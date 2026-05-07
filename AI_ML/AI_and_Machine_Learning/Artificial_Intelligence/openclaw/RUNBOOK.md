# OpenClaw Runtime Runbook

## Non-Negotiables

- Keep the gateway tray-only unless the operator explicitly approves changing that contract.
- Do not re-enable the `OpenClaw Gateway` scheduled task as a repair.
- Do not create duplicate tray managers, tray icons, gateway nodes, or overlapping bot sessions.
- Treat active-work progress as mandatory every 30 seconds until verified completion.
- Recover missing async output locally before asking the operator what happened.

## Current-Truth Commands

- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Test-OpenClawCurrentTruth.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Invoke-OpenClawSmoke.ps1 -SkipTelegramNetwork -Json`
- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\Get-OpenClawCurrentTruthReport.ps1 -Json`

## Failure Symptoms

- Gateway appears down: first run `Test-OpenClawCurrentTruth.ps1`; treat TCP liveness, listener PID, manager PID, gateway PID, and tray ownership separately from deep readiness.
- Gateway is degraded: record the exact failed component before repair; do not flatten status timeout into process death.
- Sessions list hangs: use bounded local evidence recovery with `Get-OpenClawLatestEvidence.ps1` and avoid full transcript scans.
- Missing async output: run `Get-OpenClawLatestEvidence.ps1 -OutputPath openclaw-home\tmp\evidence.json`, inspect the produced file path and timestamps, then continue.
- Long job may disconnect: write checkpoints with `Write-OpenClawJobCheckpoint.ps1` and verify checkpoint updates with `Test-OpenClawDurableJob.ps1`.
- Slash command mutation: use `Set-OpenClawSlashCommand.ps1`; protected commands must be rejected and menu sync must happen after local verification.
- Telegram menu limit: only 100 commands are visible in the menu; typed dispatch must use the shared command catalog and not depend on visibility.
- Browser control conflict: identify existing Chrome/controller ownership before starting another controller.
- Restart needed: use `ProfileFunctions\Restart-OpenclawGateway.ps1`; verify one tray manager, one gateway node, listener on `127.0.0.1:18789`, and no scheduled gateway task re-enable afterward.

## Verification Ladder

- Narrow check: run the script that proves the changed behavior.
- Broader check: run `Invoke-OpenClawSmoke.ps1 -SkipTelegramNetwork -Json`.
- Live check: verify runtime PIDs/listener and Telegram/browser/user-visible behavior where relevant.
- Final report: separate verified facts, unverified claims, partial work, blocked work, and not-started work.
