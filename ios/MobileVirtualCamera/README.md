# Mobile Virtual Camera for iOS

A native, high-performance iOS application that turns your iPhone or iPad into an ultra high-definition wireless virtual webcam with low latency WebRTC streaming, remote camera control RPCs, hardware video encoding, and QR code pairing.

---

## 🌟 Key Features

- **High-Definition Capture**:
  - Full support for **4K UHD (3840x2160)**, **1080p FHD (1920x1080)**, and **720p HD**.
  - **60 FPS** and **30 FPS** high-framerate video pipelines.
  - Multi-lens switching: **Ultra-Wide (0.5x)**, **Wide-Angle (1x)**, **Telephoto (3x)**, and **TrueDepth Front Camera**.
  - Pinch-to-zoom and optical/digital zoom interpolation.
  - Tap-to-focus and exposure point-of-interest targeting.
  - Flash / Torch toggle.
  - High-resolution snapshot capture while streaming.
  - Gyroscope-based cinematic video stabilization.

- **Low Latency WebRTC & Real-Time Signaling**:
  - Direct P2P WebRTC streaming with STUN/TURN fallback.
  - Hardware H.264 & HEVC/H.265 video compression via Apple VideoToolbox.
  - Sub-30ms local Wi-Fi latency.
  - Socket.IO signaling connection to the relay server with auto-reconnection and heartbeat keep-alives.

- **Remote Camera RPC (Desktop Controls Phone)**:
  - Supports remote commands dispatched from Desktop:
    - Switch camera lens (Front / Back / Ultra-wide / Telephoto)
    - Toggle flashlight / torch
    - Digital zoom adjustments
    - Resolution and FPS adjustments
    - Audio mute / unmute
    - Trigger high-res photo capture
    - Request real-time FPS, bitrate, and latency metrics

- **Fast & Secure Device Pairing**:
  - Instant pairing via **QR code scanning** using `AVCaptureMetadataOutput` with haptic feedback.
  - Manual 6-digit alphanumeric pairing PIN fallback.
  - Encrypted auth token storage in **Apple Keychain**.

- **Live Telemetry & Diagnostics**:
  - Real-time HUD showing FPS, bitrate (Mbps/Kbps), latency (ms), thermal state, and battery status.
  - Automatic battery warning alert when battery drops below 15%.
  - Thermal throttling management.

- **Modern SwiftUI UI / UX**:
  - Modern cyberpunk dark theme (`#0F0F23`, `#16162A`, `#6C63FF`, `#00FF88`).
  - Fluid gestures: pinch-to-zoom, tap-to-focus with animated reticle.
  - Quick Controls floating dock and lens switcher pill bar.

---

## 🏗️ Architecture & Project Structure

