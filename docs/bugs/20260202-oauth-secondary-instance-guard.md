# Bug Fix Log: OAuth secondary instance guard

Date: 2026-02-02

## Summary
OAuth redirect launches a second app instance that can race the primary instance and cause a state mismatch. Added a process-level lock so only one instance initializes UI, and secondary instances forward OAuth callbacks then terminate.

## Repro
1. Launch VercelBar.
2. Start OAuth sign-in.
3. Complete consent; redirect opens another instance.
4. Two menu bar icons appear and state mismatch occurs.

## Test (TDD)
Added `AppInstanceLockTests` to verify that a second lock acquire fails.

## Fix
- Added `AppInstanceLock` using a lock file.
- `AppDelegate` now treats lock failure as a secondary instance and exits after forwarding callbacks.

## Verification
- Second instance no longer shows a menu bar item.
- OAuth redirect is handled by the primary instance.
