# claw - Launch OpenClaw
$vbs = 'C:\Users\micha\.openclaw\ClawdBot\ClawdbotTray.vbs'
if (Test-Path $vbs) {
    Start-Process wscript.exe -ArgumentList "`"$vbs`"" -WindowStyle Hidden
    Write-Host "OpenClaw launched" -ForegroundColor Green
} else {
    Write-Host "OpenClaw not found at $vbs" -ForegroundColor Red
}