import Foundation

enum APIError: Error, Equatable {
  case invalidResponse
  case unauthorized
  case forbidden
  case notFound
  case rateLimited(resetAt: Date?)
  case serverError
  case decodingFailed
  case networkFailure
  case oauthError(String)
}
