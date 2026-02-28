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
cp "./ComposeLauncher/Sources/Core/Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"

# Copy Info.plist from source
cp "./ComposeLauncher/Sources/Core/Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

# Create PkgInfo
echo -n "APPL????" > "${APP_BUNDLE}/Contents/PkgInfo"

echo "✅ Build complete: ${APP_BUNDLE}"

echo "🔄 Restarting app..."
# Close the app if it's running. Use the process name "ComposeLauncher"
# We use || true because pkill returns 1 if no process is found, which would trigger set -e
pkill -x "ComposeLauncher" || true

# Wait a moment for the process to terminate
sleep 1

# Open the new build
open "${APP_BUNDLE}"

echo "🚀 ${APP_NAME} is running!"

