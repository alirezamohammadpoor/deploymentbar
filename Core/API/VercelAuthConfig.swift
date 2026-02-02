import Foundation

struct VercelAuthConfig: Equatable {
  let clientId: String
  let clientSecret: String?
  let redirectURI: String
  let scopes: [String]

  static func load(from bundle: Bundle = .main) -> VercelAuthConfig? {
    guard let info = bundle.infoDictionary else { return nil }
    guard let clientId = info["VercelClientId"] as? String, !clientId.isEmpty else {
      return nil
    }
    guard let redirectURI = info["VercelRedirectURI"] as? String, !redirectURI.isEmpty else {
      return nil
    }
    let clientSecret = (info["VercelClientSecret"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    let scopesValue = (info["VercelScopes"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    let scopes = scopesValue?.split(separator: " ").map(String.init) ?? ["offline_access"]
    return VercelAuthConfig(
      clientId: clientId,
      clientSecret: clientSecret,
      redirectURI: redirectURI,
      scopes: scopes
    )
  }
}
