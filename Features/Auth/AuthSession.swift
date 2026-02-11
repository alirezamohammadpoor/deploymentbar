import AppKit
import Foundation

@MainActor
final class AuthSession: ObservableObject {
  static let shared = AuthSession(
    credentialStore: CredentialStore(),
    stateStore: AuthSessionStateStore()
  )

  enum Status: Equatable {
    case signedOut
    case signingIn
    case signedIn
    case error(String)
  }

  @Published private(set) var status: Status = .signedOut

  private let credentialStore: CredentialStoring
  private let stateStore: AuthSessionStateStore
  private var client: VercelAPIClientImpl?
  private var pendingState: String?
  private var codeVerifier: String?
  private var redirectURI: String?
  private var didLoadInitialStatus = false

  private init(credentialStore: CredentialStoring, stateStore: AuthSessionStateStore) {
    self.credentialStore = credentialStore
    self.stateStore = stateStore
    if let pending = stateStore.load() {
      pendingState = pending.state
      codeVerifier = pending.verifier
      redirectURI = pending.redirectURI
    }
  }

  static func makeForTesting(
    credentialStore: CredentialStoring,
    stateStore: AuthSessionStateStore
  ) -> AuthSession {
    AuthSession(credentialStore: credentialStore, stateStore: stateStore)
  }

  func loadInitialStatusIfNeeded() {
    guard !didLoadInitialStatus else { return }
    didLoadInitialStatus = true

    let hasOAuth = credentialStore.loadTokens() != nil
    let hasPAT = credentialStore.loadPersonalToken() != nil
    DebugLog.write("loadInitialStatus: hasOAuth=\(hasOAuth), hasPAT=\(hasPAT)")
    if hasOAuth || hasPAT {
      status = .signedIn
    } else {
      status = .signedOut
    }
    DebugLog.write("loadInitialStatus: status set to \(status)")
  }

  func startSignIn() {
    if case .signingIn = status {
      return
    }

    guard let config = VercelAuthConfig.load() else {
      status = .error("Missing Vercel OAuth config in Info.plist")
      return
    }

    let verifier = PKCE.generateCodeVerifier()
    let challenge = PKCE.codeChallenge(for: verifier)
    let state = UUID().uuidString

    pendingState = state
    codeVerifier = verifier
    redirectURI = config.redirectURI
    stateStore.save(.init(state: state, verifier: verifier, redirectURI: config.redirectURI))
    client = VercelAPIClientImpl(config: config, tokenProvider: { [weak self] in
      self?.credentialStore.loadTokens()?.accessToken
    })

    do {
      let url = try client?.authorizationURL(state: state, codeChallenge: challenge)
      if let url {
        status = .signingIn
        NSWorkspace.shared.open(url)
      } else {
        status = .error("Failed to build authorization URL")
      }
    } catch {
      status = .error("Failed to build authorization URL")
    }
  }

  func handleCallback(url: URL) {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
    let code = components.queryItems?.first { $0.name == "code" }?.value
    let state = components.queryItems?.first { $0.name == "state" }?.value

    if pendingState == nil, let pending = stateStore.load() {
      pendingState = pending.state
      codeVerifier = pending.verifier
      redirectURI = pending.redirectURI
    }

    if client == nil, let config = VercelAuthConfig.load() {
      client = VercelAPIClientImpl(config: config, tokenProvider: { [weak self] in
        self?.credentialStore.loadTokens()?.accessToken
      })
    }

    guard let code, let state, state == pendingState else {
      stateStore.clear()
      status = .error(Self.stateMismatchMessage(expected: pendingState, received: state, code: code))
      return
    }

    guard let client, let redirectURI else {
      stateStore.clear()
      status = .error("OAuth session not initialized")
      return
    }

    status = .signingIn
    Task {
      do {
        var tokens = try await client.exchangeCode(code, codeVerifier: codeVerifier, redirectURI: redirectURI)

        // Discover team if token response didn't include team_id
        if tokens.teamId == nil {
          credentialStore.saveTokens(tokens)
          do {
            let teams = try await client.fetchTeams()
            if let team = teams.first {
              DebugLog.write("OAuth: using team '\(team.name)' (id=\(team.id))")
              tokens = tokens.withTeamId(team.id)
            }
          } catch {
            DebugLog.write("OAuth: team discovery failed (non-fatal): \(error)")
          }
        }

        credentialStore.saveTokens(tokens)
        stateStore.clear()
        self.status = .signedIn
      } catch let error as APIError {
        stateStore.clear()
        self.status = .error(error.userMessage)
      } catch {
        stateStore.clear()
        self.status = .error("Token exchange failed")
      }
    }
  }

  func signOut(revokeToken: Bool = false) {
    let tokens = credentialStore.loadTokens()
    credentialStore.clearTokens()
    credentialStore.clearPersonalToken()
    stateStore.clear()
    status = .signedOut

    guard revokeToken, let tokens, let refreshToken = tokens.refreshToken, !refreshToken.isEmpty else { return }
    Task.detached {
      guard let config = VercelAuthConfig.load() else { return }
      let client = VercelAPIClientImpl(config: config, tokenProvider: { tokens.accessToken })
      do {
        try await client.revokeToken(refreshToken)
      } catch {
        return
      }
    }
  }


  static func stateMismatchMessage(expected: String?, received: String?, code: String?) -> String {
    guard let code, !code.isEmpty else {
      return "OAuth state mismatch (missing code)"
    }
    guard let received, !received.isEmpty else {
      return "OAuth state mismatch (missing state)"
    }
    let expectedValue = expected ?? "nil"
    return "OAuth state mismatch (expected \(expectedValue), got \(received))"
  }

  func usePersonalToken(_ token: String) {
    let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    credentialStore.savePersonalToken(trimmed)
    status = .signedIn
  }
}

private extension DateFormatter {
  static var shortTime: DateFormatter {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
  }
}
