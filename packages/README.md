# 📦 Mobile Virtual Camera — Packages

This folder contains all compiled and packaged deliverables for the Mobile Virtual Camera project.

```
packages/
├── windows/              ← Windows desktop app (compiled, ready to run)
│   └── MobileVirtualCamera/
│       ├── MobileVirtualCamera.Desktop.exe
│       └── ...
├── backend/              ← Node.js backend server (compiled + npm deps)
│   ├── src/
│   ├── node_modules/
│   └── package.json
├── android/              ← Android APK build output
│   ├── BUILD_INSTRUCTIONS.md
│   └── app-release.apk   (after building on Android Studio)
└── ios/                  ← iOS IPA build output
    ├── BUILD_INSTRUCTIONS.md
    └── MobileVirtualCamera.ipa  (after building on macOS/Xcode)
```

---

## 🖥️ Windows Desktop App

**Status**: ✅ Compiled and ready

### Run directly
```
packages\windows\MobileVirtualCamera\MobileVirtualCamera.Desktop.exe
```

### Requirements
- Windows 10 (22H2+) or Windows 11
- No .NET runtime required (self-contained)
- Backend server must be running (see Backend section below)

### Virtual Camera Driver
The virtual camera requires the **VirtualCameraDriver.dll** to be present next to the `.exe`. This driver registers a virtual webcam device visible in Zoom, Teams, OBS, Discord, etc.

> See [`INSTALL.md`](../INSTALL.md) for the full driver installation guide.

---

## 🌐 Backend Server

**Status**: ✅ Packaged with dependencies

### Start the server
```batch
cd packages\backend
node src\server.js
```
or via npm:
```batch
cd packages\backend
npm start
```
or use the launcher:
```batch
installers\backend\start-server.bat
```

### Docker (recommended for production)
```bash
cd installers/backend
docker-compose up -d
```

### Environment
Copy and edit `.env` before starting:
```bash
cp .env.example .env
# Edit .env with your JWT_SECRET, TURN server config, etc.
```

**Default port**: `3000`

---

## 📱 Android App

**Status**: 🔧 Requires build on a machine with Android Studio

The Android source code is in `android/`. See build instructions:

👉 [`android/BUILD_INSTRUCTIONS.md`](android/BUILD_INSTRUCTIONS.md)

**Quick build** (from project root, requires Android SDK):
```bash
cd android
./gradlew assembleRelease
cp app/build/outputs/apk/release/app-release.apk ../packages/android/
```

**Default settings**: 4K (3840×2160) @ 60fps, 25 Mbps

---

## 🍎 iOS App

**Status**: 🔧 Automated Cloud CI/CD or macOS Build

The iOS source code is in `ios/MobileVirtualCamera/`.

👉 Build Guide: [`ios/BUILD_INSTRUCTIONS.md`](ios/BUILD_INSTRUCTIONS.md)  
👉 Distribution & Sideloading (AltStore/Sideloadly/TestFlight): [`ios/DISTRIBUTE.md`](ios/DISTRIBUTE.md)

**Options to build**:
1. **GitHub Actions (Free Cloud Build — No Mac required)**:
   Push to GitHub and run `.github/workflows/ios-build.yml` to generate and download the `.ipa` directly.
2. **Local macOS Build**:
   ```bash
   ./installers/ios/build-ipa.sh
   ```

**Default settings**: 4K (3840×2160) @ 60fps, 25 Mbps

---

## 🔄 Complete System Setup

For the full system to work:

1. **Start the backend** (optional for cloud sync, not required for local Wi-Fi pairing):
   ```batch
   cd packages\backend && node src\server.js
   ```
2. **Launch desktop app**:
   `packages\windows\MobileVirtualCamera\MobileVirtualCamera.Desktop.exe`
3. **Install mobile app** on your iPhone/Android from the respective APK/IPA
4. **Pair** your phone via QR code or direct Wi-Fi shown in the desktop app
5. **Select the virtual camera** named `Mobile Virtual Camera` in Zoom/Teams/OBS/etc.

---

## 📋 Version Info

| Component | Version | Default Resolution |
|-----------|---------|-------------------|
| Desktop (Windows) | 1.0.0 | 4K 3840×2160 @ 60fps |
| Backend (Node.js) | 1.0.0 | — |
| Android App | 1.0.0 | 4K 3840×2160 @ 60fps |
| iOS App | 1.0.0 | 4K 3840×2160 @ 60fps |

