@echo off
setlocal
title Mobile Virtual Camera - Relay & Signaling Server

echo ==============================================================
echo    Mobile Virtual Camera - Relay Server
echo ==============================================================
echo.

cd /d "%~dp0..\..\backend"

if not exist "node_modules\" (
    echo [*] Installing server dependencies...
    call npm install
)

if not exist ".env" (
    if exist ".env.example" (
        echo [*] Initializing .env configuration from template...
        copy .env.example .env >nul
    )
)

echo [*] Starting Mobile Virtual Camera Backend on http://localhost:5000 ...
call npm start
pause

