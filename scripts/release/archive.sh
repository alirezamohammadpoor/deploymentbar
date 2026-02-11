#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_PATH="$ROOT_DIR/VercelBar.xcodeproj"
SCHEME="VercelBar"
CONFIGURATION="Release"
BUILD_DIR="$ROOT_DIR/build/release"
ARCHIVE_PATH="$BUILD_DIR/VercelBar.xcarchive"
APP_PATH="$BUILD_DIR/VercelBar.app"

if [[ "${SKIP_PREFLIGHT:-0}" != "1" ]]; then
  "$ROOT_DIR/scripts/release/preflight.sh"
fi

mkdir -p "$BUILD_DIR"
rm -rf "$ARCHIVE_PATH" "$APP_PATH"

echo "== Archiving =="
xcodebuild archive \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -archivePath "$ARCHIVE_PATH"

ARCHIVED_APP="$ARCHIVE_PATH/Products/Applications/VercelBar.app"
if [[ ! -d "$ARCHIVED_APP" ]]; then
  echo "ERROR: archived app not found at $ARCHIVED_APP" >&2
  exit 1
fi

ditto "$ARCHIVED_APP" "$APP_PATH"

echo "Archive complete"
echo "ARCHIVE_PATH=$ARCHIVE_PATH"
echo "APP_PATH=$APP_PATH"
