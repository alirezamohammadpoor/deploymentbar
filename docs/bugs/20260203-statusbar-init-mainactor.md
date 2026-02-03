# Bug Fix Log: StatusBarController init on main actor

Date: 2026-02-03

## Summary
Status bar UI failed to appear despite the app running. The controller init was invoked during launch without an explicit main-actor hop, which could stall during early app lifecycle.

## Repro
1. Launch app from Xcode.
2. App runs but status item never appears.

## Fix
- Create `StatusBarController` inside a `Task { @MainActor in ... }` to ensure main-actor initialization after launch.

## Verification
- Status bar icon appears reliably after launch.
