import Foundation

enum APIClientFactory {
  static func create() throws -> (client: VercelAPIClientImpl, teamId: String?) {
    guard let config = VercelAuthConfig.load() else {
      throw APIError.invalidResponse
    }
    let credentialStore = CredentialStore()
    let tokenProvider: () -> String? = {
      credentialStore.loadPersonalToken() ?? credentialStore.loadTokens()?.accessToken
    }
    let client = VercelAPIClientImpl(config: config, tokenProvider: tokenProvider)
    let teamId = credentialStore.loadTokens()?.teamId
    return (client, teamId)
  }
}
