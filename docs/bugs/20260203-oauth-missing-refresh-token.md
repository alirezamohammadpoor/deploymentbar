# Bug Fix Log: OAuth missing refresh token

Date: 2026-02-03

## Summary
The OAuth token exchange returned a valid access token but no refresh token. The app treated this as an invalid response and surfaced "Invalid response."

## Repro
1. Complete OAuth flow.
2. Token endpoint returns access_token without refresh_token.
3. App shows "Invalid response."

## Test (TDD)
Added `TokenPairTests` to validate refresh behavior when refresh tokens are missing.

## Fix
- Made `TokenPair.refreshToken` optional.
- Avoid refresh attempts when no refresh token exists.
- Prompt re-auth when the access token expires and cannot refresh.

## Verification
- OAuth token exchange succeeds with access-only tokens.
