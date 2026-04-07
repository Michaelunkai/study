$content = Get-Content "F:\study\Dev_Toolchain\programming\nodejs\claude-web-terminal\PROMPT.md" -Raw
Set-Clipboard -Value $content
Write-Host "Copied to clipboard"
