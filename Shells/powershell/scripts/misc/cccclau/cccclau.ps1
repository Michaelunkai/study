# cccclau - Chain Claude Code launcher with full config
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args2)
$prompt = $Args2 -join ' '
Write-Host "Claude Code (chained)" -ForegroundColor Cyan
if ($prompt) { claude $prompt } else { claude }