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

extension APIError {
  var userMessage: String {
    switch self {
    case .unauthorized:
      return "Unauthorized"
    case .forbidden:
      return "Access denied"
    case .notFound:
      return "Not found"
    case .rateLimited(let resetAt):
      if let resetAt {
        return "Rate limited until \(DateFormatter.shortTime.string(from: resetAt))"
      }
      return "Rate limited"
    case .serverError:
      return "Server error"
    case .decodingFailed:
      return "Decode error"
    case .networkFailure:
      return "Network error"
    case .invalidResponse:
      return "Invalid response"
    case .oauthError(let message):
      return message
    }
  }
}

private extension DateFormatter {
  static var shortTime: DateFormatter {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
  }
}
