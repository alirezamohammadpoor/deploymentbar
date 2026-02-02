import Foundation

final class CredentialStore {
  func loadTokens() -> TokenPair? {
    // TODO: load from Keychain.
    nil
  }

  func saveTokens(_ tokens: TokenPair) {
    // TODO: save to Keychain.
  }

  func clearTokens() {
    // TODO: remove from Keychain.
  }
}
