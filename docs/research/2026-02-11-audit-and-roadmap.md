# DeployBar Audit and Roadmap (2026-02-11)

## Scope
This document captures:
- Codebase audit of the current macOS app implementation
- Verified Vercel API/auth contracts from current docs
- Comparable app research
- Consolidated recommendations from three perspectives: Lead Developer, Lead Design, Lead Product Manager
- A concrete implementation plan for personal use now and scalable public release later

## Current State (Code Audit)

### What is working structurally
- Clear separation of concerns across app lifecycle, API, services, and feature UI.
- Menu bar app architecture is in place (`LSUIElement` + `NSStatusItem` + popover).
- OAuth + PAT dual-path auth implemented.
- Polling and notification pipelines exist and are wired.

### High-priority technical issues
1. **Credential storage does not match security goals/docs**
- Current implementation stores OAuth tokens and PAT in plain files under Application Support with restrictive file permissions.
- Code: `Core/Services/CredentialStore.swift`
- Risk: not aligned with expected macOS security posture for desktop auth clients; docs still reference Keychain.

2. **Test suite currently fails to build**
- `xcodebuild test` fails due API/model drift in tests.
- Repro command:
  - `xcodebuild test -project VercelBar.xcodeproj -scheme VercelBar -destination 'platform=macOS' -derivedDataPath .derivedData`
- Breaks include:
  - `AuthSession.stateMismatchMessage` now main-actor isolated and called from nonisolated tests.
  - `TokenPair`/`TokenResponseParser.Parsed` gained `teamId` argument; tests still use old initializers.

3. **Initialization flow is over-complex and fragile**
- `StatusBarController` does deferred two-phase configure with many singleton/global dependencies.
- `AppDelegate` includes multiple debug-mode branches and distributed-notification URL forwarding paths.
- Harder to reason about startup race conditions and invisible menubar regressions.

4. **Design system implementation diverges from your provided spec**
- `Core/Utilities/Geist.swift` is dark-only and token values/sizes differ from your DeployBar guideline.
- Building state color currently amber in code, while brand spec uses Vercel blue.

### Medium-priority issues
- Extensive debug logging in production paths (`DebugLog.write`) without log levels.
- `Task.detached` usage in actor-sensitive areas (auth/project refresh paths) increases correctness risk.
- Duplicated app/project artifacts in repo root are interfering with default CLI workflows.

## Verified External Contracts (Vercel + platform)

### Vercel auth endpoints (current)
From Sign in with Vercel docs:
- Authorization: `https://vercel.com/oauth/authorize`
- Token: `https://api.vercel.com/login/oauth/token`
- Revoke: `https://api.vercel.com/login/oauth/token/revoke`
- Introspect: `https://api.vercel.com/login/oauth/token/introspect`
- Userinfo: `https://api.vercel.com/login/oauth/userinfo`

### OAuth token contract
Token endpoint supports:
- `grant_type`: `authorization_code` or `refresh_token`
- `client_id`: required
- `client_secret`: optional when client auth method is `none`
- `code_verifier`: required for auth code flow with PKCE
- `redirect_uri`: must match auth request

Expected token response includes:
- `access_token`, `token_type`, `id_token`, `expires_in`, `scope`
- `refresh_token` when `offline_access` scope is granted

### Callback URL behavior
From Vercel Sign in with Vercel manage docs:
- Callback URLs must be explicitly registered.
- For local dev, `http://localhost...` is allowed.
- For production, `https://...` callback URLs should be used.
- For Vercel-hosted apps, selecting a Vercel project in dashboard can support deployment-domain callback handling.

### Deployments API contracts (current)
From REST API reference:
- List deployments: `GET /v6/deployments`
- Get deployment by id/url: `GET /v13/deployments/{idOrUrl}`
- Query supports `limit`, `projectId` / `projectIds`, `target`, `branch`, `sha`, `teamId`.
- Response fields include `uid`, `name`, `url`, `state`, `readyState`, `projectId`, `meta`, timestamps (`created`/`createdAt`, `ready`).

