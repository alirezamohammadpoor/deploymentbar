import AppKit
import Foundation

@MainActor
final class AuthSession: ObservableObject {
  static let shared = AuthSession()

  enum Status: Equatable {
    case signedOut
    case signingIn
    case signedIn
    case error(String)
  }

  @Published private(set) var status: Status = .signedOut

  private let credentialStore = CredentialStore()
  private let stateStore = AuthSessionStateStore()
  private var client: VercelAPIClientImpl?
  private var pendingState: String?
  private var codeVerifier: String?
  private var redirectURI: String?

  private init() {
    if credentialStore.loadTokens() != nil {
      status = .signedIn
    }

    if let pending = stateStore.load() {
      pendingState = pending.state
      codeVerifier = pending.verifier
      redirectURI = pending.redirectURI
    }
  }

  func startSignIn() {
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

    let url = client?.authorizationURL(state: state, codeChallenge: challenge)
    if let url {
      status = .signingIn
      NSWorkspace.shared.open(url)
    } else {
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

    guard let code, let state, state == pendingState else {
      stateStore.clear()
      status = .error("OAuth state mismatch")
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
        let tokens = try await client.exchangeCode(code, codeVerifier: codeVerifier, redirectURI: redirectURI)
        credentialStore.saveTokens(tokens)
        stateStore.clear()
        self.status = .signedIn
      } catch let error as APIError {
        stateStore.clear()
        self.status = .error(errorMessage(for: error))
      } catch {
        stateStore.clear()
        self.status = .error("Token exchange failed")
      }
    }
  }

  func signOut(revokeToken: Bool = false) {
    let tokens = credentialStore.loadTokens()
    credentialStore.clearTokens()
    stateStore.clear()
    status = .signedOut

    guard revokeToken, let tokens else { return }
    Task.detached {
      guard let config = VercelAuthConfig.load() else { return }
      let client = VercelAPIClientImpl(config: config, tokenProvider: { tokens.accessToken })
      do {
        try await client.revokeToken(tokens.refreshToken)
      } catch {
        return
      }
    }
  }

  private func errorMessage(for error: APIError) -> String {
    switch error {
    case .oauthError(let message):
      return message
    case .unauthorized:
      return "Unauthorized"
    case .rateLimited(let resetAt):
      if let resetAt {
        return "Rate limited until \(DateFormatter.shortTime.string(from: resetAt))"
      }
      return "Rate limited"
    case .serverError:
      return "Server error"
    case .decodingFailed:
      return "Decode error"
    case .networkFailure:
      return "Network error"
    case .invalidResponse:
      return "Invalid response"
    }
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
