@echo off
setlocal
set "ROOT=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%setup\Install-RemoteCommandCenter.ps1" %*
exit /b %ERRORLEVEL%

