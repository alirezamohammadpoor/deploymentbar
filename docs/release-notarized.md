# VercelBar Notarized Release (Direct Download)

## Scope
This release path builds a signed macOS `.app`, notarizes it with Apple, staples notarization, and emits deterministic ZIP artifacts for direct download. Optional DMG packaging/notarization is supported.

Bundle ID remains `com.example.VercelBar` in this cycle.

## Prerequisites
- Xcode + command line tools
- Developer ID Application certificate in login keychain
- Notary profile configured for `notarytool`
- Required env vars:
  - `VERCEL_CLIENT_ID`
  - `VERCEL_REDIRECT_URI`
  - `VERCEL_SCOPES`
  - `APPLE_NOTARY_PROFILE`

## Commands
Run from repo root:

```bash
./scripts/release/preflight.sh
./scripts/release/archive.sh
./scripts/release/package.sh
./scripts/release/notarize.sh
```

Optional DMG artifact:
```bash
CREATE_DMG=1 ./scripts/release/package.sh
NOTARIZE_DMG=1 ./scripts/release/notarize.sh
```

## Artifact Paths
- Archive: `build/release/VercelBar.xcarchive`
- App bundle copy: `build/release/VercelBar.app`
- Pre-notary ZIP: `build/release/artifacts/VercelBar-<version>-<build>.zip`
- Notarized ZIP: `build/release/artifacts/VercelBar-<version>-<build>-notarized.zip`
- Optional pre-notary DMG: `build/release/artifacts/VercelBar-<version>-<build>.dmg`
- Optional notarized DMG: `build/release/artifacts/VercelBar-<version>-<build>-notarized.dmg`

## Troubleshooting
1. `Missing APPLE_NOTARY_PROFILE`
- Export `APPLE_NOTARY_PROFILE` and ensure it exists in keychain.

2. `No Developer ID Application signing identity found`
- Install/import Developer ID Application certificate in login keychain.

3. Notary submission rejected
- Re-run with the same ZIP and inspect output from:
  - `xcrun notarytool submit ... --wait`

4. Build fails because OAuth config values are empty
- Ensure `VERCEL_CLIENT_ID`, `VERCEL_REDIRECT_URI`, and `VERCEL_SCOPES` are exported in the shell running scripts.

## Future switch to production bundle ID
Before public release:
1. Update `project.yml` bundle identifier.
2. Regenerate project with `xcodegen`.
3. Recreate signing profiles/certs for the new identifier.
4. Re-run full notarized pipeline.

## In-app update checks
The app performs manual update checks via GitHub Releases API.
