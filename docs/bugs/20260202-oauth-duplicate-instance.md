# Bug Fix Log: OAuth duplicate instance

Date: 2026-02-02

## Summary
OAuth redirect launches a second app instance, which causes a state mismatch and leaves two menu bar items running. The duplicate instance should forward the callback URL to the existing instance and exit.

## Repro
1. Launch VercelBar.
2. Start OAuth sign-in.
3. Complete consent; the redirect opens the app again.
4. Two menu bar icons appear and the OAuth state mismatches.

## Test (TDD)
Added `AppInstanceCheckerTests` to verify duplicate detection logic.

## Fix
- Added `AppInstanceChecker` for detecting duplicate instances.
- Added `AppInstanceMessenger` to forward callback URLs to the original instance via `DistributedNotificationCenter`.
- Updated `AppDelegate` to forward the callback and terminate if this is a secondary instance.

## Verification
- OAuth redirect no longer leaves a second instance running.
- Callback is handled by the original instance and state matches.
