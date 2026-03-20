# MSERT Auto-Scanner + Auto-Remover
# GUI mode with /F:Y so you see progress AND threats auto-removed

$msertLog = "C:\Windows\debug\msert.log"

# Delete old log so we only parse THIS scan's results
if (Test-Path $msertLog) {
    Remove-Item $msertLog -Force -ErrorAction SilentlyContinue
    Write-Host "Cleared old MSERT log" -ForegroundColor DarkGray
}

# Kill any leftover MSERT processes so we can overwrite the exe
Get-Process -Name "MSERT" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "Downloading Microsoft Safety Scanner..." -ForegroundColor Cyan
$msertPath = "$env:TEMP\MSERT.exe"
Remove-Item $msertPath -Force -ErrorAction SilentlyContinue
Invoke-WebRequest 'https://go.microsoft.com/fwlink/?LinkId=212732' -OutFile $msertPath
Write-Host "Downloaded to $msertPath" -ForegroundColor Green

# Launch MSERT (GUI mode - clicker handles wizard, /N skips EULA-only check)
Write-Host "Launching MSERT..." -ForegroundColor Cyan
$process = Start-Process -FilePath $msertPath -PassThru

# Wait for window
Write-Host "Waiting for MSERT window..." -ForegroundColor Yellow
$timeout = 30; $elapsed = 0; $msertFound = $false
while (-not $msertFound -and $elapsed -lt $timeout) {
    Start-Sleep -Seconds 2; $elapsed += 2
    $procs = Get-Process -Name "MSERT" -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($p in $procs) {
            if ($p.MainWindowTitle -ne "") { $msertFound = $true; break }
        }
    }
}

if (-not $msertFound) {
    Write-Host "ERROR: MSERT window did not appear" -ForegroundColor Red
    exit 1
}

Write-Host "MSERT launched with auto-remove, running auto-clicker..." -ForegroundColor Green
& "C:\Users\micha\AppData\Local\Programs\Python\Python311\python.exe" "$PSScriptRoot\msert-clicker.py"

# Wait for MSERT to finish
$process.WaitForExit()
$exitCode = $process.ExitCode
Write-Host "MSERT finished with exit code: $exitCode" -ForegroundColor Cyan

# Cleanup exe
Remove-Item $msertPath -Force -ErrorAction SilentlyContinue

# ===== POST-SCAN: Show results from log =====
Write-Host "`n=== MSERT SCAN RESULTS ===" -ForegroundColor Magenta

if (Test-Path $msertLog) {
    $logContent = Get-Content $msertLog -Raw -Encoding Unicode -ErrorAction SilentlyContinue

    # Show full log
    Write-Host "`n--- MSERT Log ---" -ForegroundColor Yellow
    $logContent -split "`n" | ForEach-Object {
        $line = $_.Trim()
        if ($line -ne "" -and $line -notmatch '^\-+$') {
            Write-Host "  $line" -ForegroundColor White
        }
    }

    # Check exit code meaning
    switch ($exitCode) {
        0 { Write-Host "`n[OK] No threats found - system clean!" -ForegroundColor Green }
        2 { Write-Host "`n[OK] Threats found and successfully removed by MSERT!" -ForegroundColor Green }
        6 { Write-Host "`n[!] Threats found - some require manual removal" -ForegroundColor Yellow }
        8 { Write-Host "`n[!] Error during scan" -ForegroundColor Red }
        default { Write-Host "`n[?] Unknown exit code: $exitCode" -ForegroundColor Yellow }
    }

    # If threats were found but not fully cleaned (exit 6), try force-remove
    if ($exitCode -eq 6) {
        Write-Host "`n=== FORCE-REMOVING REMAINING THREATS ===" -ForegroundColor Red

        $threatPaths = @()

        # Extract file paths from log
        $groupPatterns = @(
            '->\s*(?:file:_?)?([A-Za-z]:\\.+)',
            '[Cc]ontainer[Ff]ile:\s*([A-Za-z]:\\.+)',
            'Resource Path:\s*([A-Za-z]:\\.+)',
            'path:\s*([A-Za-z]:\\.+)'
        )
        foreach ($pattern in $groupPatterns) {
            $rxMatches = [regex]::Matches($logContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            foreach ($m in $rxMatches) {
                $path = $m.Groups[1].Value.Trim().Trim('"').Trim("'")
                if ($path -and (Test-Path $path)) {
                    $threatPaths += $path
                }
            }
        }

        # Standalone path pattern
        $rxMatches = [regex]::Matches($logContent, '[A-Za-z]:\\[^\s\r\n"'']+\.(exe|dll|bat|cmd|vbs|ps1|tmp|scr|sys|lnk|msi|inf|js|wsf|com|pif)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        foreach ($m in $rxMatches) {
            $path = $m.Value.Trim().Trim('"').Trim("'")
            if ($path -and (Test-Path $path)) {
                $threatPaths += $path
            }
        }

        $threatPaths = $threatPaths | Sort-Object -Unique

        if ($threatPaths.Count -gt 0) {
            Write-Host "[!] Found $($threatPaths.Count) threat files still on disk - force-removing..." -ForegroundColor Red
            $removed = 0
            foreach ($file in $threatPaths) {
                try {
                    & takeown /f $file /d y 2>$null | Out-Null
                    & icacls $file /grant "Administrators:F" /c /q 2>$null | Out-Null
                    Remove-Item $file -Force -ErrorAction Stop
                    Write-Host "  [OK] Deleted: $file" -ForegroundColor Green
                    $removed++
                } catch {
                    try {
                        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class MoveFileEx {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool MoveFileExW(string lpExistingFileName, string lpNewFileName, int dwFlags);
}
'@ -ErrorAction SilentlyContinue
                        [MoveFileEx]::MoveFileExW($file, $null, 4) | Out-Null
                        Write-Host "  [PENDING] Scheduled for boot-deletion: $file" -ForegroundColor Yellow
                        $removed++
                    } catch {
                        Write-Host "  [FAIL] Could not remove: $file" -ForegroundColor Red
                    }
                }
            }
            Write-Host "`n[RESULT] Removed/scheduled $removed of $($threatPaths.Count) threat files" -ForegroundColor Cyan
        } else {
            Write-Host "[OK] MSERT removed all threats - none left on disk!" -ForegroundColor Green
        }
    }
} else {
    Write-Host "[!] MSERT log not found at $msertLog" -ForegroundColor Yellow
}

Write-Host "`n[OK] MSERT scan + cleanup complete!" -ForegroundColor Green
