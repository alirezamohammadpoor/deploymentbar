# VercelBar Setup

Last updated: 2026-02-02

## OAuth configuration
Set these keys in `App/Info.plist` before running:
- `VercelClientId`: OAuth client ID from Vercel.
- `VercelClientSecret`: Optional; include if your OAuth app requires it.
- `VercelRedirectURI`: Must match the OAuth app redirect. Default: `vercelbar://oauth/callback`.
- `VercelScopes`: Space-delimited scopes. Recommended: `offline_access`.

## URL scheme
Ensure your OAuth redirect uses the `vercelbar` custom URL scheme so the app can receive the callback.

## Notes
- Current scope is personal account only (no team scopes).
- Targets/branches: all.
