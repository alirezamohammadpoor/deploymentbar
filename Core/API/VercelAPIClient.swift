import Foundation

protocol VercelAPIClient {
  func authorizationURL(state: String, codeChallenge: String?) -> URL
  func exchangeCode(_ code: String, codeVerifier: String?, redirectURI: String) async throws -> TokenPair
  func refreshToken(_ refreshToken: String) async throws -> TokenPair
  func revokeToken(_ token: String) async throws
  func fetchDeployments(limit: Int, projectIds: [String]?, teamId: String?) async throws -> [DeploymentDTO]
  func fetchDeploymentDetail(idOrUrl: String) async throws -> DeploymentDetailDTO
  func fetchDeploymentEvents(deploymentId: String, teamId: String?) async throws -> [LogLine]
  func fetchProjects(teamId: String?) async throws -> [ProjectDTO]
  func fetchTeams() async throws -> [TeamDTO]
  func fetchCurrentUser() async throws -> String
  func createDeployment(name: String, target: String?, gitSource: GitDeploymentSource, teamId: String?) async throws -> DeploymentDTO
  func rollbackProject(projectId: String, deploymentId: String, teamId: String?) async throws
}

struct TeamDTO: Codable {
  let id: String
  let name: String
  let slug: String
}

struct GitDeploymentSource: Codable {
  let type: String // "github", "gitlab", "bitbucket"
  let ref: String // branch name
  let repoId: String // repository ID
}

struct TokenPair: Codable, Equatable {
  let accessToken: String
  let refreshToken: String?
  let expiresAt: Date
  let teamId: String?
}

extension TokenPair {
  func withTeamId(_ teamId: String) -> TokenPair {
    TokenPair(accessToken: accessToken, refreshToken: refreshToken,
              expiresAt: expiresAt, teamId: teamId)
  }

  var canRefresh: Bool {
    guard let refreshToken else { return false }
    return !refreshToken.isEmpty
  }

  var isExpired: Bool {
    expiresAt <= Date()
  }

  var shouldRefreshSoon: Bool {
    guard canRefresh else { return false }
    return expiresAt <= Date().addingTimeInterval(60)
  }
}
