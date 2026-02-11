#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$ROOT_DIR/build/release"
APP_PATH="$BUILD_DIR/VercelBar.app"
ARTIFACTS_DIR="$BUILD_DIR/artifacts"
NOTARIZE_DMG="${NOTARIZE_DMG:-0}"

if [[ -z "${APPLE_NOTARY_PROFILE:-}" ]]; then
  echo "ERROR: Missing APPLE_NOTARY_PROFILE" >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  "$ROOT_DIR/scripts/release/archive.sh"
fi

if [[ ! -d "$ARTIFACTS_DIR" ]]; then
  mkdir -p "$ARTIFACTS_DIR"
fi

ZIP_PATH="${ZIP_PATH:-}"
if [[ -z "$ZIP_PATH" || ! -f "$ZIP_PATH" ]]; then
  "$ROOT_DIR/scripts/release/package.sh"
  ZIP_PATH="$(ls -1t "$ARTIFACTS_DIR"/VercelBar-*.zip | grep -v -- "-notarized.zip$" | head -n 1)"
fi

if [[ -z "$ZIP_PATH" || ! -f "$ZIP_PATH" ]]; then
  echo "ERROR: Source zip not found for notarization" >&2
  exit 1
fi

echo "== Notarizing =="
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$APPLE_NOTARY_PROFILE" --wait

echo "== Stapling =="
xcrun stapler staple "$APP_PATH"

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$APP_PATH/Contents/Info.plist")
NOTARIZED_ZIP_PATH="$ARTIFACTS_DIR/VercelBar-${VERSION}-${BUILD}-notarized.zip"
rm -f "$NOTARIZED_ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$NOTARIZED_ZIP_PATH"

if [[ "$NOTARIZE_DMG" == "1" ]]; then
  CREATE_DMG=1 "$ROOT_DIR/scripts/release/package.sh" >/dev/null
  DMG_PATH="${DMG_PATH:-$ARTIFACTS_DIR/VercelBar-${VERSION}-${BUILD}.dmg}"
  if [[ ! -f "$DMG_PATH" ]]; then
    echo "ERROR: Source dmg not found for notarization at $DMG_PATH" >&2
    exit 1
  fi

  echo "== Notarizing DMG =="
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$APPLE_NOTARY_PROFILE" --wait

  echo "== Stapling DMG =="
  xcrun stapler staple "$DMG_PATH"

  NOTARIZED_DMG_PATH="$ARTIFACTS_DIR/VercelBar-${VERSION}-${BUILD}-notarized.dmg"
  rm -f "$NOTARIZED_DMG_PATH"
  cp "$DMG_PATH" "$NOTARIZED_DMG_PATH"
fi

spctl --assess --type execute --verbose "$APP_PATH"

echo "Notarization complete"
echo "NOTARIZED_ZIP_PATH=$NOTARIZED_ZIP_PATH"
if [[ "$NOTARIZE_DMG" == "1" ]]; then
  echo "NOTARIZED_DMG_PATH=$NOTARIZED_DMG_PATH"
fi
