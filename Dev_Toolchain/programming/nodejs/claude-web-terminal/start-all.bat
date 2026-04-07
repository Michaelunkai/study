@echo off
title Claude Web Terminal Launcher
cd /d F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal

echo Starting Claude Web Terminal server...
start "" /min node server.js
timeout /t 3 /nobreak >nul

echo Starting cloudflared tunnel...
start "" cloudflared tunnel --url http://localhost:3099

echo.
echo Server started on port 3099
echo Tunnel connecting to localhost:3099...
echo Check cloudflared window for public URL
echo.
pause
