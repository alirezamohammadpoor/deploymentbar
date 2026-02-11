# Design Agent Pass — 2026-02-11

## Objective
Ship a low-risk visual polish pass that improves scanability and interaction clarity in the menu bar UI without changing deployment/auth behavior.

## Implemented
- Converted the popover footer into a semantic status chip (`fresh`, `stale`, `waiting`) plus consistent action buttons.
- Added target badges to deployment rows so `production` vs `preview` context is visible without opening details.
- Updated deployment relative-time rendering to refresh on the shared 30s clock tick.
- Aligned skeleton row padding to row layout tokens.
- Applied reduce-motion handling for row expand/collapse animation paths.

## Files
- `Features/StatusBar/StatusBarMenu.swift`
- `Features/StatusBar/DeploymentRowView.swift`
- `Features/StatusBar/SkeletonRowView.swift`
- `Features/Settings/DesignPreviewView.swift`

## Follow-up candidates
- Add hover states to deployment action buttons (`ActionButton`) for parity with footer controls.
- Add keyboard focus styling for footer actions.
- Add UI snapshot coverage for status chip and target badge variants.
