import Foundation

protocol CredentialStoring {
  func loadTokens() -> TokenPair?
  func saveTokens(_ tokens: TokenPair)
  func clearTokens()
  func loadPersonalToken() -> String?
  func savePersonalToken(_ token: String)
  func clearPersonalToken()
}

protocol KeychainDataStoring {
  func data(for account: String) -> Data?
  @discardableResult
  func setData(_ data: Data, for account: String) -> Bool
  func removeData(for account: String)
}

protocol LegacyCredentialFileStoring {
  func loadOAuthTokensData() -> Data?
  func saveOAuthTokensData(_ data: Data)
  func clearOAuthTokensData()

  func loadPersonalTokenData() -> Data?
  func savePersonalTokenData(_ data: Data)
  func clearPersonalTokenData()
}

final class CredentialStore: CredentialStoring {
  enum Account {
    static let oauthTokens = "oauth-tokens"
    static let personalToken = "personal-token"
  }

  static var defaultKeychainService: String {
    let bundleID = Bundle.main.bundleIdentifier ?? "com.example.VercelBar"
    return "\(bundleID).credentials"
  }

  private let keychain: KeychainDataStoring
  private let legacyStore: LegacyCredentialFileStoring
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init(
    keychain: KeychainDataStoring? = nil,
    legacyStore: LegacyCredentialFileStoring = LegacyCredentialFileStore()
  ) {
    self.keychain = keychain ?? KeychainWrapper(service: Self.defaultKeychainService)
    self.legacyStore = legacyStore

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    self.encoder = encoder

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.decoder = decoder
  }

  func loadTokens() -> TokenPair? {
    if let keychainData = keychain.data(for: Account.oauthTokens) {
      if let tokens = decodeTokens(from: keychainData) {
        legacyStore.clearOAuthTokensData()
        return tokens
      }

      DebugLog.write("CredentialStore.loadTokens found invalid Keychain data, clearing")
      keychain.removeData(for: Account.oauthTokens)
    }

    guard let legacyData = legacyStore.loadOAuthTokensData(),
          let tokens = decodeTokens(from: legacyData) else {
      return nil
    }

    migrateOAuthTokensToKeychain(legacyData)
    return tokens
  }

  func saveTokens(_ tokens: TokenPair) {
    do {
      let data = try encoder.encode(tokens)

      if keychain.setData(data, for: Account.oauthTokens) {
        legacyStore.clearOAuthTokensData()
      } else {
        DebugLog.write("CredentialStore.saveTokens failed to persist Keychain item")
      }
    } catch {
      DebugLog.write("CredentialStore.saveTokens failed: \(error)")
    }
  }

  func clearTokens() {
    keychain.removeData(for: Account.oauthTokens)
    legacyStore.clearOAuthTokensData()
  }

  func loadPersonalToken() -> String? {
    if let keychainData = keychain.data(for: Account.personalToken) {
      if let token = decodePersonalToken(from: keychainData) {
        legacyStore.clearPersonalTokenData()
        return token
      }

      DebugLog.write("CredentialStore.loadPersonalToken found invalid Keychain data, clearing")
      keychain.removeData(for: Account.personalToken)
    }

    guard let legacyData = legacyStore.loadPersonalTokenData(),
          let token = decodePersonalToken(from: legacyData) else {
      return nil
    }

    migratePersonalTokenToKeychain(legacyData)
    return token
  }

  func savePersonalToken(_ token: String) {
    let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let data = trimmed.data(using: .utf8), !trimmed.isEmpty else {
      return
    }

    if keychain.setData(data, for: Account.personalToken) {
      legacyStore.clearPersonalTokenData()
    } else {
      DebugLog.write("CredentialStore.savePersonalToken failed to persist Keychain item")
    }
  }

  func clearPersonalToken() {
    keychain.removeData(for: Account.personalToken)
    legacyStore.clearPersonalTokenData()
  }

  private func decodeTokens(from data: Data) -> TokenPair? {
    do {
      return try decoder.decode(TokenPair.self, from: data)
    } catch {
      DebugLog.write("CredentialStore.decodeTokens failed: \(error)")
      return nil
    }
  }

  private func decodePersonalToken(from data: Data) -> String? {
    guard let token = String(data: data, encoding: .utf8)?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !token.isEmpty else {
      return nil
    }
    return token
  }

  private func migrateOAuthTokensToKeychain(_ data: Data) {
    if keychain.setData(data, for: Account.oauthTokens) {
      legacyStore.clearOAuthTokensData()
      DebugLog.write("CredentialStore migrated OAuth tokens from legacy storage to Keychain")
    } else {
      DebugLog.write("CredentialStore failed to migrate OAuth tokens to Keychain")
    }
  }

  private func migratePersonalTokenToKeychain(_ data: Data) {
    if keychain.setData(data, for: Account.personalToken) {
      legacyStore.clearPersonalTokenData()
      DebugLog.write("CredentialStore migrated PAT from legacy storage to Keychain")
    } else {
      DebugLog.write("CredentialStore failed to migrate PAT to Keychain")
    }
  }
}

final class LegacyCredentialFileStore: LegacyCredentialFileStoring {
  private let directory: URL
  private let oauthTokensFile: String
  private let personalTokenFile: String

  init(
    directory: URL = LegacyCredentialFileStore.defaultDirectory(),
    oauthTokensFile: String = "oauth-tokens.json",
    personalTokenFile: String = "personal-token"
  ) {
    self.directory = directory
    self.oauthTokensFile = oauthTokensFile
    self.personalTokenFile = personalTokenFile

    try? FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700]
    )
  }

  func loadOAuthTokensData() -> Data? {
    read(fileName: oauthTokensFile)
  }

  func saveOAuthTokensData(_ data: Data) {
    write(data: data, fileName: oauthTokensFile)
  }

  func clearOAuthTokensData() {
    delete(fileName: oauthTokensFile)
  }

  func loadPersonalTokenData() -> Data? {
    read(fileName: personalTokenFile)
  }

  func savePersonalTokenData(_ data: Data) {
    write(data: data, fileName: personalTokenFile)
  }

  func clearPersonalTokenData() {
    delete(fileName: personalTokenFile)
  }

  private func read(fileName: String) -> Data? {
    let url = directory.appendingPathComponent(fileName)
    return try? Data(contentsOf: url)
  }

  private func write(data: Data, fileName: String) {
    let url = directory.appendingPathComponent(fileName)
    do {
      try data.write(to: url, options: [.atomic])
      try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    } catch {
      DebugLog.write("LegacyCredentialFileStore.write failed (\(fileName)): \(error)")
    }
  }

  private func delete(fileName: String) {
    let url = directory.appendingPathComponent(fileName)
    try? FileManager.default.removeItem(at: url)
  }

  private static func defaultDirectory() -> URL {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return appSupport.appendingPathComponent("VercelBar", isDirectory: true)
  }
}
