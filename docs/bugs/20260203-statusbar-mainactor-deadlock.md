# Bug Fix Log: StatusBarController main actor deadlock

Date: 2026-02-03

## Summary
`StatusBarController` initialization appeared to hang before running its init body. The class was marked `@MainActor`, and the initialization path could deadlock during early app launch.

## Repro
1. Launch app from Xcode.
2. Logs show "Creating StatusBarController" but no init logs.
3. No menu bar icon appears.

## Fix
- Removed `@MainActor` annotation from `StatusBarController`.
- Kept creation on the main actor in `AppDelegate`.

## Verification
- Init logs appear and status item shows.
