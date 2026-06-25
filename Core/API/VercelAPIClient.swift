import Foundation

protocol VercelAPIClient {
  func fetchDeployments(limit: Int, projectIds: [String]?, teamId: String?) async throws -> [DeploymentDTO]
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
