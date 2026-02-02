import Foundation

enum APIError: Error, Equatable {
  case invalidResponse
  case unauthorized
  case rateLimited(resetAt: Date?)
  case serverError
  case decodingFailed
  case networkFailure
}
