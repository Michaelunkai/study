# rmcc - Kill all Claude Code processes
$procs = Get-Process -Name "claude*" -ErrorAction SilentlyContinue
if ($procs) {
    $procs | Stop-Process -Force
    Write-Host "Killed $($procs.Count) Claude processes" -ForegroundColor Yellow
} else {
    Write-Host "No Claude processes running" -ForegroundColor Gray
}