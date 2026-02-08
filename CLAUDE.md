# VercelBar

A native macOS menu bar application for monitoring Vercel deployments in real-time.

## Quick Start

```bash
# Build
xcodebuild -project VercelBar.xcodeproj -scheme VercelBar -configuration Debug build

# Run tests
xcodebuild -project VercelBar.xcodeproj -scheme VercelBarTests -configuration Debug test

# Fix codesign issues (extended attributes)
xattr -cr App Core Features Resources VercelBar.xcodeproj
```

## Project Structure

```
deploymentbar/
├── App/                      # Application entry point
│   ├── VercelBarApp.swift    # SwiftUI app with Settings scene
│   ├── AppDelegate.swift     # AppKit lifecycle, URL scheme handling
│   └── Info.plist            # Bundle config, OAuth settings, URL schemes
├── Core/
│   ├── API/                  # Vercel API integration
│   │   ├── VercelAPIClient.swift      # Protocol + implementation
│   │   ├── VercelEndpoints.swift      # API URL constants
│   │   ├── VercelAuthConfig.swift     # OAuth config from Info.plist
│   │   ├── PKCE.swift                 # Code verifier/challenge generation
│   │   ├── TokenResponseParser.swift  # OAuth token parsing
│   │   ├── OAuthErrorParser.swift     # Error message extraction
│   │   └── Models/
│   │       ├── Deployment.swift       # Deployment + DTO
│   │       ├── Project.swift          # Project + DTO
│   │       ├── TokenPair.swift        # OAuth tokens with refresh
│   │       └── TeamDTO.swift          # Team info
│   ├── Services/             # Business logic layer
│   │   ├── AuthSession.swift          # OAuth state machine
│   │   ├── CredentialStore.swift      # Token persistence
│   │   ├── RefreshEngine.swift        # Polling with backoff
│   │   ├── DeploymentStore.swift      # Deployment state
│   │   ├── ProjectStore.swift         # Project list
│   │   ├── SettingsStore.swift        # User preferences
│   │   ├── NotificationManager.swift  # Desktop notifications
│   │   ├── AppInstanceCoordinator.swift # Single-instance lock
│   │   ├── BrowserLauncher.swift      # URL opening
│   │   └── LaunchAtLoginManager.swift # SMAppService integration
│   └── Utilities/
│       ├── Theme.swift                # Design system (colors, typography)
│       ├── DebugLog.swift             # File logging
│       └── RelativeTimeFormatter.swift
├── Features/
│   ├── Auth/
│   │   ├── OAuthFlowView.swift        # Sign-in UI
│   │   └── OAuthCallbackHandler.swift # URL scheme receiver
│   ├── Settings/
│   │   ├── SettingsView.swift         # Preferences window
│   │   ├── PersonalTokenView.swift    # PAT authentication
│   │   ├── ProjectFilterView.swift    # Project selection
│   │   └── VercelComponents.swift     # Reusable UI components
│   └── StatusBar/
│       ├── StatusBarController.swift  # NSStatusItem management
│       ├── StatusBarMenu.swift        # Main popover UI
│       └── DeploymentRowView.swift    # Deployment list item
├── Resources/
│   ├── Assets.xcassets       # App icons, colors
│   └── AppIcon.icns          # Menu bar icon
├── Tests/                    # Unit tests (16 files)
├── Config/
│   └── Secrets.xcconfig      # OAuth credentials (gitignored)
└── project.yml               # XcodeGen specification
```

## Architecture

### Pattern: Layered MVVM + Services

```
┌─────────────────────────────────────────────────────────────┐
│                    UI Layer (Features/)                      │
│  StatusBarMenu, SettingsView, OAuthFlowView, DeploymentRow  │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Service Layer (Core/Services/)               │
│  AuthSession, RefreshEngine, NotificationManager, Stores    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    API Layer (Core/API/)                     │
│         VercelAPIClient, Models, Token Management           │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| Component | Responsibility |
|-----------|----------------|
| `AuthSession` | OAuth2 + PKCE state machine (signedOut → signingIn → signedIn) |
| `CredentialStore` | Persists tokens to `~/Library/Application Support/VercelBar/` |
| `RefreshEngine` | Polls deployments with adaptive intervals (5s builds, 30s+ idle) |
| `StatusBarController` | Manages NSStatusItem, popover, icon animation |
| `NotificationManager` | Desktop notifications with deduplication |
| `AppInstanceCoordinator` | Single-instance via POSIX file lock (`/tmp/vercelbar.lock`) |

### Data Flow

1. **Authentication**: User clicks Sign In → AuthSession generates PKCE challenge → Opens browser → OAuth callback via `vercelbar://` → Token exchange → Credentials stored
2. **Polling**: RefreshEngine starts → Checks token expiry → Fetches deployments → Detects state changes → Triggers notifications → Updates UI via Combine publishers
3. **Notifications**: Deployment state transition (building→ready/error) → Check settings & history → Post UNNotification → User clicks → Opens URL in browser

