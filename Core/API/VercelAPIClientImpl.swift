import Foundation

final class VercelAPIClientImpl: VercelAPIClient {
  private let tokenProvider: () -> String?
  private let session: URLSession

  init(tokenProvider: @escaping () -> String?, session: URLSession = .shared) {
    self.tokenProvider = tokenProvider
    self.session = session
  }

  func fetchDeployments(limit: Int, projectIds: [String]?, teamId: String? = nil) async throws -> [DeploymentDTO] {
    var items = [URLQueryItem(name: "limit", value: String(limit))]
    if let projectIds, !projectIds.isEmpty {
      items.append(URLQueryItem(name: "projectIds", value: projectIds.joined(separator: ",")))
    }
    if let teamId, !teamId.isEmpty {
      items.append(URLQueryItem(name: "teamId", value: teamId))
    }
    let request = try authorizedRequest(path: "/v6/deployments", queryItems: items)
    let (data, _) = try await session.data(for: request)
    if let raw = String(data: data, encoding: .utf8)?.prefix(500) {
      DebugLog.write("API /v6/deployments raw: \(raw)")
    }
    let response = try JSONDecoder.vercelDecoder.decode(DeploymentsResponse.self, from: data)
    return response.deployments
  }

  func fetchProjects(teamId: String? = nil) async throws -> [ProjectDTO] {
    var items: [URLQueryItem] = []
    if let teamId, !teamId.isEmpty {
      items.append(URLQueryItem(name: "teamId", value: teamId))
    }
    let request = try authorizedRequest(path: "/v9/projects", queryItems: items)
    let response: ProjectsResponse = try await execute(request)
    return response.projects
  }

  func fetchTeams() async throws -> [TeamDTO] {
    let request = try authorizedRequest(path: "/v2/teams", queryItems: [])
    let response: TeamsResponse = try await execute(request)
    return response.teams
  }

  /// Fetches the authenticated user and returns a display name. Throws on a
  /// non-2xx status, so it doubles as token validation when connecting.
  func fetchCurrentUser() async throws -> String {
    let request = try authorizedRequest(path: "/v2/user", queryItems: [])
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
    DebugLog.write("API /v2/user → \(http.statusCode) (\(data.count) bytes)")
    switch http.statusCode {
    case 200...299:
      if let parsed = try? JSONDecoder().decode(VercelUserResponse.self, from: data) {
        return parsed.displayName
      }
      return "your account"
    case 401, 403:
      throw APIError.unauthorized
    default:
      throw APIError.invalidResponse
    }
  }

  func fetchDeploymentEvents(deploymentId: String, teamId: String? = nil) async throws -> [LogLine] {
    var items: [URLQueryItem] = []
    if let teamId, !teamId.isEmpty {
      items.append(URLQueryItem(name: "teamId", value: teamId))
    }
    let request = try authorizedRequest(path: "/v2/deployments/\(deploymentId)/events", queryItems: items)
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
    DebugLog.write("API /v2/deployments/\(deploymentId)/events → \(http.statusCode) (\(data.count) bytes)")

    switch http.statusCode {
    case 200...299:
      let events = try JSONDecoder.vercelDecoder.decode([DeploymentEventDTO].self, from: data)
      var lineNumber = 1
      var logLines: [LogLine] = []
      for event in events {
        if event.type == "stdout" || event.type == "stderr" {
          if let line = LogLine.from(dto: event, lineNumber: lineNumber) {
            logLines.append(line)
            lineNumber += 1
          }
        }
      }
      return logLines
    case 401:
      throw APIError.unauthorized
    case 403:
      throw APIError.forbidden
    case 404:
      throw APIError.notFound
    case 429:
      let reset = http.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap { TimeInterval($0) }
      throw APIError.rateLimited(resetAt: reset.map { Date(timeIntervalSince1970: $0) })
    default:
      throw APIError.invalidResponse
    }
  }

  func createDeployment(name: String, target: String?, gitSource: GitDeploymentSource, teamId: String? = nil) async throws -> DeploymentDTO {
    var items: [URLQueryItem] = []
    if let teamId, !teamId.isEmpty {
      items.append(URLQueryItem(name: "teamId", value: teamId))
    }

    var request = try authorizedRequest(path: "/v13/deployments", queryItems: items)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    var body: [String: Any] = [
      "name": name,
      "gitSource": [
        "type": gitSource.type,
        "ref": gitSource.ref,
        "repoId": gitSource.repoId
      ]
    ]
    if let target {
      body["target"] = target
    }

    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    return try await execute(request)
  }

  func rollbackProject(projectId: String, deploymentId: String, teamId: String? = nil) async throws {
    var items: [URLQueryItem] = []
    if let teamId, !teamId.isEmpty {
      items.append(URLQueryItem(name: "teamId", value: teamId))
    }

    var request = try authorizedRequest(path: "/v9/projects/\(projectId)/rollback", queryItems: items)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
      "deploymentId": deploymentId
    ]
    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    try await executeNoContent(request)
  }

  private func authorizedRequest(path: String, queryItems: [URLQueryItem]) throws -> URLRequest {
    guard let token = tokenProvider() else { throw APIError.unauthorized }
    guard var components = URLComponents(url: VercelEndpoints.baseURL, resolvingAgainstBaseURL: false) else {
      throw APIError.invalidResponse
    }
    components.path = path
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    guard let url = components.url else { throw APIError.invalidResponse }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return request
  }

  private func execute<Response: Decodable>(_ request: URLRequest) async throws -> Response {
    do {
      let (data, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
      DebugLog.write("API \(request.url?.path ?? "?") → \(http.statusCode) (\(data.count) bytes)")
      switch http.statusCode {
      case 200...299:
        do {
          return try JSONDecoder.vercelDecoder.decode(Response.self, from: data)
        } catch {
          DebugLog.write("API decode failed: \(error)")
          if let raw = String(data: data, encoding: .utf8)?.prefix(500) {
            DebugLog.write("API raw response: \(raw)")
          }
          throw APIError.decodingFailed
        }
      case 401:
        throw APIError.unauthorized
      case 429:
        let reset = http.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap { TimeInterval($0) }
        let resetDate = reset.map { Date(timeIntervalSince1970: $0) }
        throw APIError.rateLimited(resetAt: resetDate)
      case 500...599:
        throw APIError.serverError
      default:
        throw APIError.invalidResponse
      }
    } catch let error as APIError {
      throw error
    } catch {
      throw APIError.networkFailure
    }
  }

  private func executeNoContent(_ request: URLRequest) async throws {
    do {
      let (_, response) = try await session.data(for: request)
      guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
      switch http.statusCode {
      case 200...299:
        return
      case 401:
        throw APIError.unauthorized
      case 429:
        let reset = http.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap { TimeInterval($0) }
        let resetDate = reset.map { Date(timeIntervalSince1970: $0) }
        throw APIError.rateLimited(resetAt: resetDate)
      case 500...599:
        throw APIError.serverError
      default:
        throw APIError.invalidResponse
      }
    } catch let error as APIError {
      throw error
    } catch {
      throw APIError.networkFailure
    }
  }
}

private struct DeploymentsResponse: Decodable {
  let deployments: [DeploymentDTO]
}

private struct ProjectsResponse: Decodable {
  let projects: [ProjectDTO]
}

private struct TeamsResponse: Decodable {
  let teams: [TeamDTO]
}

private struct VercelUserResponse: Decodable {
  struct User: Decodable {
    let username: String?
    let name: String?
    let email: String?
  }
  let user: User

  var displayName: String {
    user.username ?? user.name ?? user.email ?? "your account"
  }
}
