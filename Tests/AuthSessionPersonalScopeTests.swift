import XCTest
@testable import VercelBar

@MainActor
final class AuthSessionPersonalScopeTests: XCTestCase {
  func testTokenExchangeDoesNotAutoAssignTeamForPersonalMode() async {
    let defaults = UserDefaults(suiteName: "AuthSessionPersonalScopeTests.\(UUID().uuidString)")!
    let stateStore = AuthSessionStateStore(defaults: defaults)
    stateStore.save(.init(state: "state123", verifier: "verifier123", redirectURI: "vercelbar://oauth/callback"))

    let credentialStore = RecordingCredentialStore()
    let client = StubAuthClient()
    let session = AuthSession.makeForTesting(
      credentialStore: credentialStore,
      stateStore: stateStore,
      configLoader: { Self.testConfig() },
      urlOpener: { _ in },
      clientFactory: { _, _ in client }
    )

    session.handleCallback(
      url: URL(string: "vercelbar://oauth/callback?state=state123&code=code123")!
    )

    await waitForSignedInStatus(session)

    XCTAssertEqual(client.fetchTeamsCallCount, 0)
    XCTAssertEqual(credentialStore.savedTokens?.teamId, nil)
    XCTAssertEqual(session.status, .signedIn)
  }

  private func waitForSignedInStatus(_ session: AuthSession, timeout: TimeInterval = 1.0) async {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
      if session.status == .signedIn {
        return
      }
      try? await Task.sleep(nanoseconds: 10_000_000)
    }
    XCTFail("Timed out waiting for signed-in status")
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

private final class RecordingCredentialStore: CredentialStoring {
  var savedTokens: TokenPair?

  func loadTokens() -> TokenPair? { nil }
  func saveTokens(_ tokens: TokenPair) { savedTokens = tokens }
  func clearTokens() {}
  func loadPersonalToken() -> String? { nil }
  func savePersonalToken(_ token: String) {}
  func clearPersonalToken() {}
}

private final class StubAuthClient: VercelAPIClient {
  var fetchTeamsCallCount = 0

  func authorizationURL(state: String, codeChallenge: String?) throws -> URL {
    URL(string: "https://example.com/oauth?state=\(state)")!
  }

  func exchangeCode(_ code: String, codeVerifier: String?, redirectURI: String) async throws -> TokenPair {
    TokenPair(accessToken: "token", refreshToken: "refresh", expiresAt: Date().addingTimeInterval(3600), teamId: nil)
  }

  func refreshToken(_ refreshToken: String) async throws -> TokenPair { throw APIError.invalidResponse }
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
