# VercelBar Spec

Last updated: 2026-02-02

## Scope decisions
- Account scope: personal only (no team scopes yet).
- Targets/branches: show all targets and branches.
- Minimum macOS version: 14.0 (Apple Silicon / M1+).

**Phase 0**
Confirmed API contracts

Vercel API
- Base URL: `https://api.vercel.com`.
- Auth header: `Authorization: Bearer <access_token>`.
- OAuth authorize: `https://vercel.com/oauth/authorize`.
- OAuth token exchange: `https://api.vercel.com/login/oauth/token`.
- OAuth revoke: `https://api.vercel.com/login/oauth/token/revoke`.
- OAuth introspect: `https://api.vercel.com/login/oauth/token/introspect`.
- OAuth user info: `https://api.vercel.com/login/oauth/userinfo`.
- Access token TTL: 1 hour. Refresh token TTL: 30 days. Refresh tokens rotate.
- Deployments list: `GET /v6/deployments`.
- Deployment detail: `GET /v13/deployments/{idOrUrl}`.
- Rate limit: check `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`; handle 429 errors.

macOS frameworks
- Menu bar: `NSStatusBar`, `NSStatusItem` in `Features/StatusBar/StatusBarController.swift`.
- Notifications: `UserNotifications` with `UNUserNotificationCenterDelegate` in `Core/Services/NotificationManager.swift`.
- URL opening: `NSWorkspace.open(_:)` in `Core/Services/BrowserLauncher.swift`.
- Default browser detection: `NSWorkspace.urlForApplication(toOpen:)` with `LSCopyDefaultHandlerForURLScheme` fallback in `Core/Services/BrowserLauncher.swift`.
- Keychain: Security framework `SecItemCopyMatching`, `SecItemAdd`, `SecItemUpdate`, `SecItemDelete` in `Core/Utilities/KeychainWrapper.swift`.
- Launch at login: `ServiceManagement` `SMAppService` in `Core/Services/LaunchAtLoginManager.swift`.
- Agent app (no Dock icon): `LSUIElement = true` in `App/Info.plist`.
- OAuth callback: `CFBundleURLTypes` in `App/Info.plist`, handled in `App/AppDelegate.swift` and `Features/Auth/OAuthCallbackHandler.swift`.

**Phase 1**
Product requirements and acceptance criteria

Core (MVP-blocking)
- Menu bar icon with deployment status indicator
- Acceptance: status icon changes within one poll tick based on most recent deployment state.
- Files: `Features/StatusBar/StatusBarController.swift`, `Core/Services/DeploymentStore.swift`.

- Dropdown showing 10 most recent deployments
- Acceptance: list shows 10 items, sorted by `createdAt` descending, updated on refresh.
- Files: `Features/StatusBar/StatusBarMenu.swift`, `Core/Services/DeploymentStore.swift`.

- Each row: project name, branch, status badge, relative timestamp
- Acceptance: row shows `name`, `gitSource.ref` (or `-`), state badge, relative time.
- Files: `Features/StatusBar/DeploymentRowView.swift`, `Core/Utilities/RelativeTimeFormatter.swift`.

- Click deployment opens preview URL
- Acceptance: row opens `https://<url>` in default browser; row disabled if `url == nil`.
- Files: `Core/Services/BrowserLauncher.swift`, `Features/StatusBar/DeploymentRowView.swift`.

- Notification on status change (ready or failed)
- Acceptance: transitions to ready or error trigger a single notification per deployment.
- Files: `Core/Services/NotificationManager.swift`, `Core/Services/DeploymentStore.swift`.

- Notification click opens preview URL
- Acceptance: notification tap opens URL immediately.
- Files: `Core/Services/NotificationManager.swift`, `Core/Services/BrowserLauncher.swift`.

- Vercel OAuth authentication flow
- Acceptance: user completes OAuth; tokens stored; deployments fetched.
- Files: `Features/Auth/OAuthFlowView.swift`, `Features/Auth/OAuthCallbackHandler.swift`, `Core/API/VercelAPIClient.swift`.

- Secure token storage in Keychain
- Acceptance: `accessToken`, `refreshToken`, `expiresAt` persist across launches; logout clears.
- Files: `Core/Services/CredentialStore.swift`, `Core/Utilities/KeychainWrapper.swift`.

- Polling every 30 seconds
- Acceptance: `RefreshEngine` triggers fetch every 30s while authenticated.
- Files: `Core/Services/RefreshEngine.swift`.

Important (V1)
- Project filtering
- Acceptance: only selected projects render and notify.
- Files: `Features/Settings/ProjectFilterView.swift`, `Core/Services/DeploymentStore.swift`.

- Browser selection
- Acceptance: user can choose default or a specific browser; opening respects choice.
- Files: `Features/Settings/SettingsView.swift`, `Core/Services/BrowserLauncher.swift`.

