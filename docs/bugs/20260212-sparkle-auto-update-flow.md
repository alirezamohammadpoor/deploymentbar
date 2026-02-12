# 2026-02-12 — Check for Updates did not install updates

## Summary
The Settings action **Check for Updates** only queried GitHub Releases and opened a browser page. Users could not download/install updates in-app, which blocked the expected direct-distribution update flow.

## Reproduction
1. Install app version `1.0`.
2. Publish release `1.0.1`.
3. Click **Check for Updates** in Settings.
4. Previous behavior: app opened GitHub release URL; no in-app installer flow.

## TDD
Added failing tests first:
- `Tests/SparkleUpdateServiceTests.swift`
  - `testCheckForUpdatesStartsCheckingAndCallsDriver`
  - `testDidFindUpdateTransitionsToUpdateInitiated`
  - `testDidNotFindUpdateTransitionsToUpToDate`
  - `testDidFailTransitionsToFailed`
- `Tests/UpdateManagerTests.swift`
  - `testCheckForUpdatesDelegatesToService`
  - `testCheckingStatusMapsToLoadingText`
  - `testUpToDateStatusMapsToInfoText`
  - `testUpdateFoundStatusMapsToSuccessText`
  - `testFailureStatusMapsToErrorText`

## Root Cause
Update logic was implemented as a GitHub API poller (`releases/latest`) without an installer/runtime update framework. It could only inform users, not apply updates.

## Fix
- Integrated Sparkle runtime package into app target.
- Added `SparkleUpdateService` to drive update checks and status transitions.
- Refactored `UpdateManager` to consume Sparkle service states and keep Settings UI contract.
- Added Sparkle Info.plist keys (`SUFeedURL`, `SUPublicEDKey`, automatic check/install flags).
- Added release scripts and docs for Sparkle key generation and appcast generation.

## Verification
`xcodebuild test -project VercelBar.xcodeproj -scheme VercelBar -destination 'platform=macOS' -only-testing:VercelBarTests/UpdateManagerTests -only-testing:VercelBarTests/SparkleUpdateServiceTests`
- All Sparkle/update manager tests pass.
