@echo off
setlocal
title Olist Report - English
cd /d "%~dp0"
if not exist "%~dp0Run_Report.ps1" (
    echo Required files are missing. Extract the entire ZIP before running Start.cmd.
    pause
    exit /b 1
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Run_Report.ps1"
echo.
echo Finished. If an error appears above, copy it or open last_error.txt in this folder.
pause
