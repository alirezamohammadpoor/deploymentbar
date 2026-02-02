# Bug Fix Log: OAuth state mismatch details

Date: 2026-02-02

## Summary
OAuth state mismatch errors lacked context, making it unclear whether the code or state was missing, or whether the expected state was lost. Added a diagnostic message to distinguish missing parameters from true mismatch.

## Repro
1. Complete OAuth redirect when the app has lost the pending state.
2. Observe "OAuth state mismatch" with no details.

## Test (TDD)
Added tests covering missing code, missing state, and mismatched state details.

## Fix
- Guard duplicate sign-in attempts.
- Added detailed mismatch message including expected/received state.

## Verification
- Error now includes specific mismatch details.
- Tests pass (subject to test runner sandbox restrictions in this environment).
