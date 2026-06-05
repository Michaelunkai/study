@echo off
start "" /B powershell.exe -NoProfile -ExecutionPolicy Bypass -File "F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\scripts\Force-QbitFitGirlAutoInstall.ps1" -Daemon -PollMilliseconds 250
exit /b 0
