import Foundation

struct OAuthErrorParser {
  static func parseMessage(data: Data) -> String? {
    guard let payload = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) else {
      return nil
    }
    if let description = payload.errorDescription, !description.isEmpty {
      return "\(payload.error): \(description)"
    }
    return payload.error.isEmpty ? nil : payload.error
  }
}

private struct OAuthErrorResponse: Decodable {
  let error: String
  let errorDescription: String?

  enum CodingKeys: String, CodingKey {
    case error
    case errorDescription = "error_description"
  }
}
