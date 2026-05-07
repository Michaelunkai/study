# clawkey - Show OpenClaw token/key status
. 'F:\study\AI_ML\AI_and_Machine_Learning\Artificial_Intelligence\openclaw\scripts\Resolve-OpenClawPaths.ps1'
$paths = Get-OpenClawPaths
$tokenFile = $paths.TokenPath
if (Test-Path $tokenFile) {
    $t = Get-Content $tokenFile -Raw | ConvertFrom-Json
    $tok = if ($t.token) { $t.token } elseif ($t.CLAUDE_CODE_OAUTH_TOKEN) { $t.CLAUDE_CODE_OAUTH_TOKEN } else { 'N/A' }
    Write-Host "Token: $($tok.Substring(0,[Math]::Min(30,$tok.Length)))..." -ForegroundColor Cyan
} else {
    Get-ChildItem Env: | Where-Object { $_.Name -match 'TELEGRAM|CLAUDE_CODE_OAUTH|ANTHROPIC' } |
        ForEach-Object { Write-Host "$($_.Name): $($_.Value.Substring(0,[Math]::Min(30,$_.Value.Length)))..." -ForegroundColor Cyan }
}
