<#
.SYNOPSIS
    ssg - PowerShell utility script
.NOTES
    Original function: ssg
    Extracted: 2026-02-19 20:20
#>
Start-Process "F:\backup\windowsapps\installed\gameSaveManager\gs_mngr_3.exe"
Start-Sleep -Seconds 120; ws 'gg && sprofile && savegames'
