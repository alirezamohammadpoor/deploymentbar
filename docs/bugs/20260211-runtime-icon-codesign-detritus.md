# 2026-02-11 — Runtime icon mutation breaks CodeSign

## Summary
`xcodebuild` intermittently failed during codesigning with:
- `resource fork, Finder information, or similar detritus not allowed`

Root cause was mutating the built app bundle icon metadata at runtime via `NSWorkspace.setIcon(_:forFile:)` in `AppDelegate`.

## Reproduction
1. Run the app from Xcode.
2. Build or test again.
3. Observe CodeSign failure for the app or test bundle:
```text
resource fork, Finder information, or similar detritus not allowed
```

## Root cause
`App/AppDelegate.swift` previously called:
- `NSWorkspace.shared.setIcon(icon, forFile: Bundle.main.bundlePath, ...)`

That call writes Finder metadata (`Icon\r` / Finder info) into the bundle path, which is not allowed by code signing in subsequent builds.

## TDD
Added regression test first:
- `Tests/AppDelegateIconTests.swift`
- `testApplyApplicationIconDoesNotCallWorkspaceSetIcon`

The test asserts:
- app icon assignment still happens,
- workspace-level icon mutation is **not** called,
- no `Icon\r` metadata file appears in bundle path.

## Fix
In `App/AppDelegate.swift`:
- introduced `applyApplicationIcon(...)` path that only sets:
  - `NSApplication.applicationIconImage`
- removed runtime use of `NSWorkspace.setIcon(_:forFile:)`.

## Verification
1. `xcodebuild test -project VercelBar.xcodeproj -scheme VercelBar -destination 'platform=macOS'`
2. Confirmed regression test passes and no icon-mutation call path is used.
