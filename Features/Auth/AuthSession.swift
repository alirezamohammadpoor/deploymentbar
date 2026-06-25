import Foundation

@MainActor
final class AuthSession: ObservableObject {
  enum Status: Equatable {
    case signedOut
    case signingIn // validating the first token (no existing session yet)
    case signedIn
  }

  static let shared = AuthSession(credentialStore: CredentialStore.shared)

  @Published private(set) var status: Status = .signedOut
  @Published private(set) var connectedAs: String?
  @Published private(set) var isConnecting = false
  @Published private(set) var connectError: String?

  private let credentialStore: CredentialStoring
  private let clientFactory: (_ token: String) -> VercelAPIClient
  private var didLoadInitialStatus = false

  private init(
    credentialStore: CredentialStoring,
    clientFactory: @escaping (_ token: String) -> VercelAPIClient = { token in
      VercelAPIClientImpl(tokenProvider: { token })
    }
  ) {
    self.credentialStore = credentialStore
    self.clientFactory = clientFactory
  }

  static func makeForTesting(
    credentialStore: CredentialStoring,
    clientFactory: @escaping (_ token: String) -> VercelAPIClient = { token in
      VercelAPIClientImpl(tokenProvider: { token })
    }
  ) -> AuthSession {
    AuthSession(credentialStore: credentialStore, clientFactory: clientFactory)
  }

  func loadInitialStatusIfNeeded() {
    guard !didLoadInitialStatus else { return }
    didLoadInitialStatus = true

    let hasPAT = credentialStore.loadPersonalToken() != nil
    DebugLog.write("loadInitialStatus: hasPAT=\(hasPAT)")
    status = hasPAT ? .signedIn : .signedOut
  }

  /// Validates a personal access token against the Vercel API, then persists it.
  /// On success, status becomes `.signedIn` and `connectedAs` holds the account
  /// name. On failure, `connectError` carries a message and an existing signed-in
  /// session is left intact — the previously-stored token still works.
  func connect(token: String) {
    let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    let wasSignedIn = (status == .signedIn)
    connectError = nil
    isConnecting = true
    if !wasSignedIn { status = .signingIn }

    let client = clientFactory(trimmed)
    Task {
      do {
        let user = try await client.fetchCurrentUser()
        credentialStore.savePersonalToken(trimmed)
        connectedAs = user
        connectError = nil
        status = .signedIn
        isConnecting = false
        DebugLog.write("AuthSession.connect: validated as \(user)")
      } catch {
        connectError = Self.message(for: error)
        isConnecting = false
        if !wasSignedIn { status = .signedOut }
        DebugLog.write("AuthSession.connect: failed (\(connectError ?? ""))")
      }
    }
  }

  func signOut() {
    credentialStore.clearPersonalToken()
    connectedAs = nil
    connectError = nil
    isConnecting = false
    status = .signedOut
    DebugLog.write("AuthSession.signOut")
  }

  private static func message(for error: Error) -> String {
    guard let apiError = error as? APIError else {
      return "Couldn't verify that token. Try again."
    }
    switch apiError {
    case .unauthorized, .forbidden:
      return "That token didn't work — check it's complete and not expired."
    case .networkFailure:
      return "Couldn't reach Vercel — check your connection and try again."
    default:
      return "Couldn't verify that token. Try again."
    }
  }
}
