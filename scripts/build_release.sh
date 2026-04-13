#!/bin/bash

#  build_release.sh
#  Noon
#
#  Copyright © 2026 Sunazur. All rights reserved.
#  Licensed under CC BY-NC-SA 4.0.

set -e

PROJECT_NAME="Noon"
SCHEME_NAME="Noon"
CONFIGURATION="Release"
BUILD_DIR="./build"
ARCHIVE_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Export"
DMG_NAME="${PROJECT_NAME}.dmg"
APP_NAME="${PROJECT_NAME}.app"

echo "🚀 Starting build process for ${PROJECT_NAME}..."

# 1. Clean build directory
echo "🧹 Cleaning build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# 2. Archive the app
echo "📦 Archiving app..."
xcodebuild archive \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "${SCHEME_NAME}" \
    -configuration "${CONFIGURATION}" \
    -archivePath "${ARCHIVE_PATH}" \
    -destination "generic/platform=macOS" \
    QUIET=YES

# 3. Export the app
echo "📂 Exporting app..."
xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -exportOptionsPlist "scripts/exportOptions.plist" \
    -exportPath "${EXPORT_PATH}" \
    QUIET=YES

# 4. Create DMG
echo "💿 Creating DMG..."
hdiutil create -format UDZO -srcfolder "${EXPORT_PATH}/${APP_NAME}" -volname "${PROJECT_NAME}" "${BUILD_DIR}/${DMG_NAME}"

echo "✅ Build successful! DMG is located at: ${BUILD_DIR}/${DMG_NAME}"
