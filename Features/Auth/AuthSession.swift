import AppKit
import Foundation

@MainActor
final class AuthSession: ObservableObject {
  typealias ClientFactory = (_ config: VercelAuthConfig, _ tokenProvider: @escaping () -> String?) -> VercelAPIClient

  enum Status: Equatable {
    case signedOut
    case signingIn
    case signedIn
    case error(String)
  }

  enum AuthErrorCode: Equatable {
    case missingOAuthConfig
    case authorizationURLBuildFailed
    case stateMismatchMissingCode
    case stateMismatchMissingState
    case stateMismatchValueMismatch
    case sessionNotInitialized
    case oauthTokenExchangeFailed
    case networkFailure
  }

  static let shared = AuthSession(
    credentialStore: CredentialStore(),
    stateStore: AuthSessionStateStore()
  )

  @Published private(set) var status: Status = .signedOut
  @Published private(set) var pendingAuthStartedAt: Date?
  @Published private(set) var lastAuthErrorCode: AuthErrorCode?

  private let credentialStore: CredentialStoring
  private let stateStore: AuthSessionStateStore
  private let configLoader: () -> VercelAuthConfig?
  private let urlOpener: (URL) -> Void
  private let clientFactory: ClientFactory
  private let nowProvider: () -> Date
  private var client: VercelAPIClient?
  private var pendingState: String?
  private var codeVerifier: String?
  private var redirectURI: String?
  private var didLoadInitialStatus = false

  private init(
    credentialStore: CredentialStoring,
    stateStore: AuthSessionStateStore,
    configLoader: @escaping () -> VercelAuthConfig? = { VercelAuthConfig.load() },
    urlOpener: @escaping (URL) -> Void = { NSWorkspace.shared.open($0) },
    clientFactory: @escaping ClientFactory = { config, tokenProvider in
      VercelAPIClientImpl(config: config, tokenProvider: tokenProvider)
    },
    nowProvider: @escaping () -> Date = Date.init
  ) {
    self.credentialStore = credentialStore
    self.stateStore = stateStore
    self.configLoader = configLoader
    self.urlOpener = urlOpener
    self.clientFactory = clientFactory
    self.nowProvider = nowProvider
    if let pending = stateStore.load() {
      pendingState = pending.state
      codeVerifier = pending.verifier
      redirectURI = pending.redirectURI
    }
  }

  static func makeForTesting(
    credentialStore: CredentialStoring,
    stateStore: AuthSessionStateStore,
    configLoader: @escaping () -> VercelAuthConfig? = { nil },
    urlOpener: @escaping (URL) -> Void = { _ in },
    clientFactory: @escaping ClientFactory = { config, tokenProvider in
      VercelAPIClientImpl(config: config, tokenProvider: tokenProvider)
    },
    nowProvider: @escaping () -> Date = Date.init
  ) -> AuthSession {
    AuthSession(
      credentialStore: credentialStore,
      stateStore: stateStore,
      configLoader: configLoader,
      urlOpener: urlOpener,
      clientFactory: clientFactory,
      nowProvider: nowProvider
    )
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

    guard let config = configLoader() else {
      setAuthError("Missing Vercel OAuth config in Info.plist", code: .missingOAuthConfig)
      return
    }

    let verifier = PKCE.generateCodeVerifier()
    let challenge = PKCE.codeChallenge(for: verifier)
    let state = UUID().uuidString

    pendingState = state
    codeVerifier = verifier
    redirectURI = config.redirectURI
    pendingAuthStartedAt = nowProvider()
    lastAuthErrorCode = nil
    stateStore.save(.init(state: state, verifier: verifier, redirectURI: config.redirectURI))
    client = clientFactory(config, { [weak self] in
      self?.credentialStore.loadTokens()?.accessToken
    })

    do {
      let url = try client?.authorizationURL(state: state, codeChallenge: challenge)
      if let url {
        status = .signingIn
        urlOpener(url)
      } else {
        clearPendingAuthorizationState()
        setAuthError("Failed to build authorization URL", code: .authorizationURLBuildFailed)
      }
    } catch {
      clearPendingAuthorizationState()
      setAuthError("Failed to build authorization URL", code: .authorizationURLBuildFailed)
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

    if client == nil, let config = configLoader() {
      client = clientFactory(config, { [weak self] in
        self?.credentialStore.loadTokens()?.accessToken
      })
    }

    guard let code, !code.isEmpty else {
      clearPendingAuthorizationState()
      setAuthError(Self.stateMismatchMessage(expected: pendingState, received: state, code: code), code: .stateMismatchMissingCode)
      return
    }

    guard let state, !state.isEmpty else {
      clearPendingAuthorizationState()
      setAuthError(Self.stateMismatchMessage(expected: pendingState, received: state, code: code), code: .stateMismatchMissingState)
      return
    }

    guard state == pendingState else {
      clearPendingAuthorizationState()
      setAuthError(Self.stateMismatchMessage(expected: pendingState, received: state, code: code), code: .stateMismatchValueMismatch)
      return
    }

    guard let client, let redirectURI else {
      clearPendingAuthorizationState()
      setAuthError("OAuth session not initialized", code: .sessionNotInitialized)
      return
    }

    status = .signingIn
    lastAuthErrorCode = nil
    Task {
      do {
        let tokens = try await client.exchangeCode(code, codeVerifier: codeVerifier, redirectURI: redirectURI)
        credentialStore.saveTokens(tokens)
        clearPendingAuthorizationState()
        lastAuthErrorCode = nil
        self.status = .signedIn
      } catch let error as APIError {
        clearPendingAuthorizationState()
        if case .networkFailure = error {
          setAuthError(error.userMessage, code: .networkFailure)
        } else {
          setAuthError(error.userMessage, code: .oauthTokenExchangeFailed)
        }
      } catch {
        clearPendingAuthorizationState()
        setAuthError("Token exchange failed", code: .oauthTokenExchangeFailed)
      }
    }
  }

  func resetPendingAuthorization(manual: Bool = true) {
    clearPendingAuthorizationState()
    client = nil
    lastAuthErrorCode = nil
    status = .signedOut
    if manual {
      DebugLog.write("AuthSession reset pending authorization")
    }
  }

  func retryAuthorization() {
    resetPendingAuthorization(manual: false)
    startSignIn()
  }

  func signOut(revokeToken: Bool = false) {
    let tokens = credentialStore.loadTokens()
    let revokeConfig = configLoader()
    credentialStore.clearTokens()
    credentialStore.clearPersonalToken()
    clearPendingAuthorizationState()
    client = nil
    lastAuthErrorCode = nil
    status = .signedOut

    guard revokeToken, let tokens, let refreshToken = tokens.refreshToken, !refreshToken.isEmpty else { return }
    Task.detached {
      guard let config = revokeConfig else { return }
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
    clearPendingAuthorizationState()
    lastAuthErrorCode = nil
    status = .signedIn
  }

  private func clearPendingAuthorizationState() {
    pendingState = nil
    codeVerifier = nil
    redirectURI = nil
    pendingAuthStartedAt = nil
    stateStore.clear()
  }

  private func setAuthError(_ message: String, code: AuthErrorCode) {
    lastAuthErrorCode = code
    status = .error(message)
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
