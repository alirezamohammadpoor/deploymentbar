# Bug Fix Log: Status item init hang

Date: 2026-02-03

## Summary
Status bar icon failed to appear. Logging showed `StatusBarController` creation began but never reached the init body, indicating a hang in the status item property initialization.

## Repro
1. Launch app.
2. Logs show `Creating StatusBarController` but no `StatusBarController init`.
3. No menu bar icon appears.

## Test (TDD)
Added a test that verifies the status item provider is called during initialization.

## Fix
- Moved status item creation into `StatusBarController` init using a provider.
- Added logging before and after status item creation.

## Verification
- Init logs are emitted and status item appears.
