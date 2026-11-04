#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
APP_NAME="WPMCounter.app"
APP_BUNDLE="$BUILD_DIR/$APP_NAME"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "==> Building WPMCounter..."

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "==> Compiling Swift sources..."
swiftc -O \
    -framework Cocoa \
    -framework SwiftUI \
    -target arm64-apple-macos13.0 \
    "$SCRIPT_DIR"/Sources/*.swift \
    -o "$MACOS_DIR/WPMCounter"

echo "==> Packaging Info.plist and Assets..."
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
if [ -f "$SCRIPT_DIR/Assets/AppIcon.icns" ]; then
    cp "$SCRIPT_DIR/Assets/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

echo "==> Ad-hoc signing app bundle..."
codesign --force --deep -s - "$APP_BUNDLE"

echo "==> Build complete: $APP_BUNDLE"
