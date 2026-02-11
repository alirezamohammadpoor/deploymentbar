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
require_cmd /usr/libexec/PlistBuddy

require_env VERCEL_CLIENT_ID
require_env VERCEL_REDIRECT_URI
require_env VERCEL_SCOPES
require_env APPLE_NOTARY_PROFILE

if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
  fail "No Developer ID Application signing identity found in keychain"
fi

if ! xcrun notarytool history --keychain-profile "$APPLE_NOTARY_PROFILE" >/dev/null 2>&1; then
  fail "Notary profile '$APPLE_NOTARY_PROFILE' is unavailable or invalid"
fi

if [[ ! -f "$ROOT_DIR/Config/Secrets.xcconfig" ]]; then
  warn "Config/Secrets.xcconfig is missing. Build may fail if Xcode settings depend on it."
fi

echo "Preflight OK"
