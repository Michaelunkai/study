@echo off
wscript.exe //B "%~dp0qbit-hook-launcher.vbs" "%~1" "%~2" "%~3" >NUL 2>NUL
exit /b 0
