# Telegram Command Repair Report

## 1. Runtime source of truth
- Hidden tray launcher: `F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ClawdBot\ClawdbotTray.vbs`
- Live manager: PID 15008 -> `F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ClawdBot\ClawdBotManager.exe`
- Live gateway child: PID 8376 -> `"C:\Program Files\nodejs\node.exe" "F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\node_modules\openclaw\dist\index.js" gateway run --port 18789`
- Live config: `C:\Users\micha\.clawdbot\openclaw.json`
- Live dist/runtime: `F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\node_modules\openclaw\dist\index.js`
- Port proof: `  TCP    127.0.0.1:18789        0.0.0.0:0              LISTENING       8376`

## 2. Bot inventory
- bot1 @Mmichael_moltbot_bot live via Telegram Bot API getMyCommands: count=90, /nnew=False, /sync=False, /time=True, /until_done=True
- bot2 @Mmmoltbot_bot live via Telegram Bot API getMyCommands: count=90, /nnew=False, /sync=False, /time=True, /until_done=True
- openclaw @Michaopenclawbot live via Telegram Bot API getMyCommands: count=90, /nnew=False, /sync=False, /time=True, /until_done=True
- openclaw4 @Openclaw4michabot live via Telegram Bot API getMyCommands: count=90, /nnew=False, /sync=False, /time=True, /until_done=True

## 3. Recovered command catalog
- Current live skill surface: 90 commands recovered from the workspace skill snapshots shared across all 4 agents.
- Legacy Claude/Codex command docs inspected: 53.
- Historical script-only Telegram commands inspected: 49.
- Full catalog and matrix: `F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\reports\telegram-command-matrix-2026-04-22.json`

## 4. Final Telegram command matrix
- Registered Telegram menu commands on each bot: 90
- Registered commands all use the same repaired 90-command surface across bot1, bot2, openclaw, and openclaw4.
- Resolver parity sweep after the live dist patch: 90/90 Telegram commands map to the intended recovered skill entry, including underscore Telegram names such as `/done_job`, `/until_done`, and `/verification_loop`.
- Prompt-template sweep after the live dist patch: 90/90 current Telegram skill commands now carry a real prompt template into slash execution, so commands like `/done`, `/done_job`, `/until_done`, and `/verification_loop` no longer collapse to the generic `Use the "<skill>" skill for this request.` fallback.
- Scope-sync sweep after the live dist patch: default, `all_private_chats`, `all_group_chats`, and `all_chat_administrators` all return the same 90-command surface on all 4 bots; stale generic entries like `/debug` and `/start` are no longer registered in the chat scopes Telegram was still showing.
- Slash-parse sweep after the live dist patch: 90/90 commands parse successfully in both `/name ...` and `/skill original-name ...` forms across all 4 workspaces.
- Prompt-expansion sweep after the live dist patch: 90/90 commands expand to a non-empty prompt body across all 4 workspaces.
- Live user proof now exists: the user confirmed `/done` works exactly as intended after the runtime fix.
- Telegram description drift that still appears in Bot API output is only platform truncation with `…` for long descriptions; it is not a generic-description regression and does not affect the full execution prompt body.
- Matrix rows in the JSON bundle include: bot, command, final mapping, status, intended behavior, and proof.

## 5. Files changed
- `C:\Users\micha\.clawdbot\openclaw.json` - Restored 90-command Telegram custom menu across all 4 bots, kept native=false, and preserved shared real config source of truth.
- `F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\node_modules\openclaw\dist\commands-registry-list-MHrd1pp9.js` - Added underscore aliases for hyphenated skills so Telegram-safe menu commands resolve to the real skill command surface.
- `F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\node_modules\openclaw\dist\skill-commands-base-nbFzbjGB.js` - Patched direct slash skill resolution so Telegram-safe underscore commands resolve to their hyphenated or case-variant skill implementations in the generic text/slash dispatch path.
- `F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\node_modules\openclaw\dist\skills-Cwx5TftI.js` - Patched workspace skill command spec generation so Telegram slash commands carry the full stripped `SKILL.md` prompt template into execution instead of only the skill name and description.
- `F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\node_modules\openclaw\dist\extensions\telegram\bot-Ch7__EHu.js` - Patched Telegram menu sync so the repaired command surface is registered and cleared across default, private-chat, group-chat, and admin scopes instead of only the default scope.

## 6. Remaining blockers
- No safe authenticated user-side Telegram sender path is available inside this environment.
- Evidence: Telegram Bot API can only manage bot state and cannot originate user-to-bot messages.
- Evidence: Playwright MCP browser bridge still fails with extension connection timeout.
- Evidence: No existing Telethon or GramJS session was found in the requested OpenClaw, Codex, or Claude roots, and launching Telegram Desktop or Web directly would violate the no-popup and no-overlap constraint.
- Next input/access needed: Send one real command such as /time 1 test from any one of the 4 bot chats and tell me which bot you used, or provide a pre-authenticated non-popup Telegram user client/session path I can control.
