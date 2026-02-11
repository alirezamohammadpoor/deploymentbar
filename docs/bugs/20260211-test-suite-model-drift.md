# 2026-02-11 — Test suite model/actor drift

## Summary
`xcodebuild test` currently fails at compile time due to test code not matching updated production signatures and actor annotations.

## Reproduction
1. Run:
```bash
xcodebuild test -project VercelBar.xcodeproj -scheme VercelBar -destination 'platform=macOS' -derivedDataPath .derivedData
```
2. Observe compile failures in test target.

## Observed failures
- `AuthSessionStateMismatchTests` calls `AuthSession.stateMismatchMessage(...)` from non-main-actor test methods.
- `TokenPairTests` uses old `TokenPair` initializer missing `teamId`.
- `TokenResponseParserTests` uses old `Parsed` initializer missing `teamId`.

## Expected
- Test target compiles and executes successfully.

## Notes
- This is a regression caused by API/model evolution without synchronized test updates.
- Must be fixed before feature work to restore confidence and enable TDD for bug fixes.
