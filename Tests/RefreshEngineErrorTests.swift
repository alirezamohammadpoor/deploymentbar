import XCTest
@testable import VercelBar

final class RefreshEngineErrorTests: XCTestCase {
  func testErrorMessageForOAuthError() {
    let engine = RefreshEngine(
      store: DeploymentStore(),
      credentialStore: CredentialStore(),
      apiClient: VercelAPIClientImpl(config: VercelAuthConfig(clientId: "", clientSecret: nil, redirectURI: "", scopes: []), tokenProvider: { nil }),
      authSession: AuthSession.shared,
      statusStore: RefreshStatusStore(),
      settingsStore: SettingsStore.shared,
      interval: 30
    )

    let message = engine.testErrorMessage(for: .oauthError("invalid_client"))
    XCTAssertEqual(message, "invalid_client")
  }
}
