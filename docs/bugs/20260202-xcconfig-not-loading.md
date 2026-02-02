# Bug Fix Log: Secrets xcconfig not loading

Date: 2026-02-02

## Summary
The app reported missing OAuth config because XcodeGen was not applying the `Config/Secrets.xcconfig` base configuration. Build settings lacked `VERCEL_*` values, resulting in empty Info.plist keys.

## Repro
1. Create `Config/Secrets.xcconfig` with values.
2. Run `xcodegen` and launch the app.
3. Observe: "Missing Vercel OAuth config in Info.plist".
4. `xcodebuild -showBuildSettings` showed missing `VERCEL_*` values.

## Test (TDD)
Manual build settings inspection used due to sandboxed test runner limitations (tests cannot communicate with `testmanagerd`).

## Fix
- Moved `configFiles` to the correct level in `project.yml` so XcodeGen applies the base configuration.

## Verification
- `xcodebuild -showBuildSettings` now shows non-empty `VERCEL_*` values.
- App no longer reports missing OAuth config when `Config/Secrets.xcconfig` is populated.
