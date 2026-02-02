import Foundation

struct OAuthErrorParser {
  static func parseMessage(data: Data, statusCode: Int) -> String? {
    if let payload = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) {
      if let description = payload.errorDescription, !description.isEmpty {
        return "\(payload.error): \(description)"
      }
      return payload.error.isEmpty ? nil : payload.error
    }

    if let body = String(data: data, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !body.isEmpty {
      return "OAuth error (HTTP \(statusCode)): \(body)"
    }

    return "OAuth error (HTTP \(statusCode))"
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
