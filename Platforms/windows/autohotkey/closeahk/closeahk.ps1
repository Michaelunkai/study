<#
.SYNOPSIS
    closeahk - PowerShell utility script
.NOTES
    Original function: closeahk
    Extracted: 2026-02-19 20:20
#>
Get-Process | ForEach-Object {
        try {
            if ($_.Name -like "*autohotkey*" -or ($_.Path -and $_.Path -like "*.ahk")) {
                Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
    # Extra safety net for known names
    Stop-Process -Name "AutoHotkey" -Force -ErrorAction SilentlyContinue
