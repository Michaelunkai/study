// Test child_process fallback for Claude Web Terminal
const { spawn } = require('child_process');
const shell = spawn('powershell.exe', ['-NoLogo', '-Command', 'Write-Host "Fallback works"; exit'], {
  stdio: ['pipe', 'pipe', 'pipe'],
});
shell.stdout.on('data', (d) => { process.stdout.write(d); });
shell.stderr.on('data', (d) => { process.stderr.write(d); });
shell.on('close', (code) => { console.log('Exit code:', code); });
