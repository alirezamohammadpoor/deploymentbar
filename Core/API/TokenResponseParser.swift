import Foundation

struct TokenResponseParser {
  struct Parsed: Equatable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int?
  }

  static func parse(data: Data) -> Parsed? {
    if let parsed = parseJSON(data: data) {
      return parsed
    }
    return parseForm(data: data)
  }

  private static func parseJSON(data: Data) -> Parsed? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return nil
    }
    guard let accessToken = json["access_token"] as? String else {
      return nil
    }
    let refreshToken = json["refresh_token"] as? String
    let expiresIn = json["expires_in"] as? Int
    return Parsed(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
  }

  private static func parseForm(data: Data) -> Parsed? {
    guard let body = String(data: data, encoding: .utf8), !body.isEmpty else {
      return nil
    }
    var values: [String: String] = [:]
    for part in body.split(separator: "&") {
      let pair = part.split(separator: "=", maxSplits: 1).map(String.init)
      guard pair.count == 2 else { continue }
      let key = pair[0]
      let value = pair[1].removingPercentEncoding ?? pair[1]
      values[key] = value
    }
    guard let accessToken = values["access_token"] else {
      return nil
    }
    let refreshToken = values["refresh_token"]
    let expiresIn = values["expires_in"].flatMap { Int($0) }
    return Parsed(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
  }
}
