# VercelBar Setup

Last updated: 2026-02-02

## OAuth configuration (environment-based)
Set these environment variables before running `xcodegen` or building:
- `VERCEL_CLIENT_ID`
- `VERCEL_CLIENT_SECRET` (optional if your OAuth app doesn’t require it)
- `VERCEL_REDIRECT_URI` (default: `vercelbar://oauth/callback`)
- `VERCEL_SCOPES` (default: `offline_access`)

Example:
```bash
export VERCEL_CLIENT_ID=cl_xxx
export VERCEL_CLIENT_SECRET=shh_xxx
export VERCEL_REDIRECT_URI=vercelbar://oauth/callback
export VERCEL_SCOPES=offline_access
```

Alternative local file:
- Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` and fill in values.
- The file is gitignored.
- You can inject it by exporting env vars or by adding it to your local build settings.

## URL scheme
Ensure your OAuth redirect uses the `vercelbar` custom URL scheme so the app can receive the callback.

## Notes
- Current scope is personal account only (no team scopes).
- Targets/branches: all.
