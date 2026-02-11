# 2026-02-11 — OAuth recovery lacked explicit reset/retry path

## Summary
When OAuth callback state was invalid, users could get stuck in an error state without a direct in-app recovery action.

## Reproduction
1. Start OAuth sign-in.
2. Complete callback with mismatched `state`.
3. Observe error shown in the auth view.
4. Prior behavior: no explicit reset/retry controls in the auth panel.

## TDD
Added failing tests first:
- `Tests/AuthSessionRecoveryTests.swift`
  - `testStateMismatchSetsStructuredErrorAndIsRecoverable`
  - `testRetryAuthorizationStartsSignInAgain`

## Root Cause
`AuthSession` tracked sign-in status text but not structured auth error metadata, and did not expose recovery APIs for a clean state reset and retry path.

## Fix
- Added structured auth error codes in `AuthSession.AuthErrorCode`.
- Added `pendingAuthStartedAt` and `lastAuthErrorCode`.
- Added `resetPendingAuthorization(manual:)` and `retryAuthorization()`.
- Added recovery actions to `OAuthFlowView`:
  - `Retry Sign-In`
  - `Reset Auth Session`

## Verification
`xcodebuild test -project VercelBar.xcodeproj -scheme VercelBar -destination 'platform=macOS'`
- New recovery tests pass.
- Existing auth tests pass.
