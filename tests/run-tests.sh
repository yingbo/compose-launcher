#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/../ComposeLauncher"

echo "=== Running all tests (including integration with real Docker) ==="
echo ""

# Ensure Xcode developer tools are available (needed for XCTest)
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo "WARNING: Docker not found. Integration tests will be skipped."
fi

cd "$PROJECT_DIR"

swift test 2>&1

echo ""
echo "=== All tests passed ==="
