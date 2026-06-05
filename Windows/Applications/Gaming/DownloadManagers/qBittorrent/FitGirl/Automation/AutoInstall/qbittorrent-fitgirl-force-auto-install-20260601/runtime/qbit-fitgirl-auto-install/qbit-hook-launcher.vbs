Option Explicit
Dim torrentName, torrentRootPath, contentPath
torrentName = ""
torrentRootPath = ""
contentPath = ""
If WScript.Arguments.Count > 0 Then torrentName = WScript.Arguments(0)
If WScript.Arguments.Count > 1 Then torrentRootPath = WScript.Arguments(1)
If WScript.Arguments.Count > 2 Then contentPath = WScript.Arguments(2)
Dim ps, forceScript, command, shell
ps = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
forceScript = "F:\study\Windows\Applications\Gaming\DownloadManagers\qBittorrent\FitGirl\Automation\AutoInstall\qbittorrent-fitgirl-force-auto-install-20260601\scripts\Force-QbitFitGirlAutoInstall.ps1"
command = Quote(ps) & " -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File " & Quote(forceScript) & " -Once"
If Len(torrentName) > 0 Then command = command & " -TorrentName " & Quote(torrentName)
If Len(torrentRootPath) > 0 Then command = command & " -TorrentRootPath " & Quote(torrentRootPath)
If Len(contentPath) > 0 Then command = command & " -ContentPath " & Quote(contentPath)
Set shell = CreateObject("WScript.Shell")
shell.Run command, 0, False
Function Quote(value)
  Quote = Chr(34) & Replace(value, Chr(34), Chr(34) & Chr(34)) & Chr(34)
End Function
