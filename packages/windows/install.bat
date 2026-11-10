@echo off
setlocal
title Mobile Virtual Camera - Windows Installer

echo ==============================================================
echo    Mobile Virtual Camera - Installation & Driver Setup
echo ==============================================================
echo.

:: Check for Administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Administrator privileges required. Requesting elevation...
    powershell -Command "Start-Process '%~dpnx0' -Verb RunAs"
    exit /b
)

echo [*] Launching PowerShell installation script...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Desktop.ps1"

echo.
echo Press any key to exit...
pause >nul

