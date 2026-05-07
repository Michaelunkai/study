@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw"
set "STATE_ROOT=%REPO_ROOT%\openclaw-home"
set "USER_STATE_LINK=%USERPROFILE%\.openclaw"
set "NPM_GLOBAL_REPO=%REPO_ROOT%\npm-global"
set "NPM_GLOBAL_USER=%LOCALAPPDATA%\npm-global"
set "ROAMING_NPM=%APPDATA%\npm"
set "PAYLOAD_ROOT=%SCRIPT_DIR%payload"
set "NODE_EXE=C:\Program Files\nodejs\node.exe"
set "OPENCLAW_VERSION=2026.4.21"
set "OPENCLAW_PORT=18789"
set "TASK_TRAY=ClawdBotTray"
set "TASK_GATEWAY=OpenClaw Gateway"
set "SEAL_SCRIPT=%REPO_ROOT%\scripts\Seal-OpenClawAuthority.ps1"

if not exist "%PAYLOAD_ROOT%\openclaw-home\openclaw.json" (
  echo ERROR: Missing payload root "%PAYLOAD_ROOT%\openclaw-home"
  exit /b 1
)
if not exist "%PAYLOAD_ROOT%\npm-global\node_modules\openclaw\openclaw.mjs" (
  echo ERROR: Missing payload root "%PAYLOAD_ROOT%\npm-global"
  exit /b 1
)

echo [1/11] Ensuring base directories exist...
for %%D in (
  "%REPO_ROOT%"
  "%STATE_ROOT%"
  "%NPM_GLOBAL_REPO%"
  "%NPM_GLOBAL_USER%"
  "%ROAMING_NPM%"
) do if not exist "%%~D" mkdir "%%~D"

echo [2/11] Verifying Node.js runtime...
if not exist "%NODE_EXE%" (
  echo ERROR: Expected Node.js at "%NODE_EXE%" but it was not found.
  exit /b 1
)

echo [3/11] Configuring environment variables...
setx OPENCLAW_STATE_DIR "%STATE_ROOT%" >nul
setx OPENCLAW_CONFIG_PATH "%STATE_ROOT%\openclaw.json" >nul
setx OPENCLAW_TMP_DIR "%STATE_ROOT%\tmp" >nul
setx OPENCLAW_REPO_ROOT "%REPO_ROOT%" >nul
setx NPM_CONFIG_PREFIX "%NPM_GLOBAL_USER%" >nul
> "%USERPROFILE%\.npmrc" echo prefix=%NPM_GLOBAL_USER%

echo [4/11] Restoring repo npm-global payload...
robocopy "%PAYLOAD_ROOT%\npm-global" "%NPM_GLOBAL_REPO%" /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP
if errorlevel 8 exit /b 1

echo [5/11] Restoring OpenClaw state payload...
robocopy "%PAYLOAD_ROOT%\openclaw-home" "%STATE_ROOT%" /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP
if errorlevel 8 exit /b 1

echo [6/11] Restoring roaming npm payload if present...
if exist "%PAYLOAD_ROOT%\appdata-roaming-npm" (
  robocopy "%PAYLOAD_ROOT%\appdata-roaming-npm" "%ROAMING_NPM%" /MIR /R:1 /W:1 /NFL /NDL /NJH /NJS /NP
  if errorlevel 8 exit /b 1
)

echo [7/11] Sealing canonical authority, aliases, wrappers, gateway, and tasks...
powershell -NoProfile -ExecutionPolicy Bypass -File "%SEAL_SCRIPT%" -PersistUser -SkipTelegramRefresh
if errorlevel 1 exit /b 1

echo [8/11] Verification...
call "%NPM_GLOBAL_REPO%\openclaw.cmd" gateway status
if errorlevel 1 exit /b 1
call "%NPM_GLOBAL_REPO%\openclaw.cmd" status
if errorlevel 1 exit /b 1

echo [9/11] Authority verification...
powershell -NoProfile -ExecutionPolicy Bypass -File "%REPO_ROOT%\scripts\Test-OpenClawAuthority.ps1"
if errorlevel 1 exit /b 1

echo SUCCESS
endlocal
exit /b 0
