# Repo Hygiene Workflow (2026-02-11)

## Problem
Repeated ad-hoc `xcodegen` runs created duplicate project folders (`VercelBar 2.xcodeproj`, `VercelBar 3.xcodeproj`, etc.) which caused drift and confusion during debugging.

## Standard Workflow
1. Regenerate only through the helper script:
```bash
./scripts/dev/regenerate-project.sh
```
2. Confirm only the canonical project exists:
```bash
ls -d VercelBar*.xcodeproj
```
Expected output:
```text
VercelBar.xcodeproj
```
3. Build/test from the canonical project:
```bash
xcodebuild test -project VercelBar.xcodeproj -scheme VercelBar -destination 'platform=macOS'
```

## Guardrails Added
- `.gitignore` now ignores accidental duplicate project names (`VercelBar *.xcodeproj/`).
- `scripts/dev/regenerate-project.sh` validates `xcodegen` and `project.yml` before generating.
- Canonical project path remains `VercelBar.xcodeproj`.