### Rate-limiting contract
From REST API docs + Limits docs:
- API rate limits are exposed by headers:
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`
- Exceeded requests return `429`.
- Current limits table includes:
  - **Deployments retrieval per minute: 500** (scope `user`)
  - **Deployments retrieval per minute (Enterprise): 2000**

Note: this is different from the earlier assumption of 100 requests/60s for deployment polling.

## Auth Strategy Decision (PAT vs OAuth)

## Decision for your stated context
- **Now (personal use):** Support both, default to PAT for setup speed, keep OAuth available.
- **Public release / paid path:** Make OAuth the primary path and retain PAT as an advanced fallback.

## Why
- PAT is friction-heavy for general users (manual token creation and paste), but very reliable for power users.
- OAuth gives better onboarding and safer credential lifecycle for distributed users.
- Current Vercel Sign in with Vercel stack supports PKCE + refresh tokens and public-client mode (`none`), which fits desktop apps.

## Security posture required before public launch
- Move token storage to macOS Keychain.
- Separate secrets by auth mode and account/team scope.
- Add token revocation and forced re-consent handling paths.

## Comparable Apps (External)

1. **RepoBar** (macOS menubar for GitHub notifications)
- Notable: native menu bar UX, keyboard shortcuts, account/workspace support.
- Source: https://github.com/menubar-apps/RepoBar

2. **CI Demon** (Mac App Store)
- Notable: CI status monitoring and keychain-oriented auth language.
- Source: https://apps.apple.com/us/app/ci-demon/id1530607725

3. **Deploy Bar for Vercel** (open-source proof point)
- Notable: deployment list + notifications from menu bar.
- Source: https://github.com/andrewk17/deploy-bar-macos

## Role-Based Recommendations

## Lead Developer
1. Replace `CredentialStore` file persistence with Keychain-backed storage.
2. Introduce dependency injection at app composition root and remove singleton coupling from feature modules.
3. Collapse startup into deterministic phases:
   - bootstrap
   - auth restoration
   - status item render
   - data refresh start
4. Add contract tests for:
   - token exchange parsing
   - refresh rotation
   - list deployment decode (real fixture payloads)
5. Fix and stabilize test suite before adding new features.

## Lead Design
1. Implement centralized semantic token layer exactly matching your DeployBar spec (light/dark adaptive).
2. Align typography scale to your table (11/12/13pt baselines for metadata/body/title).
3. Normalize row density and spacing to 4px grid.
4. Use status mapping exactly as defined (building = blue pulse).
5. Add reduced-motion and accessibility checks for all dynamic elements.

## Lead Product Manager
1. Ship a **Personal Reliability Release** first:
   - stable auth
   - stable menubar rendering
   - reliable polling/notifications
2. Define v1 paid wedge around team workflows:
   - team/project filters
   - richer failure context
   - quality-of-life shortcuts
3. Instrument core funnel metrics:
   - auth success rate
   - first deployment visible latency
   - notification click-through
   - stale-data incidence
4. Keep scope discipline: solve monitoring deeply before adding deployment mutation features.

## Build Plan (Practical)

### Phase A (stabilize, 3-5 days)
- Fix test suite compile failures.
- Migrate credentials to Keychain.
- Remove startup/debug branches not needed for production path.
- Add startup diagnostics behind debug-only logging.

### Phase B (design hardening, 2-3 days)
- Implement your DesignTokens layer and update row/header/settings components.
- Verify dark/light parity and reduced-motion behavior.

### Phase C (public-ready foundation, 3-4 days)
- Auth UX polish (better callback/error recovery + explicit state reset flow).
- Add metrics hooks and in-app diagnostics panel.
- Add regression tests for OAuth callback edge cases and refresh loop.

## New Bug Log Entry
- `docs/bugs/20260211-test-suite-model-drift.md`

## Sources
- Vercel Limits: https://vercel.com/docs/limits.md
- Vercel Sign in with Vercel (overview): https://vercel.com/docs/sign-in-with-vercel
- Authorization Server API: https://vercel.com/docs/sign-in-with-vercel/authorization-server-api
- Manage from dashboard (client auth methods + callback URL): https://vercel.com/docs/sign-in-with-vercel/manage-from-dashboard
- REST API welcome + rate-limit headers: https://vercel.mintlify-docs-rest-api-reference.com/docs/rest-api/reference/welcome.md
- REST API list deployments: https://vercel.mintlify-docs-rest-api-reference.com/docs/rest-api/reference/endpoints/deployments/list-deployments.md
- REST API get deployment: https://vercel.mintlify-docs-rest-api-reference.com/docs/rest-api/reference/endpoints/deployments/get-a-deployment-by-id-or-url.md
- RepoBar: https://github.com/menubar-apps/RepoBar
- CI Demon: https://apps.apple.com/us/app/ci-demon/id1530607725
- Deploy Bar for Vercel: https://github.com/andrewk17/deploy-bar-macos
