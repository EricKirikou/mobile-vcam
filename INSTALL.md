# Mobile Virtual Camera — Installation & Packaging Guide

This repository contains the full source code and build automation for **Mobile Virtual Camera** across **iOS**, **Android**, **Windows Desktop**, and the **Relay / Signaling Backend**.

---

## 📦 Installable Apps & Software Overview

| Platform | Format | Build / Setup Tool | Target Location |
| :--- | :--- | :--- | :--- |
| **Windows Desktop** | `.exe` / Inno Setup Installer | [`install.bat`](file:///C:/Users/uitsi/Downloads/MobileVirtualCamera/installers/windows/install.bat) / [`setup.iss`](file:///C:/Users/uitsi/Downloads/MobileVirtualCamera/installers/windows/setup.iss) | `Program Files\MobileVirtualCamera` |
| **iOS** | `.ipa` / Xcode Project | [`build-ipa.sh`](file:///C:/Users/uitsi/Downloads/MobileVirtualCamera/installers/ios/build-ipa.sh) / Xcode | `ios/MobileVirtualCamera/build/IPA` |
| **Android** | `.apk` (Release & Debug) | [`build-apk.bat`](file:///C:/Users/uitsi/Downloads/MobileVirtualCamera/installers/android/build-apk.bat) | `android/app/build/outputs/apk/` |
| **Relay Backend** | Node.js / Docker Service | [`start-server.bat`](file:///C:/Users/uitsi/Downloads/MobileVirtualCamera/installers/backend/start-server.bat) / Docker Compose | `http://localhost:5000` |

---

## 🚀 1. Windows Desktop Installation

### Option A: One-Click PowerShell / Batch Installer
1. Navigate to `installers/windows/`
2. Right-click [`install.bat`](file:///C:/Users/uitsi/Downloads/MobileVirtualCamera/installers/windows/install.bat) and select **Run as Administrator** (or run `Install-Desktop.ps1`).
3. The installer automatically:
   - Copies the desktop application files to `C:\Program Files\MobileVirtualCamera`.
   - Adds Windows Defender Firewall rules for TCP 5000 and WebRTC UDP ports (50000-50100).
   - Registers the Virtual Camera DirectShow driver filter.
   - Places a **Mobile Virtual Camera** shortcut on your Desktop and Start Menu.

### Option B: Compiling the Standalone Setup Wizard (`.exe`)
1. Open [`installers/windows/setup.iss`](file:///C:/Users/uitsi/Downloads/MobileVirtualCamera/installers/windows/setup.iss) in [Inno Setup Compiler](https://jrsoftware.org/isinfo.php).
2. Click **Build > Compile**.
3. The standalone setup executable is generated at:
   ```
   dist/MobileVirtualCamera-Setup-v1.0.0.exe
   ```

---

## 📱 2. iOS App Installation & IPA Generation

### Option A: Open directly in Xcode
1. Double click `ios/MobileVirtualCamera/MobileVirtualCamera.xcodeproj` on your Mac.
2. Select your connected iPhone or iPad as the run destination.
3. Select your development team under **Signing & Capabilities**.
4. Press `Cmd + R` to build and install directly onto your iOS device.

### Option B: Command Line IPA Build
1. Run the packaging script on your Mac:
   ```bash
   chmod +x installers/ios/build-ipa.sh
   ./installers/ios/build-ipa.sh
   ```
2. The installable `MobileVirtualCamera.ipa` will be output to:
   ```
   ios/MobileVirtualCamera/build/IPA/MobileVirtualCamera.ipa
   ```
3. Install via Apple Configurator, Xcode Devices & Simulators, or TestFlight.

---

## 🤖 3. Android APK Build

1. Run the APK build script:
   ```cmd
   installers\android\build-apk.bat
   ```
2. The generated installable APK files will be located at:
   ```
   android\app\build\outputs\apk\release\app-release-unsigned.apk
   android\app\build\outputs\apk\debug\app-debug.apk
   ```

---

## 🌐 4. Running the Signaling / Relay Backend

### Option A: Native Windows / Node.js
Double click [`installers/backend/start-server.bat`](file:///C:/Users/uitsi/Downloads/MobileVirtualCamera/installers/backend/start-server.bat). This will automatically install dependencies and start the server on `http://localhost:5000`.

### Option B: Docker Compose
```bash
cd installers/backend
docker compose up -d
```

