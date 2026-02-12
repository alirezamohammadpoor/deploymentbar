# Sparkle Update Publishing (GitHub Releases + ZIP)

## One-time setup
1. Generate Sparkle keys locally:
   ```bash
   ./scripts/release/sparkle-keys.sh
   ```
2. Save the public key into `Config/Secrets.xcconfig`:
   ```xcconfig
   SPARKLE_PUBLIC_ED_KEY = <public-key>
   ```
3. Export private key path in shell:
   ```bash
   export SPARKLE_PRIVATE_KEY_FILE=/absolute/path/to/sparkle_private_key
   ```
4. Regenerate the Xcode project:
   ```bash
   ./scripts/dev/regenerate-project.sh
   ```

## Per release
1. Build + notarize:
   ```bash
   ./scripts/release/preflight.sh
   ./scripts/release/archive.sh
   ./scripts/release/package.sh
   RELEASE_TAG=v<version> ./scripts/release/notarize.sh
   ```
2. `notarize.sh` will generate/update `appcast.xml` by default (`GENERATE_APPCAST=1`).
3. Commit and push `appcast.xml`.
4. Upload the notarized ZIP asset from `build/release/artifacts/` to the matching GitHub tag.

## Variables
- `SPARKLE_GENERATE_APPCAST_BIN`: path to Sparkle `generate_appcast` binary.
- `SPARKLE_PRIVATE_KEY_FILE`: private EdDSA key file for signing appcast entries.
- `RELEASE_TAG`: defaults to `v<CFBundleShortVersionString>`.
- `DOWNLOAD_URL`: optional full URL override for update ZIP.
- `RELEASE_NOTES_URL`: optional full URL override for release notes page.

## App wiring
- `SUFeedURL`: `https://raw.githubusercontent.com/alirezamohammadpoor/deploymentbar/main/appcast.xml`
- `SUPublicEDKey`: resolved from `$(SPARKLE_PUBLIC_ED_KEY)` in `App/Info.plist`.
- Settings button **Check for Updates** triggers Sparkle flow.
