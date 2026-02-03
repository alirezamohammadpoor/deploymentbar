import Foundation

protocol CredentialStoring {
  func loadTokens() -> TokenPair?
  func saveTokens(_ tokens: TokenPair)
  func clearTokens()
  func loadPersonalToken() -> String?
  func savePersonalToken(_ token: String)
  func clearPersonalToken()
}

final class CredentialStore: CredentialStoring {
  private let account = "vercel.tokens"
  private let personalTokenAccount = "vercel.pat"
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

  func loadPersonalToken() -> String? {
    do {
      guard let data = try KeychainWrapper.get(personalTokenAccount) else { return nil }
      return String(data: data, encoding: .utf8)
    } catch {
      return nil
    }
  }

  func savePersonalToken(_ token: String) {
    do {
      guard let data = token.data(using: .utf8) else { return }
      try KeychainWrapper.set(data, account: personalTokenAccount)
    } catch {
      // TODO: log error.
    }
  }

  func clearPersonalToken() {
    do {
      try KeychainWrapper.delete(personalTokenAccount)
    } catch {
      // TODO: log error.
    }
  }
}
