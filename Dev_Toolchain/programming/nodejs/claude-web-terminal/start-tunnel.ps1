# Start cloudflared tunnel for Claude Web Terminal
$cloudflared = "cloudflared"
# Try common paths
if (!(Get-Command cloudflared -ErrorAction SilentlyContinue)) {
    $paths = @("C:\Program Files (x86)\cloudflared\cloudflared.exe", "C:\Windows\cloudflared.exe")
    foreach ($p in $paths) {
        if (Test-Path $p) { $cloudflared = $p; break }
    }
}
Write-Host "Starting cloudflared tunnel to localhost:3099..."
& $cloudflared tunnel --url http://localhost:3099
