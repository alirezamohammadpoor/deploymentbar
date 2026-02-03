# Bug Fix Log: Missing vercelDecoder

Date: 2026-02-03

## Summary
`JSONDecoder.vercelDecoder` was removed when token decoding was refactored, causing a build error in the generic API decode path.

## Repro
1. Build project after token parser changes.
2. Compiler error: no member `vercelDecoder`.

## Fix
- Restored `JSONDecoder.vercelDecoder` in a dedicated extension file.

## Verification
- Project builds successfully.
