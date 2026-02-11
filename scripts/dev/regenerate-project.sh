#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "error: xcodegen is not installed. Install with: brew install xcodegen"
  exit 1
fi

if [[ ! -f "project.yml" ]]; then
  echo "error: project.yml not found in $ROOT_DIR"
  exit 1
fi

echo "Regenerating Xcode project from project.yml..."
xcodegen generate

echo "Project regenerated: $ROOT_DIR/VercelBar.xcodeproj"
