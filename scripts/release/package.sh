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
# Stable-named copy for the website's releases/latest/download/Deploymentbar.dmg link.
STABLE_DMG_PATH="$ARTIFACTS_DIR/Deploymentbar.dmg"

# Clean stale artifacts up front — including the stable-named DMG, so a previous
# run's Deploymentbar.dmg can never be re-uploaded when this run skips CREATE_DMG.
rm -f "$ZIP_PATH" "$NOTARIZED_ZIP_PATH" "$DMG_PATH" "$NOTARIZED_DMG_PATH" "$STABLE_DMG_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Package complete"
echo "ZIP_PATH=$ZIP_PATH"
echo "Use this ZIP for Sparkle updates after notarization."

BG_IMAGE="$ROOT_DIR/scripts/release/assets/dmg-background.png"
VOL_ICON="$ROOT_DIR/Resources/AppIcon.icns"

if [[ "${CREATE_DMG:-0}" == "1" ]]; then
  rm -rf "$DMG_ROOT"
  mkdir -p "$DMG_ROOT"
  cp -R "$APP_PATH" "$DMG_ROOT/"

  if command -v create-dmg >/dev/null 2>&1; then
    # Styled "drag to Applications" window. create-dmg can exit non-zero on a
    # benign AppleScript step, so guard with `|| true` and verify the file after.
    CREATE_DMG_ARGS=(
      --volname "Deploymentbar"
      --window-pos 200 120
      --window-size 660 400
      --icon-size 128
      --icon "VercelBar.app" 165 190
      --hide-extension "VercelBar.app"
      --app-drop-link 495 190
      --no-internet-enable
    )
    if [[ -f "$BG_IMAGE" ]]; then
      CREATE_DMG_ARGS+=(--background "$BG_IMAGE")
    else
      echo "NOTE: $BG_IMAGE not found — building DMG without custom background art."
    fi
    if [[ -f "$VOL_ICON" ]]; then
      CREATE_DMG_ARGS+=(--volicon "$VOL_ICON")
    fi
    create-dmg "${CREATE_DMG_ARGS[@]}" "$DMG_PATH" "$DMG_ROOT" || true

    if [[ ! -f "$DMG_PATH" ]]; then
      echo "ERROR: create-dmg did not produce $DMG_PATH" >&2
      exit 1
    fi
  else
    echo "NOTE: 'create-dmg' not installed — falling back to a plain DMG."
    echo "      Install the styled installer window with: brew install create-dmg"
    hdiutil create \
      -volname "Deploymentbar" \
      -srcfolder "$DMG_ROOT" \
      -ov \
      -format UDZO \
      "$DMG_PATH"
  fi

  cp "$DMG_PATH" "$STABLE_DMG_PATH"
  echo "DMG_PATH=$DMG_PATH"
  echo "STABLE_DMG_PATH=$STABLE_DMG_PATH"
  echo "Upload Deploymentbar.dmg to the GitHub release so the website button resolves."
fi
