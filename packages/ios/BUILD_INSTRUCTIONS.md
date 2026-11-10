# Mobile Virtual Camera — iOS Build Instructions

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| macOS | 14.0 Sonoma+ | Required — cannot build on Windows/Linux |
| Xcode | 15.0+ | From Mac App Store |
| Apple Developer Account | Any tier | Free for device testing, paid for distribution |
| CocoaPods or SPM | Latest | Dependencies via Swift Package Manager |

> **⚠️ Windows Users**: iOS builds require macOS with Xcode. Consider using a Mac,
> a CI service (GitHub Actions, Bitrise, Codemagic), or a cloud Mac (MacStadium).

## Automated Build (Recommended)

```bash
cd MobileVirtualCamera
chmod +x installers/ios/build-ipa.sh
./installers/ios/build-ipa.sh
```

The script will:
1. Resolve Swift Package Manager dependencies
2. Build the archive
3. Export the IPA using `installers/ios/ExportOptions.plist`

## Manual Build Steps

### 1. Open Project in Xcode
```bash
cd ios/MobileVirtualCamera
open MobileVirtualCamera.xcodeproj
```

### 2. Configure Signing
- Select the `MobileVirtualCamera` target → **Signing & Capabilities**
- Set your **Team** (Apple Developer account)
- Set **Bundle Identifier**: `com.mobilevirtualcamera.app`
- Let Xcode manage signing automatically, or add your provisioning profile manually

### 3. Resolve Dependencies (Swift Package Manager)
```
Xcode → File → Packages → Resolve Package Versions
```

Required packages (defined in `Package.swift`):
- `WebRTC` (GoogleWebRTC or airbnb/webrtc-build)
- `Starscream` (WebSocket signaling)

### 4. Build for Device (Debug)
- Select your physical device in the target bar
- Press **⌘R** or Product → Run

### 5. Build Release Archive
```bash
xcodebuild archive \
  -project ios/MobileVirtualCamera/MobileVirtualCamera.xcodeproj \
  -scheme MobileVirtualCamera \
  -archivePath build/MobileVirtualCamera.xcarchive \
  -configuration Release \
  CODE_SIGN_IDENTITY="iPhone Distribution" \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID"
```

### 6. Export IPA
```bash
xcodebuild -exportArchive \
  -archivePath build/MobileVirtualCamera.xcarchive \
  -exportOptionsPlist installers/ios/ExportOptions.plist \
  -exportPath packages/ios/
```

## Default Camera Settings (4K)

The iOS app defaults to **4K (3840×2160) @ 60fps, 25 Mbps**:
- `Core/Camera/CameraControls.swift`: `.res4K`, `.fps60`
- `Core/Storage/UserPreferences.swift`: `"4K"`, `60fps`, `25000 kbps`
- `Core/WebRTC/RTCConfig.swift`: `targetBitrateKbps = 25000`, `maxFps = 60`

## CI/CD (GitHub Actions Example)

```yaml
name: iOS Build
on: [push]
jobs:
  build:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Build IPA
        run: ./installers/ios/build-ipa.sh
      - uses: actions/upload-artifact@v4
        with:
          name: MobileVirtualCamera.ipa
          path: packages/ios/*.ipa
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `No signing certificate` | Add Apple ID in Xcode → Preferences → Accounts |
| `Package resolution failed` | Delete `.build/` and re-resolve packages |
| `Camera permission denied on simulator` | Use a real device — simulators can't use cameras |
| `AVCaptureSession 4K not supported` | Requires iPhone XS / 11 or newer for 4K 60fps |
| `WebRTC framework not found` | Run `File → Packages → Resolve Package Versions` |

