# OAuth Redirect Helper

This folder (`oauth-redirect/`) is a tiny static site you can deploy to Vercel.
It receives the OAuth `code` and `state` and forwards them to the native app via the custom scheme.

## Deploy
1. Create a new Vercel project using the `oauth-redirect/` folder, or set the project Root Directory to `oauth-redirect`.
2. Deploy it.
3. Copy the deployed URL (e.g. `https://vercelbar-oauth-redirect.vercel.app/oauth/callback`).

## Configure Vercel OAuth app
In the Vercel OAuth app settings, add the deployed HTTPS URL to **Authorization Callback URLs**.

## Configure the app
Set:
```
VERCEL_REDIRECT_URI=https://<your-project>.vercel.app/oauth/callback
```

The redirect page will then forward to:
```
vercelbar://oauth/callback?code=...&state=...
```

## Troubleshooting
- If Vercel complains about `routes` with `rewrites/redirects`, ensure `oauth-redirect/vercel.json` only uses `rewrites`.
