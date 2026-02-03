# Bug Fix Log: OAuth stale URL handler

Date: 2026-02-03

## Summary
OAuth redirects sometimes launched an older build (from a different DerivedData path) because Launch Services still pointed the `vercelbar://` scheme at a stale app bundle. The stale instance lacked the latest single-instance guards, so it created duplicate menu bar icons and state mismatches.

## Repro
1. Run VercelBar from Xcode (new build).
2. Complete OAuth consent; macOS launches a different, older build path.
3. Two instances appear; state mismatch occurs.

## Test (TDD)
Added `URLSchemeRegistrarTests` to validate registration guard logic for `.app` bundles.

## Fix
- Registered the current bundle with Launch Services on startup to ensure the `vercelbar://` handler points to the running build.

## Verification
- OAuth redirect now opens the running build instead of a stale DerivedData bundle.
