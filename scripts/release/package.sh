#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/release"
APP_PATH="$BUILD_DIR/VercelBar.app"
ARTIFACTS_DIR="$BUILD_DIR/artifacts"
PLIST_PATH="$APP_PATH/Contents/Info.plist"

if [[ "${CREATE_DMG:-0}" == "1" ]]; then
  echo "ERROR: DMG packaging is intentionally disabled in this cycle. Use ZIP artifacts." >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  "$ROOT_DIR/scripts/release/archive.sh"
fi

if [[ ! -f "$PLIST_PATH" ]]; then
  echo "ERROR: App Info.plist missing at $PLIST_PATH" >&2
  exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST_PATH")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST_PATH")
mkdir -p "$ARTIFACTS_DIR"

ZIP_PATH="$ARTIFACTS_DIR/VercelBar-${VERSION}-${BUILD}.zip"
NOTARIZED_ZIP_PATH="$ARTIFACTS_DIR/VercelBar-${VERSION}-${BUILD}-notarized.zip"

rm -f "$ZIP_PATH" "$NOTARIZED_ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Package complete"
echo "ZIP_PATH=$ZIP_PATH"
