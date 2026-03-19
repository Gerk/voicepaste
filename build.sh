#!/bin/bash
# Build VoicePaste and create a .app bundle
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="VoicePaste"
BUILD_DIR=".build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"

echo "Building $APP_NAME..."
swift build -c release 2>&1

echo "Creating app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$CONTENTS/MacOS"
mkdir -p "$CONTENTS/Resources"

# Copy binary
cp "$BUILD_DIR/release/$APP_NAME" "$CONTENTS/MacOS/$APP_NAME"

# Copy Info.plist
cp "Resources/Info.plist" "$CONTENTS/Info.plist"

# Sign with entitlements (ad-hoc, no Apple ID needed)
echo "Signing with entitlements..."
codesign --force --sign - \
    --entitlements "$APP_NAME.entitlements" \
    "$APP_BUNDLE"

echo ""
echo "✓ Built: $APP_BUNDLE"
echo ""
echo "To run:"
echo "  open $APP_BUNDLE"
echo ""
echo "First launch: macOS will prompt for Microphone, Speech Recognition,"
echo "and Accessibility permissions. Grant all three."
