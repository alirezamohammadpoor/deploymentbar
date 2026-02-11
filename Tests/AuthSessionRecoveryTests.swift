import XCTest
@testable import VercelBar

@MainActor
final class AuthSessionRecoveryTests: XCTestCase {
  func testStateMismatchSetsStructuredErrorAndIsRecoverable() {
    let defaults = UserDefaults(suiteName: "AuthSessionRecoveryTests.\(UUID().uuidString)")!
    let stateStore = AuthSessionStateStore(defaults: defaults)
    stateStore.save(.init(state: "expected", verifier: "verifier", redirectURI: "vercelbar://oauth/callback"))

    let credentialStore = TestCredentialStore()
    let client = StubAuthClient()
    let session = AuthSession.makeForTesting(
      credentialStore: credentialStore,
      stateStore: stateStore,
      configLoader: { Self.testConfig() },
      urlOpener: { _ in },
      clientFactory: { _, _ in client }
    )

    session.handleCallback(url: URL(string: "vercelbar://oauth/callback?state=wrong&code=abc")!)

    guard case .error = session.status else {
      return XCTFail("Expected error status")
    }
    XCTAssertEqual(session.lastAuthErrorCode, .stateMismatchValueMismatch)
    XCTAssertNil(stateStore.load())

    session.resetPendingAuthorization()

    XCTAssertEqual(session.status, .signedOut)
    XCTAssertNil(session.lastAuthErrorCode)
    XCTAssertNil(session.pendingAuthStartedAt)
  }

  func testRetryAuthorizationStartsSignInAgain() {
    let stateStore = AuthSessionStateStore(defaults: UserDefaults(suiteName: "AuthSessionRecoveryTests.\(UUID().uuidString)")!)
    let credentialStore = TestCredentialStore()
    let client = StubAuthClient()
    var openedURLs: [URL] = []

    let session = AuthSession.makeForTesting(
      credentialStore: credentialStore,
      stateStore: stateStore,
      configLoader: { Self.testConfig() },
      urlOpener: { openedURLs.append($0) },
      clientFactory: { _, _ in client }
    )

    session.retryAuthorization()

    XCTAssertEqual(session.status, .signingIn)
    XCTAssertEqual(openedURLs.count, 1)
    XCTAssertNotNil(session.pendingAuthStartedAt)
    XCTAssertNil(session.lastAuthErrorCode)
    XCTAssertNotNil(stateStore.load())
  }

  private static func testConfig() -> VercelAuthConfig {
    VercelAuthConfig(
      clientId: "client",
      clientSecret: nil,
      redirectURI: "vercelbar://oauth/callback",
      scopes: ["offline_access"]
    )
  }
}

private final class TestCredentialStore: CredentialStoring {
  var tokens: TokenPair?
  var personalToken: String?

  func loadTokens() -> TokenPair? { tokens }
  func saveTokens(_ tokens: TokenPair) { self.tokens = tokens }
  func clearTokens() { tokens = nil }
  func loadPersonalToken() -> String? { personalToken }
  func savePersonalToken(_ token: String) { personalToken = token }
  func clearPersonalToken() { personalToken = nil }
}

private final class StubAuthClient: VercelAPIClient {
  var fetchTeamsCallCount = 0

  func authorizationURL(state: String, codeChallenge: String?) throws -> URL {
    URL(string: "https://example.com/oauth?state=\(state)")!
  }

  func exchangeCode(_ code: String, codeVerifier: String?, redirectURI: String) async throws -> TokenPair {
    TokenPair(accessToken: "token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(3600), teamId: nil)
  }

  func refreshToken(_ refreshToken: String) async throws -> TokenPair {
    throw APIError.invalidResponse
  }

  func revokeToken(_ token: String) async throws {}

  func fetchDeployments(limit: Int, projectIds: [String]?, teamId: String?) async throws -> [DeploymentDTO] { [] }
  func fetchDeploymentEvents(deploymentId: String, teamId: String?) async throws -> [LogLine] { [] }
  func fetchProjects(teamId: String?) async throws -> [ProjectDTO] { [] }

  func fetchTeams() async throws -> [TeamDTO] {
    fetchTeamsCallCount += 1
    return [TeamDTO(id: "team_123", name: "Team", slug: "team")]
  }

  func fetchCurrentUser() async throws -> String { "{}" }
  func createDeployment(name: String, target: String?, gitSource: GitDeploymentSource, teamId: String?) async throws -> DeploymentDTO {
    throw APIError.invalidResponse
  }
  func rollbackProject(projectId: String, deploymentId: String, teamId: String?) async throws {}
}
