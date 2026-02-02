# Bug Fix Log: Token exchange errors lacked details

Date: 2026-02-02

## Summary
OAuth token exchange failures showed a generic "Token exchange failed" message, which made it hard to diagnose configuration issues (invalid redirect URI, client id, or client secret). Added OAuth error parsing and surfaced descriptive error messages from the token endpoint.

## Repro
1. Attempt OAuth sign-in with invalid client credentials or redirect URI.
2. Observe generic error message in the app.

## Test (TDD)
Added `OAuthErrorParserTests` to ensure OAuth error JSON is parsed into user-visible messages.

## Fix
- Added `OAuthErrorParser` to parse `error` and `error_description` from OAuth responses.
- Added `APIError.oauthError` and wired token exchange to throw it on non-2xx responses.
- Updated `AuthSession` to surface OAuth error messages to the UI.

## Verification
- OAuth error responses now show the exact error and description.
