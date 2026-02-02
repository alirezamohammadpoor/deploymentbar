import Foundation

protocol VercelAPIClient {
  func authorizationURL(state: String, codeChallenge: String) -> URL
  func exchangeCode(_ code: String, codeVerifier: String, redirectURI: String) async throws -> TokenPair
  func refreshToken(_ refreshToken: String) async throws -> TokenPair
  func fetchDeployments(limit: Int, projectIds: [String]?) async throws -> [DeploymentDTO]
  func fetchDeploymentDetail(idOrUrl: String) async throws -> DeploymentDetailDTO
}

struct TokenPair: Equatable {
  let accessToken: String
  let refreshToken: String
  let expiresAt: Date
}
