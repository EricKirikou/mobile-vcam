# Mobile Virtual Camera — iOS Build & Distribution Guide

This document covers how to build, install, and publish the iOS app package (`MobileVirtualCamera.ipa`).

---

## ⚡ Option 1: 1-Click Automated Cloud Build (No Mac Required)

Because iOS builds require macOS and Xcode, we have configured a **GitHub Actions CI/CD workflow** that builds the `.ipa` on Apple's cloud runners for free.

### Steps:
1. Initialize a git repository and push to GitHub:
   ```powershell
   git init
   git add .
   git commit -m "Initial commit for Mobile Virtual Camera"
   git branch -M main
   git remote add origin https://github.com/<YOUR_USERNAME>/MobileVirtualCamera.git
   git push -u origin main
   ```
2. In your GitHub repository:
   - Click on the **Actions** tab.
   - Select **"Build iOS Package (IPA)"** on the left.
   - Click **Run workflow** → Select `unsigned` (or `app-store` if you have certificates).
3. Once completed (~3-5 minutes), download `MobileVirtualCamera-iOS-IPA.zip` from the workflow summary artifacts.
4. Extract the `.ipa` file inside.

---

## 📲 Option 2: Sideload onto iPhone/iPad (Free Apple ID, No \$99 Dev Account)

You can install the `.ipa` directly onto any iPhone or iPad running iOS 16+ using either **Sideloadly** or **AltStore**.

### Method A: Sideloadly (Windows & macOS)
1. Download and install [Sideloadly](https://sideloadly.io/) on your PC.
2. Connect your iPhone to your PC via USB cable and unlock your device (tap **Trust this Computer**).
3. Open Sideloadly:
   - Drag & drop `MobileVirtualCamera.ipa` into Sideloadly.
   - Enter your Apple ID email.
   - Click **Start**.
4. Once completed, on your iPhone:
   - Go to **Settings** → **General** → **VPN & Device Management**.
   - Tap your Apple ID and tap **Trust "Mobile Virtual Camera"**.
   - Enable **Developer Mode** in **Settings** → **Privacy & Security** → **Developer Mode** (reboot when prompted).
5. Open **Mobile Virtual Camera** from your home screen.

### Method B: AltStore
1. Install [AltServer](https://altstore.io/) on your computer.
2. Install AltStore onto your iOS device.
3. AirDrop or download `MobileVirtualCamera.ipa` to your Files app.
4. In AltStore, go to **My Apps** → tap the **+** button in the top left → choose `MobileVirtualCamera.ipa`.

---

## 🍏 Option 3: Local Build on a Mac (Xcode)

If you have a Mac:
1. Transfer the project directory to your Mac.
2. Open terminal in the project directory:
   ```bash
   chmod +x installers/ios/build-ipa.sh
   ./installers/ios/build-ipa.sh
   ```
3. The script automatically detects whether you have a developer certificate installed:
   - **With Developer Account**: Builds and signs a release IPA archive.
   - **Without Developer Account**: Compiles and packages an unsigned IPA ready for Sideloadly/AltStore.
4. Output file: `packages/ios/MobileVirtualCamera.ipa`.

---

## 🚀 Option 4: Publish to TestFlight & App Store

To distribute via Apple's official App Store or TestFlight:

1. **Prerequisites**: Paid Apple Developer Program membership (\$99/year).
2. **Configure App ID**:
   - Go to [Apple Developer Portal](https://developer.apple.com/account/).
   - Create an App ID matching `com.mobilevirtualcamera.app`.
   - Enable Camera and Local Network capabilities.
3. **Configure GitHub Actions Secrets** (optional for automated CI/CD):
   - `APPLE_CERTIFICATE_BASE64`: Base64 string of your `.p12` distribution certificate.
   - `APPLE_CERTIFICATE_PASSWORD`: Password for your `.p12` file.
   - `APPLE_PROVISIONING_PROFILE_BASE64`: Base64 string of your `.mobileprovision` file.
4. **Export Options**:
   Change `installers/ios/ExportOptions.plist` method to `app-store`:
   ```xml
   <key>method</key>
   <string>app-store</string>
   ```
5. **Upload via Transporter or Xcode**:
   - On Mac: Open **Transporter** app, drag `MobileVirtualCamera.ipa` and click **Deliver**.
   - Or directly in Xcode: **Product** → **Archive** → **Distribute App** → **App Store Connect**.
6. The build will appear in [App Store Connect](https://appstoreconnect.apple.com/) under TestFlight within ~10 minutes.

