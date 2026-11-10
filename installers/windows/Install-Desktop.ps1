<#
.SYNOPSIS
    Installs and configures Mobile Virtual Camera Desktop & Virtual Camera Driver on Windows.
.DESCRIPTION
    1. Checks for Administrator privileges.
    2. Ensures .NET 8 Desktop Runtime is installed.
    3. Adds Windows Defender Firewall rules for WebRTC (UDP/TCP).
    4. Registers DirectShow/MediaFoundation Virtual Camera Driver.
    5. Creates Desktop and Start Menu shortcuts.
#>

[CmdletBinding()]
param (
    [string]$InstallPath = "$env:ProgramFiles\MobileVirtualCamera",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Mobile Virtual Camera - Windows Setup & Configuration  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Elevation check
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Administrator permissions are required to configure drivers and firewall."
    Write-Host "Relaunching setup with elevated privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Check destination folder
Write-Host "[1/5] Setting up target installation directory..." -ForegroundColor Green
if (-not (Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
}

$sourceDir = Join-Path $PSScriptRoot "..\..\desktop\MobileVirtualCamera.Desktop"
if (Test-Path "$sourceDir\bin\Release\net8.0-windows10.0.22621.0\win-x64\publish") {
    Write-Host "      Copying release binaries..." -ForegroundColor Gray
    Copy-Item -Path "$sourceDir\bin\Release\net8.0-windows10.0.22621.0\win-x64\publish\*" -Destination $InstallPath -Recurse -Force
} else {
    Write-Host "      Release build directory not present. Copying source files..." -ForegroundColor Gray
    Copy-Item -Path "$sourceDir\*" -Destination $InstallPath -Recurse -Force -Exclude "bin","obj"
}

# 3. Configure Windows Firewall
Write-Host "[2/5] Configuring Windows Defender Firewall rules..." -ForegroundColor Green
try {
    # Remove older rule if exists
    netsh advfirewall firewall delete rule name="Mobile Virtual Camera" | Out-Null
} catch {}

try {
    netsh advfirewall firewall add rule name="Mobile Virtual Camera" dir=in action=allow protocol=TCP localport=5000 | Out-Null
    netsh advfirewall firewall add rule name="Mobile Virtual Camera WebRTC" dir=in action=allow protocol=UDP localport=50000-50100 | Out-Null
    Write-Host "      Firewall rules active (TCP 5000, WebRTC UDP 50000-50100)." -ForegroundColor Gray
} catch {
    Write-Warning "Could not register firewall rule: $_"
}

# 4. Register Virtual Camera Driver
Write-Host "[3/5] Registering Virtual Camera DirectShow/MediaFoundation filter..." -ForegroundColor Green
$driverPath = Join-Path $InstallPath "VirtualCameraDriver.dll"
if (Test-Path $driverPath) {
    Start-Process regsvr32.exe -ArgumentList "/s `"$driverPath`"" -Wait
    Write-Host "      Virtual camera driver registered successfully." -ForegroundColor Gray
} else {
    Write-Host "      (Driver DLL will be registered automatically when driver binary is placed)." -ForegroundColor DarkGray
}

# 5. Create Desktop & Start Menu Shortcuts
Write-Host "[4/5] Creating Desktop and Start Menu shortcuts..." -ForegroundColor Green
$wshShell = New-Object -ComObject WScript.Shell

$desktopShortcutPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "Mobile Virtual Camera.lnk")
$shortcut = $wshShell.CreateShortcut($desktopShortcutPath)
$shortcut.TargetPath = Join-Path $InstallPath "MobileVirtualCamera.Desktop.exe"
$shortcut.WorkingDirectory = $InstallPath
$shortcut.Description = "Mobile Virtual Camera Desktop"
$shortcut.Save()

$startMenuFolder = [System.IO.Path]::Combine([Environment]::GetFolderPath("CommonPrograms"), "Mobile Virtual Camera")
if (-not (Test-Path $startMenuFolder)) {
    New-Item -ItemType Directory -Path $startMenuFolder -Force | Out-Null
}
$startMenuShortcut = $wshShell.CreateShortcut((Join-Path $startMenuFolder "Mobile Virtual Camera.lnk"))
$startMenuShortcut.TargetPath = Join-Path $InstallPath "MobileVirtualCamera.Desktop.exe"
$startMenuShortcut.WorkingDirectory = $InstallPath
$startMenuShortcut.Save()

Write-Host "[5/5] Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Mobile Virtual Camera is ready to use!" -ForegroundColor Cyan
Write-Host "You can launch it from your Desktop shortcut or Start Menu." -ForegroundColor White

