@echo off
setlocal
title Mobile Virtual Camera - Android APK Builder

echo ==============================================================
echo    Mobile Virtual Camera - Android APK Builder
echo ==============================================================
echo.

cd /d "%~dp0..\..\android"

echo [*] Building Android Debug and Release APKs...
if exist "gradlew.bat" (
    call gradlew.bat assembleRelease assembleDebug
) else (
    echo [!] Initializing Gradle Wrapper...
    call gradle wrapper
    call gradlew.bat assembleRelease assembleDebug
)

echo.
echo [*] APK build artifacts generated at:
echo     android\app\build\outputs\apk\release\app-release-unsigned.apk
echo     android\app\build\outputs\apk\debug\app-debug.apk
echo.
pause

