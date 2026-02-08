import Foundation

enum VercelEndpoints {
  static let baseURL = URL(string: "https://api.vercel.com")!
  static let oauthAuthorize = URL(string: "https://vercel.com/oauth/authorize")!
  static let oauthToken = URL(string: "https://api.vercel.com/login/oauth/token")!
  static let oauthRevoke = URL(string: "https://api.vercel.com/login/oauth/token/revoke")!
}
