# Bug Fix Log: OAuth token JSON decode

Date: 2026-02-03

## Summary
OAuth token exchange returned a valid payload but decoding failed, surfacing as "Decode error". The parser now supports both JSON and form-encoded token responses.

## Repro
1. Complete OAuth flow.
2. Token endpoint returns a valid token payload.
3. App shows "Decode error".

## Test (TDD)
Added `TokenResponseParserTests` to validate JSON and form-encoded parsing.

## Fix
- Added `TokenResponseParser` to parse JSON or form-encoded token responses.
- Updated token exchange to use the new parser.

## Verification
- OAuth token exchange succeeds for both response formats.
