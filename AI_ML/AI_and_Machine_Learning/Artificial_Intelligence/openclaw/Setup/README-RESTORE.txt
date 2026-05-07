OpenClaw machine restore bundle
================================

Generated from live inspection of this machine on 2026-04-28.

What this batch does
--------------------
1. Recreates the expected F:-drive OpenClaw folder layout.
2. Recreates the user npm global prefix at %LOCALAPPDATA%\npm-global.
3. Rewrites %USERPROFILE%\.npmrc with prefix=%LOCALAPPDATA%\npm-global.
4. Sets OPENCLAW_STATE_DIR / OPENCLAW_CONFIG_PATH / OPENCLAW_TMP_DIR.
5. Installs @openai/codex globally.
6. Rebuilds OpenClaw wrappers via scripts\Ensure-OpenClawCommandSurface.ps1.
7. Rewrites openclaw-home\gateway.cmd.
8. Recreates scheduled tasks:
   - ClawdBotTray
   - OpenClaw Gateway (left disabled to match the current machine)
9. Restores payload folders if you place them under Setup\payload\...
10. Verifies the gateway command surface.

Important limitation
--------------------
This cannot magically recreate private auth/state from the internet by itself.
To reproduce this machine closely, you should also place copies of the live state under:

Setup\payload\openclaw-home
Setup\payload\user-openclaw
Setup\payload\npm-global
Setup\payload\appdata-roaming-npm

Recommended payload sources from this machine
---------------------------------------------
F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\openclaw-home
C:\Users\micha\.openclaw
F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global
C:\Users\micha\AppData\Roaming\npm

Critical live facts the script is based on
------------------------------------------
- Node.js expected at: C:\Program Files\nodejs\node.exe
- npm user prefix: C:\Users\micha\AppData\Local\npm-global
- Canonical OpenClaw repo root:
  F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw
- Canonical state root:
  F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\openclaw-home
- Additional user state root:
  C:\Users\micha\.openclaw
- Tray startup task launches:
  F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\ClawdBot\ClawdbotTray.vbs
- Gateway task target:
  F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\openclaw-home\gateway.cmd
- Gateway port: 18789

After running
-------------
1. Sign out/in once.
2. Run:
   F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\openclaw.cmd status
   F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\npm-global\openclaw.cmd gateway status
3. If you copied payloads, also verify Telegram routes, generated skills, browser profiles, and sessions.
