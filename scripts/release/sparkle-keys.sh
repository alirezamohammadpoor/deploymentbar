#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

SPARKLE_GENERATE_KEYS_BIN="${SPARKLE_GENERATE_KEYS_BIN:-}"
if [[ -z "$SPARKLE_GENERATE_KEYS_BIN" ]]; then
  SPARKLE_GENERATE_KEYS_BIN="$(command -v generate_keys || true)"
fi

if [[ -z "$SPARKLE_GENERATE_KEYS_BIN" ]]; then
  fail "Unable to find Sparkle generate_keys binary. Set SPARKLE_GENERATE_KEYS_BIN."
fi

echo "== Generating Sparkle keys =="
"$SPARKLE_GENERATE_KEYS_BIN"

cat <<EOF

Next steps:
1) Copy the generated public key into Config/Secrets.xcconfig as:
   SPARKLE_PUBLIC_ED_KEY = <public-key>
2) Store your private key path in your shell profile:
   export SPARKLE_PRIVATE_KEY_FILE=/absolute/path/to/private_key
3) Regenerate project:
   $ROOT_DIR/scripts/dev/regenerate-project.sh
EOF
