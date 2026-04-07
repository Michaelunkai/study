# cclau - Quick Claude Code session with current dir context
param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Args2)
$prompt = $Args2 -join ' '
if ($prompt) { claude $prompt } else { claude }