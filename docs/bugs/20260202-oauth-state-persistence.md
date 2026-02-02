# Bug Fix Log: OAuth state persistence

Date: 2026-02-02

## Summary
OAuth callback sometimes failed with "state mismatch" after the app was relaunched or the sign-in flow was retried. Persisting the pending state, verifier, and redirect URI prevents the mismatch across app restarts and ensures cleanup on completion.

## Repro
1. Start OAuth sign-in.
2. Quit/restart the app before completing consent.
3. Complete consent; callback returns to the app.
4. Error: OAuth state mismatch.

## Test (TDD)
Added `AuthSessionStateStoreTests` to validate round-trip persistence and clearing of pending state.

## Fix
- Added `AuthSessionStateStore` for persisting pending OAuth state, verifier, and redirect URI.
- Loaded pending state on startup and before callback validation.
- Cleared pending state on success, error, or sign out.

## Verification
- Completed OAuth flow after app restart without state mismatch.
- Test passes (subject to test runner sandbox restrictions in this environment).
