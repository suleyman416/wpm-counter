#!/bin/bash
set -e

DEST_APP="$HOME/Applications/WPMCounter.app"
PLIST_PATH="$HOME/Library/LaunchAgents/com.local.wpmcounter.plist"

echo "==> Stopping WPMCounter..."
killall WPMCounter 2>/dev/null || true

echo "==> Removing Autostart LaunchAgent..."
rm -f "$PLIST_PATH"

echo "==> Removing app bundle..."
rm -rf "$DEST_APP"

echo "WPMCounter uninstalled successfully."
