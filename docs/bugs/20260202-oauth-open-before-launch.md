# Bug Fix Log: OAuth callback before launch

Date: 2026-02-02

## Summary
The OAuth redirect can trigger `application(_:open:)` before `applicationDidFinishLaunching`, which meant the single-instance lock was not yet acquired. This allowed a secondary instance to handle the callback and produced a state mismatch.

## Repro
1. Launch VercelBar.
2. Start OAuth sign-in.
3. Complete consent; the redirect opens the app again.
4. Callback arrives before `applicationDidFinishLaunching` and is handled by the secondary instance.

## Test (TDD)
Added `AppInstanceCoordinatorTests` to verify forwarding vs handling when the lock is or isn’t available.

## Fix
- Added `AppInstanceCoordinator` to acquire the lock on both launch and callback.
- Updated `AppDelegate` to use the coordinator for open URL handling.

## Verification
- Secondary instances forward the callback to the primary instance even if `openURL` happens before launch is complete.
