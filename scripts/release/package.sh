#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/release"
APP_PATH="$BUILD_DIR/VercelBar.app"
ARTIFACTS_DIR="$BUILD_DIR/artifacts"
PLIST_PATH="$APP_PATH/Contents/Info.plist"
DMG_ROOT="$BUILD_DIR/dmg-root"

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
DMG_PATH="$ARTIFACTS_DIR/VercelBar-${VERSION}-${BUILD}.dmg"
NOTARIZED_DMG_PATH="$ARTIFACTS_DIR/VercelBar-${VERSION}-${BUILD}-notarized.dmg"

rm -f "$ZIP_PATH" "$NOTARIZED_ZIP_PATH" "$NOTARIZED_DMG_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Package complete"
echo "ZIP_PATH=$ZIP_PATH"

if [[ "${CREATE_DMG:-0}" == "1" ]]; then
  mkdir -p "$DMG_ROOT"
  rm -rf "$DMG_ROOT"/*
  cp -R "$APP_PATH" "$DMG_ROOT/"
  rm -f "$DMG_PATH"
  hdiutil create \
    -volname "VercelBar" \
    -srcfolder "$DMG_ROOT" \
    -ov \
    -format UDZO \
    "$DMG_PATH"
  echo "DMG_PATH=$DMG_PATH"
fi