## API Integration

### Vercel OAuth2 + PKCE

```swift
// Authorization URL construction
let authURL = "https://vercel.com/integrations/oauthv2/authorize"
    + "?client_id=\(clientId)"
    + "&redirect_uri=vercelbar://callback"
    + "&response_type=code"
    + "&state=\(randomState)"
    + "&code_challenge=\(sha256(codeVerifier))"
    + "&code_challenge_method=S256"

// Token exchange
POST https://api.vercel.com/v2/oauth/access_token
```

### API Endpoints Used
- `GET /v6/deployments` - List deployments
- `GET /v9/projects` - List projects
- `GET /v2/teams` - List teams
- `GET /v2/user` - Current user info
- `POST /v2/oauth/access_token` - Token exchange/refresh
- `DELETE /v13/integrations/access-token` - Token revocation

### Error Handling
- **401 Unauthorized**: Auto sign-out, clear credentials
- **429 Rate Limited**: Respect `X-RateLimit-Reset` header
- **5xx Server Error**: Exponential backoff (max 5 min)
- **Network Failure**: Retry with backoff

## Configuration

### OAuth Setup (Config/Secrets.xcconfig)
```
VERCEL_CLIENT_ID = oac_xxxxx
VERCEL_CLIENT_SECRET = xxxxx
VERCEL_REDIRECT_URI = vercelbar://callback
VERCEL_SCOPES = read:deployments read:projects read:user
```

### Info.plist Keys
- `LSUIElement`: true (menu bar app, no dock icon)
- `CFBundleURLSchemes`: ["vercelbar"] (OAuth callback)
- `VercelClientId`, `VercelClientSecret`, `VercelRedirectURI`, `VercelScopes`

## Design System (Theme.swift)

### Colors
- **Background**: Adaptive light/dark (similar to Vercel dashboard)
- **Status indicators**: Green (ready), Yellow (building), Red (error), Gray (canceled)
- **Accent**: Vercel blue (#0070F3)

### Layout
- Popover: 320×400pt, 10pt corner radius
- Row height: 44pt
- Font: System default, 13pt body, 11pt secondary

## Testing

### Test Structure
- 16 test files, 29 implemented tests
- Protocol-based mocks: `FakeCredentialStore`, `FakeLockProvider`, `FakeMessenger`
- Test isolation: UUID-named UserDefaults suites, temp directories

### Running Tests
```bash
xcodebuild -project VercelBar.xcodeproj -scheme VercelBarTests test
```

### Coverage
- **Well tested**: OAuth parsing, auth state, token refresh, app instance coordination
- **Placeholders**: RefreshEngine, DeploymentStore, VercelAPI (marked with XCTSkip)

## Common Issues

### Build Fails with "resource fork, Finder information, or similar detritus not allowed"
```bash
xattr -cr App Core Features Resources VercelBar.xcodeproj
rm -rf ~/Library/Developer/Xcode/DerivedData/VercelBar-*
```

### OAuth Callback Not Received
1. Check URL scheme registered: `vercelbar://`
2. Verify `Info.plist` has `CFBundleURLTypes` configured
3. Check `VERCEL_REDIRECT_URI` matches registered callback

### Token Refresh Failing
- Tokens stored in `~/Library/Application Support/VercelBar/`
- Check `oauth-tokens.json` for valid refresh token
- Personal tokens don't support refresh

## Dependencies

**No external dependencies** - Uses only Apple frameworks:
- SwiftUI, AppKit, Combine
- CryptoKit (PKCE SHA256)
- UserNotifications
- ServiceManagement (launch at login)

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `VERCELBAR_MINIMAL` | Minimal status item mode |
| `VERCELBAR_STANDALONE` | Title-only display mode |
