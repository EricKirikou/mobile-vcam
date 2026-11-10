#!/bin/bash
set -e

# ==============================================================
#   Mobile Virtual Camera - iOS Build & IPA Packaging Script
# ==============================================================

echo "=========================================================="
echo "  Building Mobile Virtual Camera iOS App (IPA Distribution)"
echo "=========================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
PROJECT_DIR="${ROOT_DIR}/ios/MobileVirtualCamera"
BUILD_DIR="${PROJECT_DIR}/build"
ARCHIVE_PATH="${BUILD_DIR}/MobileVirtualCamera.xcarchive"
EXPORT_PATH="${BUILD_DIR}/IPA"
PACKAGES_IOS_DIR="${ROOT_DIR}/packages/ios"
EXPORT_OPTIONS="${SCRIPT_DIR}/ExportOptions.plist"

mkdir -p "${BUILD_DIR}"
mkdir -p "${EXPORT_PATH}"
mkdir -p "${PACKAGES_IOS_DIR}"

echo "[1/4] Cleaning previous build artifacts..."
rm -rf "${ARCHIVE_PATH}"
rm -rf "${EXPORT_PATH}"
rm -rf "${BUILD_DIR}/Payload"
rm -f "${BUILD_DIR}/MobileVirtualCamera.ipa"

echo "[2/4] Checking code signing requirements..."
# Check if code signing certificates are available in keychain
if security find-identity -v -p codesigning | grep -q "valid identities found"; then
    echo "Found valid signing identity. Proceeding with standard signed Xcode archive..."
    
    echo "[3/4] Archiving Xcode project for generic iOS device..."
    xcodebuild clean archive \
        -project "${PROJECT_DIR}/MobileVirtualCamera.xcodeproj" \
        -scheme "MobileVirtualCamera" \
        -configuration Release \
        -destination "generic/platform=iOS" \
        -archivePath "${ARCHIVE_PATH}" \
        -allowProvisioningUpdates

    echo "[4/4] Exporting signed IPA archive..."
    xcodebuild -exportArchive \
        -archivePath "${ARCHIVE_PATH}" \
        -exportPath "${EXPORT_PATH}" \
        -exportOptionsPlist "${EXPORT_OPTIONS}" \
        -allowProvisioningUpdates

    cp "${EXPORT_PATH}/"*.ipa "${PACKAGES_IOS_DIR}/MobileVirtualCamera.ipa"
else
    echo "No Apple Developer signing identity found on this Mac."
    echo "Building unsigned IPA suitable for AltStore / Sideloadly / Test Devices..."

    echo "[3/4] Compiling release binary without signing..."
    xcodebuild clean build \
        -project "${PROJECT_DIR}/MobileVirtualCamera.xcodeproj" \
        -scheme "MobileVirtualCamera" \
        -configuration Release \
        -sdk iphoneos \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_IDENTITY="" \
        AD_HOC_CODE_SIGNING_ALLOWED=YES

    echo "[4/4] Packaging .app into .ipa container..."
    APP_BUNDLE=$(find "${BUILD_DIR}/DerivedData" -name "MobileVirtualCamera.app" -type d | head -n 1)
    
    if [ -z "${APP_BUNDLE}" ]; then
        echo "Error: MobileVirtualCamera.app bundle not found!"
        exit 1
    fi

    mkdir -p "${BUILD_DIR}/Payload"
    cp -R "${APP_BUNDLE}" "${BUILD_DIR}/Payload/"
    
    cd "${BUILD_DIR}"
    zip -r -q "${PACKAGES_IOS_DIR}/MobileVirtualCamera.ipa" Payload
    rm -rf Payload
    cd "${ROOT_DIR}"
fi

echo ""
echo "=========================================================="
echo "  SUCCESS: Installable IPA created at:"
echo "  ${PACKAGES_IOS_DIR}/MobileVirtualCamera.ipa"
echo "=========================================================="
