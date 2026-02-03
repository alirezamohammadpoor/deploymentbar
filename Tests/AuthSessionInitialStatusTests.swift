import XCTest
@testable import VercelBar

final class AuthSessionInitialStatusTests: XCTestCase {
  func testLoadsSignedInWhenTokensExist() {
    let store = FakeCredentialStore(tokens: TokenPair(accessToken: "a", refreshToken: nil, expiresAt: Date()))
    let session = AuthSession.makeForTesting(
      credentialStore: store,
      stateStore: AuthSessionStateStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    )

    session.loadInitialStatusIfNeeded()

    XCTAssertEqual(session.status, .signedIn)
  }

  func testLoadsSignedOutWhenNoTokens() {
    let store = FakeCredentialStore(tokens: nil)
    let session = AuthSession.makeForTesting(
      credentialStore: store,
      stateStore: AuthSessionStateStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    )

    session.loadInitialStatusIfNeeded()

    XCTAssertEqual(session.status, .signedOut)
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
}
