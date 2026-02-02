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
  private var client: VercelAPIClientImpl?
  private var pendingState: String?
  private var codeVerifier: String?
  private var redirectURI: String?

  private init() {
    if credentialStore.loadTokens() != nil {
      status = .signedIn
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

    guard let code, let state, state == pendingState else {
      status = .error("OAuth state mismatch")
      return
    }

    guard let client, let redirectURI else {
      status = .error("OAuth session not initialized")
      return
    }

    status = .signingIn
    Task {
      do {
        let tokens = try await client.exchangeCode(code, codeVerifier: codeVerifier, redirectURI: redirectURI)
        credentialStore.saveTokens(tokens)
        self.status = .signedIn
      } catch {
        self.status = .error("Token exchange failed")
      }
    }
  }

  func signOut() {
    credentialStore.clearTokens()
    status = .signedOut
  }
}
