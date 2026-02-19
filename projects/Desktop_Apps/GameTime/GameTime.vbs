Set objShell = CreateObject("WScript.Shell")
objShell.CurrentDirectory = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
objShell.Run "cmd.exe /c npx electron .", 1, False