```
ios/MobileVirtualCamera/
├── MobileVirtualCamera.xcodeproj/     # Xcode Project
│   └── project.pbxproj
├── Package.swift                       # Swift Package Manager Manifest
├── README.md                           # Documentation
└── MobileVirtualCamera/
    ├── App/
    │   ├── MobileVirtualCameraApp.swift # @main SwiftUI entry point
    │   └── AppDelegate.swift           # AudioSession & Background configuration
    ├── Core/
    │   ├── Camera/
    │   │   ├── CameraManager.swift     # AVCaptureSession, multi-lens, zoom, focus, frames
    │   │   ├── CameraControls.swift    # Observable camera controls state
    │   │   ├── CameraConfiguration.swift# Resolutions, FPS presets, lenses
    │   │   └── CameraPreviewView.swift # UIViewRepresentable with focus ring gestures
    │   ├── WebRTC/
    │   │   ├── WebRTCClient.swift      # WebRTC stream coordinator & metrics loop
    │   │   ├── SignalingClient.swift   # Socket.IO & WebSocket signaling protocol client
    │   │   └── RTCConfig.swift         # STUN/TURN & codec settings
    │   ├── Network/
    │   │   ├── APIClient.swift         # Async/await URLSession HTTP REST client
    │   │   ├── APIEndpoints.swift      # REST endpoints definitions
    │   │   ├── AuthService.swift       # Sign In, Sign Up, JWT session restore
    │   │   ├── PairingService.swift    # Device pairing, claim pair code, unpair
    │   │   └── NetworkMonitor.swift    # NWPathMonitor Wi-Fi/Cellular connectivity
    │   ├── Storage/
    │   │   ├── KeychainHelper.swift    # Secure Apple Keychain wrapper
    │   │   └── UserPreferences.swift   # Persistent settings (UserDefaults)
    │   ├── Models/
    │   │   ├── DeviceModels.swift      # Device telemetry, capabilities, platform
    │   │   ├── UserModels.swift        # User, Auth tokens, session response
    │   │   ├── PairingModels.swift     # Pairing request/response, QR payload
    │   │   ├── SignalingModels.swift   # WebRTC SDP, ICE candidates, metrics
    │   │   └── CameraRPCModels.swift   # Remote RPC commands and responses
    │   └── Telemetry/
    │       └── TelemetryCollector.swift# Battery, thermal state, disk space, network
    ├── UI/
    │   ├── Theme/
    │   │   └── AppTheme.swift          # Colors, hex parser, styling tokens
    │   ├── Navigation/
    │   │   └── AppNavigation.swift     # Auth vs Main Screen navigation coordinator
    │   ├── Views/
    │   │   ├── Auth/
    │   │   │   └── LoginView.swift     # Authentication & Server configuration
    │   │   ├── Pairing/
    │   │   │   ├── PairingView.swift   # QR scan / Manual PIN pairing sheet
    │   │   │   ├── QRScannerView.swift # Live AVCaptureMetadataOutput QR scanner
    │   │   │   └── ManualPairingView.swift # 6-digit PIN code entry
    │   │   ├── Camera/
    │   │   │   ├── CameraStreamView.swift # Full-screen live viewfinder & HUD
    │   │   │   ├── MetricsOverlayView.swift # Live FPS, Bitrate, Latency badges
    │   │   │   └── QuickControlsOverlay.swift # Lens bar, torch, mute, snapshot dock
    │   │   ├── Settings/
    │   │   │   └── SettingsView.swift  # Resolution, FPS, bitrate, HEVC, server settings
    │   │   └── Common/
    │   │       └── GlassCard.swift     # Translucent cards, GlowingButton, StatusBadge
    │   └── ViewModels/
    │       ├── AuthViewModel.swift
    │       ├── PairingViewModel.swift
    │       └── CameraViewModel.swift
    └── Resources/
        ├── Info.plist                  # Camera, Mic, Local Network privacy keys
        └── Assets.xcassets/            # AppIcon & AccentColor asset catalogs
```

---

## 🚀 Building & Running

### Prerequisites
- macOS 14.0+ (Sonoma or Sequoia)
- Xcode 15.0+ or Xcode 16.0+
- iOS Device or Simulator running iOS 16.0 or later (Physical device recommended for camera hardware testing).

### Opening in Xcode
1. Open `ios/MobileVirtualCamera/MobileVirtualCamera.xcodeproj` in Xcode:
   ```bash
   open ios/MobileVirtualCamera/MobileVirtualCamera.xcodeproj
   ```
2. Select your development team under **Signing & Capabilities**.
3. Select your connected iPhone or iPad target.
4. Press **Cmd + R** to build and run.

### Connecting to the Desktop Server
1. Ensure your iPhone and Desktop computer are connected to the same local Wi-Fi network.
2. In the iOS app, tap the **Server Settings** disclosure on the login screen or in **Settings** (gear icon) and enter your desktop's IP address (e.g. `http://192.168.1.150:5000`).
3. Sign in or register an account.
4. Tap the **QR Code Scanner** icon in the top right to scan the pairing QR code displayed in the Desktop application.
5. Once paired, your iPhone camera stream will instantly show up as a virtual webcam on your desktop!

