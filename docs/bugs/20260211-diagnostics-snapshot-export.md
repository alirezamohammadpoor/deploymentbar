# 2026-02-11 — Diagnostics snapshot/export path was missing

## Summary
The app had runtime logs but no in-app diagnostics export path, making support/debugging rely on terminal-only instructions.

## Reproduction
1. Encounter OAuth or refresh failure in menu bar app.
2. Open Settings.
3. Prior behavior: no diagnostics section, no snapshot copy, no log management controls.

## TDD
Added tests first:
- `Tests/DebugLogTests.swift`
  - `testWriteIncludesLevelAndComponent`
  - `testRotateWhenLogExceedsMaxSize`
- `Tests/DiagnosticsStoreTests.swift`
  - `testRecentLogLinesReturnsTail`
  - `testBuildSnapshotContainsCoreSections`
  - `testClearLogsRemovesLogFile`

## Root Cause
- Logging utility was unstructured and lacked rotation.
- No service existed to aggregate app/auth/refresh/settings state into a support snapshot.
- Settings UI had no diagnostics actions.

## Fix
- Extended `DebugLog` with structured levels/components and rotation.
- Added `DiagnosticsStore` for:
  - recent log lines
  - snapshot assembly
  - log cleanup
- Added `DiagnosticsView` section in settings with:
  - copy diagnostics snapshot
  - open log file
  - clear logs

## Verification
`xcodebuild test -project VercelBar.xcodeproj -scheme VercelBar -destination 'platform=macOS'`
- New diagnostics/log tests pass.
- Existing suite remains green.
