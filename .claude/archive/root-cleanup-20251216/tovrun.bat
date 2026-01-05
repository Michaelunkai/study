@echo off
REM ============================================================================
REM TOVPLAY DEVELOPMENT LAUNCHER - Batch wrapper
REM ============================================================================
REM Launches the PowerShell script with proper execution policy
REM
REM USAGE:
REM   cd F:\tovplay
REM   tovrun.bat
REM
REM Or from anywhere:
REM   F:\tovplay\tovrun.bat
REM ============================================================================

setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Run PowerShell script with bypass execution policy
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%tovrun.ps1" %*

REM Keep window open on error
if errorlevel 1 (
    echo.
    echo [ERROR] Script exited with error code !errorlevel!
    pause
    exit /b !errorlevel!
)

exit /b 0
