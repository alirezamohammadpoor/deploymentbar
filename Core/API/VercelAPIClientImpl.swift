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

  func fetchDeployments(limit: Int, projectIds: [String]?) async throws -> [DeploymentDTO] {
    var items = [URLQueryItem(name: "limit", value: String(limit))]
    if let projectIds, !projectIds.isEmpty {
      items.append(URLQueryItem(name: "projectIds", value: projectIds.joined(separator: ",")))
    }
    let request = try authorizedRequest(path: "/v6/deployments", queryItems: items)
    let response: DeploymentsResponse = try await execute(request)
    return response.deployments
  }

  func fetchDeploymentDetail(idOrUrl: String) async throws -> DeploymentDetailDTO {
    let encoded = idOrUrl.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? idOrUrl
    let request = try authorizedRequest(path: "/v13/deployments/\(encoded)", queryItems: [])
    return try await execute(request)
  }

  func fetchProjects() async throws -> [ProjectDTO] {
    let request = try authorizedRequest(path: "/v9/projects", queryItems: [])
    let response: ProjectsResponse = try await execute(request)
    return response.projects
  }

  private func tokenRequest(body: [String: String], fallbackRefreshToken: String? = nil) async throws -> TokenPair {
    var request = URLRequest(url: VercelEndpoints.oauthToken)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = formBody(body)

    let response: OAuthTokenResponse = try await execute(request, requiresAuth: false)
    guard let refresh = response.refreshToken ?? fallbackRefreshToken else {
      throw APIError.invalidResponse
    }
    let expiresIn = TimeInterval(response.expiresIn ?? 3600)
    return TokenPair(
      accessToken: response.accessToken,
      refreshToken: refresh,
      expiresAt: Date().addingTimeInterval(expiresIn)
    )
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
      switch http.statusCode {
      case 200...299:
        do {
          return try JSONDecoder.vercelDecoder.decode(Response.self, from: data)
        } catch {
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

private struct OAuthTokenResponse: Decodable {
  let accessToken: String
  let refreshToken: String?
  let expiresIn: Int?

  enum CodingKeys: String, CodingKey {
    case accessToken = "access_token"
    case refreshToken = "refresh_token"
    case expiresIn = "expires_in"
  }
}

private extension JSONDecoder {
  static var vercelDecoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys
    return decoder
  }
}
