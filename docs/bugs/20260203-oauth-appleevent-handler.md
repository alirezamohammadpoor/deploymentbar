# Bug Fix Log: OAuth AppleEvent handler

Date: 2026-02-03

## Summary
`application(_:open:)` did not reliably receive `vercelbar://` callbacks for an LSUIElement app. Registering for kAEGetURL events guarantees delivery.

## Repro
1. Trigger OAuth callback.
2. App does not receive `application(_:open:)`.
3. Secondary instance may launch or the callback is dropped.

## Test (TDD)
Manual verification using OAuth flow.

## Fix
- Register `NSAppleEventManager` handler for `kAEGetURL`.

## Verification
- OAuth callback is delivered consistently.
