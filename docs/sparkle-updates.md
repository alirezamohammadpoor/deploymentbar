# Sparkle Updates Integration

## What is wired
- Sparkle 2 is integrated in-app through `UpdaterStore`.
- App startup calls `UpdaterStore.shared.startIfConfigured()`.
- Users can manually trigger update checks from:
  - Status bar menu header (`arrow.down.circle`)
  - Settings > Updates > `Check for Updates…`

## Required configuration
Set both values in `Config/Secrets.xcconfig` (or exported environment variables):

```xcconfig
SPARKLE_FEED_URL = https://<your-domain>/appcast.xml
SPARKLE_PUBLIC_ED_KEY = <your-public-ed25519-key>
```

If `SPARKLE_FEED_URL` is missing or invalid, updater controls remain visible but checks fail with a clear message.

## Appcast hosting
Host your `appcast.xml` over HTTPS on a stable URL, then point `SPARKLE_FEED_URL` at it.

Recommended options:
- GitHub Releases + static appcast in repo pages/hosted site
- Vercel static route for `appcast.xml`

## Local verification checklist
1. Build and run app.
2. Open Settings > Updates.
3. Verify feed host appears.
4. Click `Check for Updates…`.
5. Confirm Sparkle update window appears or reports no updates.
