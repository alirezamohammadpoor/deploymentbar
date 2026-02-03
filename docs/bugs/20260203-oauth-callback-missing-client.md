# Bug Fix Log: OAuth callback missing client

Date: 2026-02-03

## Summary
After restart, OAuth callbacks could fail with "OAuth session not initialized" because the persisted state was loaded but the API client was not recreated.

## Repro
1. Start OAuth sign-in.
2. Quit/restart the app before completing consent.
3. Complete consent; callback returns.
4. Error: OAuth session not initialized.

## Test (TDD)
Manual verification after restart.

## Fix
- Lazily recreate the API client in `handleCallback()` when pending state is present.

## Verification
- OAuth callback succeeds after restart.
