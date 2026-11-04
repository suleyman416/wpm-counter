#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_SRC="$SCRIPT_DIR/build/WPMCounter.app"
DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/WPMCounter.app"
PLIST_PATH="$HOME/Library/LaunchAgents/com.local.wpmcounter.plist"

echo "==> Ensuring build exists..."
"$SCRIPT_DIR/build_app.sh"

echo "==> Stopping running instances..."
killall WPMCounter 2>/dev/null || true

echo "==> Installing to $DEST_APP..."
mkdir -p "$DEST_DIR"
rm -rf "$DEST_APP"
cp -R "$APP_SRC" "$DEST_APP"

echo "==> Setting up Autostart LaunchAgent..."
cat << EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.wpmcounter</string>
    <key>ProgramArguments</key>
    <array>
        <string>$DEST_APP/Contents/MacOS/WPMCounter</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

echo "==> Launching WPMCounter..."
open "$DEST_APP"

echo ""
echo "WPMCounter successfully installed to ~/Applications!"
