import Foundation

final class CredentialStore {
  private let account = "vercel.tokens"
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init() {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    self.encoder = encoder

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.decoder = decoder
  }

  func loadTokens() -> TokenPair? {
    do {
      guard let data = try KeychainWrapper.get(account) else { return nil }
      return try decoder.decode(TokenPair.self, from: data)
    } catch {
      return nil
    }
  }

  func saveTokens(_ tokens: TokenPair) {
    do {
      let data = try encoder.encode(tokens)
      try KeychainWrapper.set(data, account: account)
    } catch {
      // TODO: log error.
    }
  }

  func clearTokens() {
    do {
      try KeychainWrapper.delete(account)
    } catch {
      // TODO: log error.
    }
  }
}
