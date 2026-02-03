import Foundation

protocol VercelAPIClient {
  func authorizationURL(state: String, codeChallenge: String?) -> URL
  func exchangeCode(_ code: String, codeVerifier: String?, redirectURI: String) async throws -> TokenPair
  func refreshToken(_ refreshToken: String) async throws -> TokenPair
  func revokeToken(_ token: String) async throws
  func fetchDeployments(limit: Int, projectIds: [String]?) async throws -> [DeploymentDTO]
  func fetchDeploymentDetail(idOrUrl: String) async throws -> DeploymentDetailDTO
  func fetchProjects() async throws -> [ProjectDTO]
}

struct TokenPair: Codable, Equatable {
  let accessToken: String
  let refreshToken: String?
  let expiresAt: Date
}

extension TokenPair {
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
