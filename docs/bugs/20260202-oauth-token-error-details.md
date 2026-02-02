# Bug Fix Log: OAuth token error details

Date: 2026-02-02

## Summary
Token exchange failures were reported as a generic "Token exchange failed" message when the request failed outside the APIError path (e.g., network failure) or when the error body was not in the OAuth JSON shape. This made diagnosing OAuth issues difficult.

## Repro
1. Trigger OAuth token exchange failure (invalid code, bad redirect URI, or network failure).
2. Observe generic error text without status or server details.

## Test (TDD)
Added parser tests to assert fallback error messages for non-OAuth payloads and empty bodies.

## Fix
- Wrapped token exchange network failures as `APIError.networkFailure`.
- Always surface OAuth error details with HTTP status, including fallback text when the body is non-JSON.

## Verification
- OAuth errors now display an explicit HTTP status and payload when available.
- Tests pass (subject to test runner sandbox restrictions in this environment).
