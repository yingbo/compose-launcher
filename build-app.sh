#!/bin/bash

# Build script for Compose Launcher macOS app

set -e

APP_NAME="Compose Launcher"
BUNDLE_ID="com.composelauncher.app"
BUILD_DIR="./ComposeLauncher/.build/release"
APP_BUNDLE="./${APP_NAME}.app"

echo "🔨 Building Compose Launcher..."

# Build release version
cd ComposeLauncher
swift build -c release
cd ..

echo "📦 Creating app bundle..."

# Remove old bundle if exists
rm -rf "${APP_BUNDLE}"

# Create app bundle structure
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy executable
cp "${BUILD_DIR}/ComposeLauncher" "${APP_BUNDLE}/Contents/MacOS/"

# Copy icon
cp "./ComposeLauncher/Sources/Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"

# Create Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ComposeLauncher</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026. All rights reserved.</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

echo "✅ Build complete: ${APP_BUNDLE}"
echo ""
echo "To run the app:"
echo "  open \"${APP_BUNDLE}\""
echo ""
echo "To install to Applications:"
echo "  cp -r \"${APP_BUNDLE}\" /Applications/"
