# VercelBar Setup

Last updated: 2026-02-02

## OAuth configuration (environment-based)
Set these environment variables before running `xcodegen` or building:
- `VERCEL_CLIENT_ID`
- `VERCEL_CLIENT_SECRET` (optional if your OAuth app doesn’t require it)
- `VERCEL_REDIRECT_URI` (should be an HTTPS redirect helper URL)
- `VERCEL_SCOPES` (default: `offline_access`)

Example:
```bash
export VERCEL_CLIENT_ID=cl_xxx
export VERCEL_CLIENT_SECRET=shh_xxx
export VERCEL_REDIRECT_URI=https://<your-redirect-site>.vercel.app/oauth/callback
export VERCEL_SCOPES=offline_access
```

## Using Config/Secrets.xcconfig
`.xcconfig` treats `//` as a comment, so `https://...` will be truncated. Use the SLASH trick:

```xcconfig
SLASH = /
VERCEL_REDIRECT_URI = https:$(SLASH)$(SLASH)deploymentbar.vercel.app/oauth/callback
```

## Redirect helper site
Vercel OAuth apps only accept HTTPS callback URLs. This repo includes a tiny redirect helper you can deploy.
See `docs/oauth-redirect.md` and the `oauth-redirect/` folder.

## URL scheme
The app uses the `vercelbar://oauth/callback` custom URL scheme to complete OAuth. The HTTPS helper forwards to it.

## Notes
- Current scope is personal account only (no team scopes).
- Targets/branches: all.
- Manual update check uses GitHub Releases API:
  - `https://api.github.com/repos/alirezamohammadpoor/deploymentbar/releases/latest`
