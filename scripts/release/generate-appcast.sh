#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APPCAST_PATH="$ROOT_DIR/appcast.xml"
WORK_DIR="$ROOT_DIR/build/release/appcast"
ARCHIVE_DIR="$WORK_DIR/archives"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

require_env() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    fail "Missing required environment variable: $var_name"
  fi
}

ZIP_PATH="${ZIP_PATH:-}"
DOWNLOAD_URL="${DOWNLOAD_URL:-}"
RELEASE_NOTES_URL="${RELEASE_NOTES_URL:-}"
SPARKLE_GENERATE_APPCAST_BIN="${SPARKLE_GENERATE_APPCAST_BIN:-}"

if [[ -z "$SPARKLE_GENERATE_APPCAST_BIN" ]]; then
  SPARKLE_GENERATE_APPCAST_BIN="$(command -v generate_appcast || true)"
fi

if [[ -z "$SPARKLE_GENERATE_APPCAST_BIN" ]]; then
  fail "Unable to find Sparkle generate_appcast binary. Set SPARKLE_GENERATE_APPCAST_BIN."
fi

require_env SPARKLE_PRIVATE_KEY_FILE
[[ -f "$SPARKLE_PRIVATE_KEY_FILE" ]] || fail "Private key not found: $SPARKLE_PRIVATE_KEY_FILE"
[[ -n "$ZIP_PATH" ]] || fail "ZIP_PATH is required"
[[ -f "$ZIP_PATH" ]] || fail "ZIP archive not found: $ZIP_PATH"
[[ -n "$DOWNLOAD_URL" ]] || fail "DOWNLOAD_URL is required"
[[ -n "$RELEASE_NOTES_URL" ]] || fail "RELEASE_NOTES_URL is required"

rm -rf "$WORK_DIR"
mkdir -p "$ARCHIVE_DIR"
cp "$ZIP_PATH" "$ARCHIVE_DIR/"

"$SPARKLE_GENERATE_APPCAST_BIN" "$ARCHIVE_DIR" \
  --ed-key-file "$SPARKLE_PRIVATE_KEY_FILE" \
  --download-url-prefix "$(dirname "$DOWNLOAD_URL")/" \
  --link "$RELEASE_NOTES_URL" \
  --output-dir "$WORK_DIR"

GENERATED_APPCAST="$WORK_DIR/appcast.xml"
[[ -f "$GENERATED_APPCAST" ]] || fail "generate_appcast did not produce appcast.xml"

cp "$GENERATED_APPCAST" "$APPCAST_PATH"

echo "Appcast generated"
echo "APPCAST_PATH=$APPCAST_PATH"
