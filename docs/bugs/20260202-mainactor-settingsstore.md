# Bug Fix Log: Main actor violations in settings + notifications

Date: 2026-02-02

## Summary
Build failed due to main actor isolation violations when accessing `SettingsStore` from non-main contexts and calling `AuthSession.handleCallback` from a nonisolated callback. Fixed by moving access onto the main actor and using `Task { @MainActor in ... }` where needed.

## Repro
1. Run build:
   `xcodebuild -scheme VercelBar -configuration Debug -derivedDataPath .derivedData build`
2. Compiler errors:
   - `BrowserLauncher` referencing `SettingsStore.browserBundleId` from nonisolated context.
   - `NotificationManager` referencing `SettingsStore.notifyOnReady/Failed` from nonisolated context.
   - `OAuthCallbackHandler` calling `AuthSession.handleCallback` from nonisolated context.
   - `SettingsView` using `.pickerStyle(.popUpButton)` not available on macOS SwiftUI.

## Test (TDD)
- Existing `StatusBarControllerTests` kept for main-actor initialization safety.
- Manual build verification used for this fix due to UI-driven flows.

## Fix
- Marked `BrowserLauncher` as `@MainActor`.
- Wrapped notification/open URL actions in `Task { @MainActor in ... }`.
- Annotated `NotificationManager.shouldNotify` as `@MainActor` and called it inside a main-actor task.
- Wrapped OAuth callback forwarding in `Task { @MainActor in ... }`.
- Switched picker style to `PopUpButtonPickerStyle()`.

## Verification
- `xcodebuild ... build` succeeded.
- `xcodebuild ... test` failed due to sandboxed test runner (environment restriction).
