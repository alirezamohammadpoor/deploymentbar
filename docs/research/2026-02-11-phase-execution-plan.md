# DeployBar Phase Execution Plan (2026-02-11)

## Phase A — Stabilize Core (in progress)

### A1. Build/test baseline + startup reliability
- Status: done
- Implemented:
  - fixed test drift for actor isolation and `teamId` model changes
  - added regression coverage for runtime icon mutation
  - removed runtime `NSWorkspace.setIcon` mutation path

### A2. Keychain migration + compatibility
- Status: done
- Implemented:
  - Keychain-backed credential persistence via `KeychainWrapper`
  - migration from legacy file storage on read
  - cleanup of legacy files after successful migration/save
  - fallback path for corrupted keychain payloads
  - unit tests in `Tests/CredentialStoreTests.swift`

### A3. Concurrency-warning cleanup (Swift 6 readiness)
- Status: next
- Scope:
  - remove remaining main-actor warning sites
  - eliminate non-sendable captures in detached/background closures

## Phase B — Design System Alignment
- Status: in progress
- Scope:
  - align token palette and semantics to DeployBar brand guide
  - update typography scale (11/12/13 baseline)
  - standardize spacing/radius/status-dot specs
  - verify reduced-motion behavior

### Phase B progress
- Status: in progress
- Implemented:
  - moved building state token to Vercel blue (`#0070F3`) for both row dots and status bar icon tint
  - migrated core typography tokens to native SF Pro/SF Mono sizing
  - aligned status-dot and badge metrics to spec (`8px` dot, capsule badge with `4x2` padding)
  - removed forced dark-mode overrides so views follow system appearance
  - replaced top filter picker with custom Geist-style segmented control and tuned row separators/padding to the 12px inset + 4px grid
  - introduced settings cards + section descriptions and added a persistent footer status row in the menu popover (`Updated`, `Refresh`, `Sign Out`)
  - refined footer visuals into semantic status chip + action buttons, added deployment target badges, and aligned skeleton spacing/expand animation with accessibility preferences

## Phase C — Auth + Release Hardening
- Status: pending
- Scope:
  - callback diagnostics and recovery UX
  - auth metrics hooks
  - regression suite for callback/refresh edge cases
  - release checklist and manual QA pass

## Verification Baseline
- Command:
```bash
xcodebuild test -project VercelBar.xcodeproj -scheme VercelBar -destination 'platform=macOS'
```
- Current result: passing
