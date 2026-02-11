# 2026-02-11 — OAuth token flow auto-bound first team in personal mode

## Summary
After OAuth token exchange, the app auto-fetched teams and assigned the first team ID to stored tokens. This could move a personal-only user into team-scoped fetches unexpectedly.

## Reproduction
1. Sign in with OAuth on an account that has team membership.
2. Complete token exchange.
3. Prior behavior: token is mutated with first team ID from `fetchTeams()`.
4. Deployment/project requests include `teamId` even in personal-only usage.

## TDD
Added failing test first:
- `Tests/AuthSessionPersonalScopeTests.swift`
  - `testTokenExchangeDoesNotAutoAssignTeamForPersonalMode`

## Root Cause
`AuthSession.handleCallback(url:)` performed non-essential team discovery and rewrote token scope after exchange.

## Fix
- Removed automatic `fetchTeams()` enrichment in OAuth callback handling.
- Persist token response as-is (team ID may stay `nil`).

## Verification
`xcodebuild test -project VercelBar.xcodeproj -scheme VercelBar -destination 'platform=macOS'`
- Personal-scope test confirms no `fetchTeams()` call and no team ID mutation.