- Notification preferences
- Acceptance: toggles for ready and failed are honored.
- Files: `Features/Settings/NotificationSettingsView.swift`, `Core/Services/NotificationManager.swift`.

- Launch at login
- Acceptance: toggle registers/unregisters login item; state persists.
- Files: `Features/Settings/SettingsView.swift`, `Core/Services/LaunchAtLoginManager.swift`.

- Manual refresh action
- Acceptance: menu action triggers immediate refresh and clears backoff.
- Files: `Features/StatusBar/StatusBarMenu.swift`, `Core/Services/RefreshEngine.swift`.

- Visual stale-data indicator
- Acceptance: icon dims and menu shows last error when polling fails.
- Files: `Features/StatusBar/StatusBarController.swift`, `Core/Services/RefreshEngine.swift`.

Nice-to-have (V2+)
- Copy URL button
- Keyboard shortcut to open dropdown
- Multiple Vercel accounts
- Team deployments view
- Inline error log preview for failed deploys
- Menu bar icon badge with count of active builds

**Phase 2**
Architecture design

App architecture
- SwiftUI `@main` app with `NSApplicationDelegateAdaptor`.
- Agent app via `LSUIElement`.
- Status bar via `NSStatusItem` with SwiftUI popover.
- Settings window via separate `WindowGroup`.

Core modules
- `Core/API/VercelAPIClient.swift`: OAuth flow, API client, request/response types.
- `Core/Services/DeploymentStore.swift`: normalized model, diffing, filtering, sorting.
- `Core/Services/RefreshEngine.swift`: polling scheduler, cancellation, backoff.
- `Core/Services/NotificationManager.swift`: UserNotifications integration, deep link handling.
- `Core/Services/CredentialStore.swift`: Keychain wrapper for tokens.
- `Core/Services/BrowserLauncher.swift`: open URLs in configured browser.

Data model
- `Deployment`: `id`, `projectName`, `branch`, `state`, `url`, `createdAt`, `readyAt`.
- `DeploymentState`: enum `building`, `ready`, `error`, `canceled`.
- `RefreshStatus`: `lastRefresh`, `nextRefresh`, `isStale`, `error`.

Key flows
- Launch -> load credentials -> initial fetch -> render menu -> start polling.
- Poll tick -> fetch deployments -> diff -> notify on changes -> update UI.
- Notification tap -> open preview URL.
- OAuth flow -> callback -> exchange code -> store tokens -> fetch deployments.

Component diagram
```
App (VercelBarApp/AppDelegate)
- StatusBarController (NSStatusItem + Popover)
- SettingsView

StatusBarController -> DeploymentStore
DeploymentStore -> RefreshEngine
RefreshEngine -> VercelAPIClient
VercelAPIClient -> CredentialStore
DeploymentStore -> NotificationManager
StatusBarController -> BrowserLauncher
NotificationManager -> BrowserLauncher
```

**Phase 3**
Module specifications

VercelAPI module
- Protocol: `VercelAPIClient`.
- Methods: `authorizationURL()`, `exchangeCode()`, `refreshToken()`, `fetchDeployments()`.
- Error handling: 429 rate limit, token expiry, network failures.
- Response parsing: `Codable` structs matching Vercel API.

RefreshEngine module
- Interval default 30s.
- Pauses when no credentials.
- Backoff: 30s -> 60s -> 120s -> 300s cap.
- Resume normal cadence on success.
- Cancels on settings change or manual refresh.

DeploymentStore module
- `@Published var deployments: [Deployment]`.
- Diff by `id`; notify on ready/error state changes.
- Apply project filter; sort by `createdAt` desc.

NotificationManager module
- Requests permission on first auth.
- Creates notification with deployment info in `userInfo`.
- Handles tap via `UNUserNotificationCenterDelegate`.
- Content: `"[Project] deployed successfully"` or `"[Project] deployment failed"`.

CredentialStore module
- Keychain wrapper using Security framework.
- Stores `accessToken`, `refreshToken`, `expiresAt`.
- Clears on logout.
- Checks expiry before API calls.

Settings module
- UserDefaults keys: `pollingInterval`, `selectedProjects`, `browserChoice`, `launchAtLogin`, `notificationPrefs`.
- SwiftUI Settings scene or standalone window.

**Phase 4**
Folder structure

