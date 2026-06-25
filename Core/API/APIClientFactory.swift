import Foundation

enum APIClientFactory {
  /// Builds an API client backed by the stored personal access token.
  /// `teamId` is always nil — a personal token's scope already determines access.
  static func create() throws -> (client: VercelAPIClientImpl, teamId: String?) {
    let credentialStore = CredentialStore.shared
    guard credentialStore.loadPersonalToken() != nil else {
      throw APIError.unauthorized
    }
    let client = VercelAPIClientImpl(tokenProvider: {
      credentialStore.loadPersonalToken()
    })
    return (client, nil)
  }
}
