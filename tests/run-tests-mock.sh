#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../ComposeLauncher"

echo "=== Running tests in mock mode (no Docker required) ==="
echo ""

# Ensure Xcode developer tools are available (needed for XCTest)
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

cd "$PROJECT_DIR"

MOCK_DOCKER=1 swift test --disable-swift-testing 2>&1

echo ""
echo "=== Mock tests passed ==="