```
VercelBar/
├── App/
│   ├── VercelBarApp.swift
│   ├── AppDelegate.swift
│   └── Info.plist
├── Features/
│   ├── StatusBar/
│   │   ├── StatusBarController.swift
│   │   ├── StatusBarMenu.swift
│   │   └── DeploymentRowView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── ProjectFilterView.swift
│   │   └── NotificationSettingsView.swift
│   └── Auth/
│       ├── OAuthFlowView.swift
│       └── OAuthCallbackHandler.swift
├── Core/
│   ├── API/
│   │   ├── VercelAPIClient.swift
│   │   ├── VercelEndpoints.swift
│   │   └── Models/
│   │       ├── Deployment.swift
│   │       ├── Project.swift
│   │       └── APIError.swift
│   ├── Services/
│   │   ├── RefreshEngine.swift
│   │   ├── DeploymentStore.swift
│   │   ├── NotificationManager.swift
│   │   ├── CredentialStore.swift
│   │   ├── BrowserLauncher.swift
│   │   └── LaunchAtLoginManager.swift
│   └── Utilities/
│       ├── KeychainWrapper.swift
│       └── RelativeTimeFormatter.swift
├── Resources/
│   ├── Assets.xcassets
│   └── Localizable.strings
└── Tests/
    ├── VercelAPITests.swift
    ├── RefreshEngineTests.swift
    └── DeploymentStoreTests.swift
```

**Phase 5**
Build plan and definition of done

MVP (Days 1-3)

Day 1
- Scaffold Xcode project with `LSUIElement` config.
- Implement `NSStatusItem` with hardcoded icon.
- Create SwiftUI popover with mock deployment list.
- Implement `DeploymentRowView` with tap -> open URL.
- DoD: clicking row opens URL in default browser.

Day 2
- Implement Vercel OAuth flow and callback handling.
- Implement `CredentialStore` with Keychain.
- Implement `VercelAPIClient.fetchDeployments()`.
- Wire real data to popover.
- DoD: authenticate and see real deployments.

Day 3
- Implement `RefreshEngine` with 30s polling.
- Implement state change detection in `DeploymentStore`.
- Implement `NotificationManager`.
- Wire notification tap to open URL.
- Implement status icon updates.
- DoD: push a commit -> status change -> notification -> click opens preview.

V1 (Days 4-5)

Day 4
- Implement `SettingsView` and `Settings` scene.
- Add project filtering.
- Add browser selection.
- Add notification toggles.
- Implement launch at login toggle.

Day 5
- Add manual refresh button.
- Implement stale indicator.
- Add backoff to `RefreshEngine`.
- Add error state in menu.
- Polish loading and empty states.

V2 (Future)
- Copy URL button.
- Keyboard shortcut.
- Multiple accounts.
- Inline error logs.

**Phase 6**
Risk mitigation

| Risk | Mitigation |
| --- | --- |
| OAuth callback handling in menu bar app | Custom URL scheme + `AppDelegate` open URL handling. |
| Rate limiting | 30s polling = 2/min; backoff on 429; read rate limit headers. |
| Token expiry | Check expiry and refresh proactively using refresh tokens. |
| Notification permission denied | Graceful degradation with in-app indicators. |
| SwiftUI popover dismissal quirks | Keep menu accessible and consider fallback to `NSMenu`. |

Implementation snippets

OAuth callback handler (`App/AppDelegate.swift` and `Features/Auth/OAuthCallbackHandler.swift`)
```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
  func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else { return }
    OAuthCallbackHandler.shared.handle(url: url)
  }
}

final class OAuthCallbackHandler {
  static let shared = OAuthCallbackHandler()

  func handle(url: URL) {
    guard url.scheme == "vercelbar" else { return }
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
    let code = components.queryItems?.first { $0.name == "code" }?.value
    let state = components.queryItems?.first { $0.name == "state" }?.value
    AuthSession.shared.complete(code: code, state: state)
  }
}
```

Keychain wrapper (`Core/Utilities/KeychainWrapper.swift`)
```swift
enum KeychainWrapper {
  static func get(_ account: String) throws -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "VercelBar",
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw KeychainError(status) }
    return item as? Data
  }

  static func set(_ data: Data, account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "VercelBar",
      kSecAttrAccount as String: account
    ]
    let attributes: [String: Any] = [kSecValueData as String: data]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      let addQuery = query.merging(attributes) { $1 }
      let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
      guard addStatus == errSecSuccess else { throw KeychainError(addStatus) }
      return
    }
    guard status == errSecSuccess else { throw KeychainError(status) }
  }

  static func delete(_ account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "VercelBar",
      kSecAttrAccount as String: account
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status) }
  }
}
```

NSStatusItem + popover (`Features/StatusBar/StatusBarController.swift`)
```swift
final class StatusBarController: NSObject {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let popover = NSPopover()

  override init() {
    super.init()
    if let button = statusItem.button {
      button.image = NSImage(named: "StatusIdle")
      button.target = self
      button.action = #selector(togglePopover(_:))
    }
    popover.behavior = .transient
    popover.contentViewController = NSHostingController(rootView: StatusBarMenu())
  }

  @objc private func togglePopover(_ sender: Any?) {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      popover.performClose(sender)
    } else {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
  }
}
```
