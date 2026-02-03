# Bug Fix Log: OAuth token decode details

Date: 2026-02-03

## Summary
OAuth token exchange failures surfaced as a generic "Decode error" when the response returned HTTP 2xx with a non-token payload. This hid useful error details.

## Repro
1. Trigger token exchange that returns 2xx with a non-token payload (e.g., HTML or unexpected JSON).
2. Observe "Decode error" without any body or status context.

## Test (TDD)
Added an OAuth error parser test that formats a fallback message for an HTTP 200 response body.

## Fix
- When token decoding fails, emit an `oauthError` using the response body and status for diagnostics.

## Verification
- OAuth errors now include the response payload even for 2xx responses.
