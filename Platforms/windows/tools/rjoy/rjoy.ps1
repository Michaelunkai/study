<#
.SYNOPSIS
    rjoy - PowerShell utility script
.NOTES
    Original function: rjoy
    Extracted: 2026-02-19 20:20
#>
# Terminate any running instance of JoyToKey
    taskkill /F /IM JoyToKey.exe;
    # Change to the directory where JoyToKey is installed
    cd "F:\backup\windowsapps\installed\JoyToKey";
    # Start JoyToKey as administrator
    & Start-Process "JoyToKey.exe" -Verb RunAs
