#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_PATH="$ROOT_DIR/VercelBar.xcodeproj"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

require_env() {
  local var_name="$1"
  if [[ -z "${!var_name:-}" ]]; then
    fail "Missing required environment variable: $var_name"
  fi
}

echo "== VercelBar release preflight =="

[[ -d "$PROJECT_PATH" ]] || fail "Project not found at $PROJECT_PATH"

require_cmd xcodebuild
require_cmd xcrun
require_cmd security
require_cmd ditto
require_cmd hdiutil
require_cmd /usr/libexec/PlistBuddy

require_env VERCEL_CLIENT_ID
require_env VERCEL_REDIRECT_URI
require_env VERCEL_SCOPES
require_env APPLE_NOTARY_PROFILE
require_env SPARKLE_PUBLIC_ED_KEY

SPARKLE_GENERATE_APPCAST_BIN="${SPARKLE_GENERATE_APPCAST_BIN:-}"
if [[ -z "$SPARKLE_GENERATE_APPCAST_BIN" ]]; then
  SPARKLE_GENERATE_APPCAST_BIN="$(command -v generate_appcast || true)"
fi
if [[ -z "$SPARKLE_GENERATE_APPCAST_BIN" ]]; then
  fail "Sparkle generate_appcast binary not found (set SPARKLE_GENERATE_APPCAST_BIN)"
fi

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  fail "No Developer ID Application signing identity found in keychain"
fi

if ! xcrun notarytool history --keychain-profile "$APPLE_NOTARY_PROFILE" >/dev/null 2>&1; then
  fail "Notary profile '$APPLE_NOTARY_PROFILE' is unavailable or invalid"
fi

if [[ ! -f "$ROOT_DIR/Config/Secrets.xcconfig" ]]; then
  warn "Config/Secrets.xcconfig is missing. Build may fail if Xcode settings depend on it."
fi

INFO_PLIST="$ROOT_DIR/App/Info.plist"
[[ -f "$INFO_PLIST" ]] || fail "Info.plist not found at $INFO_PLIST"
/usr/libexec/PlistBuddy -c "Print :SUFeedURL" "$INFO_PLIST" >/dev/null 2>&1 \
  || fail "SUFeedURL is missing from App/Info.plist"
/usr/libexec/PlistBuddy -c "Print :SUPublicEDKey" "$INFO_PLIST" >/dev/null 2>&1 \
  || fail "SUPublicEDKey is missing from App/Info.plist"

echo "Preflight OK"
