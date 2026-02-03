import Foundation

final class VercelAPIClientImpl: VercelAPIClient {
  private let config: VercelAuthConfig
  private let tokenProvider: () -> String?
  private let session: URLSession

  init(config: VercelAuthConfig, tokenProvider: @escaping () -> String?, session: URLSession = .shared) {
    self.config = config
    self.tokenProvider = tokenProvider
    self.session = session
  }

  func authorizationURL(state: String, codeChallenge: String?) -> URL {
    var components = URLComponents(url: VercelEndpoints.oauthAuthorize, resolvingAgainstBaseURL: false)!
    var items: [URLQueryItem] = [
      URLQueryItem(name: "client_id", value: config.clientId),
      URLQueryItem(name: "redirect_uri", value: config.redirectURI),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "scope", value: config.scopes.joined(separator: " "))
    ]

    if let codeChallenge {
      items.append(URLQueryItem(name: "code_challenge", value: codeChallenge))
      items.append(URLQueryItem(name: "code_challenge_method", value: "S256"))
    }

    components.queryItems = items
    return components.url!
  }

  func exchangeCode(_ code: String, codeVerifier: String?, redirectURI: String) async throws -> TokenPair {
    var body: [String: String] = [
      "grant_type": "authorization_code",
      "client_id": config.clientId,
      "code": code,
      "redirect_uri": redirectURI
    ]
    if let secret = config.clientSecret {
      body["client_secret"] = secret
    }
    if let codeVerifier {
      body["code_verifier"] = codeVerifier
    }
    return try await tokenRequest(body: body)
  }

  func refreshToken(_ refreshToken: String) async throws -> TokenPair {
    var body: [String: String] = [
      "grant_type": "refresh_token",
      "client_id": config.clientId,
      "refresh_token": refreshToken
    ]
    if let secret = config.clientSecret {
      body["client_secret"] = secret
    }
    return try await tokenRequest(body: body, fallbackRefreshToken: refreshToken)
  }

  func revokeToken(_ token: String) async throws {
    var body: [String: String] = [
      "client_id": config.clientId,
      "token": token
    ]
    if let secret = config.clientSecret {
      body["client_secret"] = secret
    }

    var request = URLRequest(url: VercelEndpoints.oauthRevoke)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = formBody(body)

    try await executeNoContent(request)
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

  func fetchDeploymentDetail(idOrUrl: String) async throws -> DeploymentDetailDTO {
    let encoded = idOrUrl.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? idOrUrl
    let request = try authorizedRequest(path: "/v13/deployments/\(encoded)", queryItems: [])
    return try await execute(request)
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

  func fetchCurrentUser() async throws -> String {
    let request = try authorizedRequest(path: "/v2/user", queryItems: [])
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
    DebugLog.write("API /v2/user → \(http.statusCode) (\(data.count) bytes)")
    return String(data: data, encoding: .utf8) ?? "unreadable"
  }

  private func tokenRequest(body: [String: String], fallbackRefreshToken: String? = nil) async throws -> TokenPair {
    var request = URLRequest(url: VercelEndpoints.oauthToken)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = formBody(body)

    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await session.data(for: request)
    } catch {
      throw APIError.networkFailure
    }
    guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

    if (200...299).contains(http.statusCode) {
      if let raw = String(data: data, encoding: .utf8)?.prefix(500) {
        DebugLog.write("Token exchange raw response: \(raw)")
      }
      if let parsed = TokenResponseParser.parse(data: data) {
        let refresh = parsed.refreshToken ?? fallbackRefreshToken
        let expiresIn = TimeInterval(parsed.expiresIn ?? 3600)
        DebugLog.write("Token exchange: teamId=\(parsed.teamId ?? "nil")")
        return TokenPair(
          accessToken: parsed.accessToken,
          refreshToken: refresh,
          expiresAt: Date().addingTimeInterval(expiresIn),
          teamId: parsed.teamId
        )
      }

      let message = OAuthErrorParser.parseMessage(data: data, statusCode: http.statusCode)
      throw APIError.oauthError(message ?? "OAuth token decode failed (HTTP \(http.statusCode))")
    }

    let message = OAuthErrorParser.parseMessage(data: data, statusCode: http.statusCode)
    throw APIError.oauthError(message ?? "OAuth error (HTTP \(http.statusCode))")
  }

  private func formBody(_ body: [String: String]) -> Data? {
    body
      .map { key, value in "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value)" }
      .joined(separator: "&")
      .data(using: .utf8)
  }

  private func authorizedRequest(path: String, queryItems: [URLQueryItem]) throws -> URLRequest {
    guard let token = tokenProvider() else { throw APIError.unauthorized }
    var components = URLComponents(url: VercelEndpoints.baseURL, resolvingAgainstBaseURL: false)!
    components.path = path
    components.queryItems = queryItems.isEmpty ? nil : queryItems
    guard let url = components.url else { throw APIError.invalidResponse }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    return request
  }

  private func execute<Response: Decodable>(_ request: URLRequest, requiresAuth: Bool = true) async throws -> Response {
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
