# Mobile Virtual Camera — Android Build Instructions

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| Android Studio | Ladybug (2024.2+) | Or any IDE with Android SDK |
| JDK | 17+ | JAVA_HOME must be set |
| Android SDK | API 26+ (target API 35) | Via SDK Manager |
| Gradle | 8.x | Bundled with the wrapper |

## Build Steps

### 1. Clone & Open Project
```bash
git clone <repo-url>
cd MobileVirtualCamera/android
```
Open in **Android Studio** (File → Open → select the `android/` folder).

### 2. Configure Signing (Release builds)

Create `android/keystore.properties`:
```properties
storeFile=../release.keystore
storePassword=YOUR_STORE_PASSWORD
keyAlias=mobilevirtualcamera
keyPassword=YOUR_KEY_PASSWORD
```

Generate keystore (first time only):
```bash
keytool -genkey -v -keystore release.keystore \
  -alias mobilevirtualcamera -keyalg RSA \
  -keysize 2048 -validity 10000
```

### 3. Build Debug APK
```bash
./gradlew assembleDebug
# Output: android/app/build/outputs/apk/debug/app-debug.apk
```

### 4. Build Release APK
```bash
./gradlew assembleRelease
# Output: android/app/build/outputs/apk/release/app-release.apk
```

### 5. Build Release AAB (for Google Play)
```bash
./gradlew bundleRelease
# Output: android/app/build/outputs/bundle/release/app-release.aab
```

## Default Camera Settings (4K)

The app defaults to **4K (3840×2160) @ 60fps, 25 Mbps** as configured in
`android/app/src/main/java/.../Models.kt` and `CameraManager`.

## Install to Device
```bash
adb install app/build/outputs/apk/debug/app-debug.apk
```

## Automated Build Script

From the project root, run:
```batch
installers\android\build-apk.bat
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `SDK location not found` | Set `ANDROID_HOME` or create `local.properties` with `sdk.dir=C:\\Users\\<you>\\AppData\\Local\\Android\\Sdk` |
| `JAVA_HOME is not set` | Install JDK 17 and set `JAVA_HOME` env var |
| `Gradle sync failed` | Run `./gradlew --refresh-dependencies` |
| `minSdk version too low` | Requires Android 8.0 (API 26) or higher |

