import Foundation

enum VercelEndpoints {
  static let baseURL = URL(string: "https://api.vercel.com")!

  /// Web page where users create a Personal Access Token. PATs are the supported
  /// path for reading personal-account resources — OAuth resource scopes are Team-only.
  static let accountTokensPage = URL(string: "https://vercel.com/account/settings/tokens")!
}

enum GitHubEndpoints {
  /// New classic-token page with the name + `repo` scope pre-filled, so the user
  /// lands on a form that's already configured for reading CI check runs.
  static let newTokenPage = URL(string: "https://github.com/settings/tokens/new?description=Deploymentbar&scopes=repo")!
}
