# Bug Fix Log: StatusBarController main actor isolation

Date: 2026-02-02

## Summary
`xcodebuild` failed because `StatusBarController` initialized `@MainActor` state (`SettingsStore.shared`) from a non-isolated context. The fix marks `StatusBarController` as `@MainActor` and adds a unit test to keep initialization on the main actor.

## Repro
1. Run build:
   `xcodebuild -scheme VercelBar -configuration Debug -derivedDataPath .derivedData build`
2. Observe compiler error in `StatusBarController.swift`:
   `call to main actor-isolated initializer 'init()' in a synchronous nonisolated context`.

## Test (TDD)
Added `StatusBarControllerTests.testStatusBarControllerInitializesOnMainActor` to ensure initialization occurs on the main actor.

## Fix
- Annotated `StatusBarController` with `@MainActor`.
- Added `Tests/StatusBarControllerTests.swift`.

## Verification
- Re-run build/tests after this change.
