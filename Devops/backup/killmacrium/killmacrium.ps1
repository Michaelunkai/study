<#
.SYNOPSIS
    killmacrium - PowerShell utility script
.NOTES
    Original function: killmacrium
    Extracted: 2026-02-19 20:20
#>
Get-Service | Where-Object { $_.Name -like '*macrium*' } | ForEach-Object {
  try { Stop-Service -Name $_.Name -Force -ErrorAction Stop } catch {
    Get-WmiObject Win32_Service -Filter "Name='$($_.Name)'" | ForEach-Object {
      taskkill /F /PID $_.ProcessId
    }
  }
}; Get-Process | Where-Object { $_.Name -like '*macrium*' } | Stop-Process -Force
