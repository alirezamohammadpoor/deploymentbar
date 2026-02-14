import XCTest
@testable import VercelBar

@MainActor
final class AuthSessionInitialStatusTests: XCTestCase {
  func testLoadsSignedInWhenTokensExist() {
    let store = FakeCredentialStore(tokens: TokenPair(accessToken: "a", refreshToken: nil, expiresAt: Date(), teamId: nil))
    let session = AuthSession.makeForTesting(
      credentialStore: store,
      stateStore: AuthSessionStateStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    )

    session.loadInitialStatusIfNeeded()
    waitForStatus(session, expected: .signedIn)

    XCTAssertEqual(session.status, .signedIn)
  }

  func testLoadsSignedOutWhenNoTokens() {
    let store = FakeCredentialStore(tokens: nil)
    let session = AuthSession.makeForTesting(
      credentialStore: store,
      stateStore: AuthSessionStateStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    )

    session.loadInitialStatusIfNeeded()
    waitForStatus(session, expected: .signedOut)

    XCTAssertEqual(session.status, .signedOut)
  }

  private func waitForStatus(
    _ session: AuthSession,
    expected: AuthSession.Status,
    timeout: TimeInterval = 1.0
  ) {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if session.status == expected {
        return
      }
      RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.01))
    }

    XCTFail("Timed out waiting for status \(expected)")
  }
}

private final class FakeCredentialStore: CredentialStoring {
  private let tokens: TokenPair?

  init(tokens: TokenPair?) {
    self.tokens = tokens
  }

  func loadTokens() -> TokenPair? { tokens }
  func saveTokens(_ tokens: TokenPair) {}
  func clearTokens() {}
  func loadPersonalToken() -> String? { nil }
  func savePersonalToken(_ token: String) {}
  func clearPersonalToken() {}
  func loadGitHubToken() -> String? { nil }
  func saveGitHubToken(_ token: String) {}
  func clearGitHubToken() {}
}
