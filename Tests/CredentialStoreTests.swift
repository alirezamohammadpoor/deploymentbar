import XCTest
@testable import VercelBar

final class CredentialStoreTests: XCTestCase {
  func testLoadTokensMigratesLegacyDataToKeychain() throws {
    let keychain = InMemoryKeychainStore()
    let legacy = InMemoryLegacyCredentialStore()
    let tokens = makeTokens(access: "legacy-access")
    legacy.oauthTokensData = try encodeTokens(tokens)

    let store = CredentialStore(keychain: keychain, legacyStore: legacy)

    let loaded = store.loadTokens()

    XCTAssertEqual(loaded, tokens)
    XCTAssertNotNil(keychain.data(for: CredentialStore.Account.oauthTokens))
    XCTAssertNil(legacy.oauthTokensData)
  }

  func testLoadTokensFallsBackToLegacyWhenKeychainDataIsCorrupt() throws {
    let keychain = InMemoryKeychainStore()
    let legacy = InMemoryLegacyCredentialStore()
    let legacyTokens = makeTokens(access: "legacy-access")
    keychain.values[CredentialStore.Account.oauthTokens] = Data("not-json".utf8)
    legacy.oauthTokensData = try encodeTokens(legacyTokens)

    let store = CredentialStore(keychain: keychain, legacyStore: legacy)

    let loaded = store.loadTokens()

    XCTAssertEqual(loaded, legacyTokens)
    XCTAssertEqual(
      try decodeTokens(keychain.values[CredentialStore.Account.oauthTokens]),
      legacyTokens
    )
    XCTAssertNil(legacy.oauthTokensData)
  }

  func testLoadPersonalTokenMigratesLegacyDataToKeychain() {
    let keychain = InMemoryKeychainStore()
    let legacy = InMemoryLegacyCredentialStore()
    legacy.personalTokenData = Data("legacy-pat".utf8)

    let store = CredentialStore(keychain: keychain, legacyStore: legacy)

    let loaded = store.loadPersonalToken()

    XCTAssertEqual(loaded, "legacy-pat")
    XCTAssertEqual(
      String(data: keychain.values[CredentialStore.Account.personalToken] ?? Data(), encoding: .utf8),
      "legacy-pat"
    )
    XCTAssertNil(legacy.personalTokenData)
  }

  func testSaveTokensWritesToKeychainAndClearsLegacyCopy() throws {
    let keychain = InMemoryKeychainStore()
    let legacy = InMemoryLegacyCredentialStore()
    legacy.oauthTokensData = Data("stale".utf8)
    let tokens = makeTokens(access: "new-access")

    let store = CredentialStore(keychain: keychain, legacyStore: legacy)

    store.saveTokens(tokens)

    XCTAssertEqual(
      try decodeTokens(keychain.values[CredentialStore.Account.oauthTokens]),
      tokens
    )
    XCTAssertNil(legacy.oauthTokensData)
  }

  func testClearRemovesKeychainAndLegacyData() {
    let keychain = InMemoryKeychainStore()
    let legacy = InMemoryLegacyCredentialStore()
    keychain.values[CredentialStore.Account.oauthTokens] = Data("oauth".utf8)
    keychain.values[CredentialStore.Account.personalToken] = Data("pat".utf8)
    legacy.oauthTokensData = Data("legacy-oauth".utf8)
    legacy.personalTokenData = Data("legacy-pat".utf8)

    let store = CredentialStore(keychain: keychain, legacyStore: legacy)

    store.clearTokens()
    store.clearPersonalToken()

    XCTAssertNil(keychain.values[CredentialStore.Account.oauthTokens])
    XCTAssertNil(keychain.values[CredentialStore.Account.personalToken])
    XCTAssertNil(legacy.oauthTokensData)
    XCTAssertNil(legacy.personalTokenData)
  }

  private func makeTokens(access: String) -> TokenPair {
    TokenPair(
      accessToken: access,
      refreshToken: "refresh",
      expiresAt: Date(timeIntervalSince1970: 1_700_000_000),
      teamId: "team_1"
    )
  }

  private func encodeTokens(_ tokens: TokenPair) throws -> Data {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(tokens)
  }

  private func decodeTokens(_ data: Data?) throws -> TokenPair? {
    guard let data else { return nil }
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return try decoder.decode(TokenPair.self, from: data)
  }
}

private final class InMemoryKeychainStore: KeychainDataStoring {
  var values: [String: Data] = [:]

  func data(for account: String) -> Data? {
    values[account]
  }

  @discardableResult
  func setData(_ data: Data, for account: String) -> Bool {
    values[account] = data
    return true
  }

  func removeData(for account: String) {
    values.removeValue(forKey: account)
  }
}

private final class InMemoryLegacyCredentialStore: LegacyCredentialFileStoring {
  var oauthTokensData: Data?
  var personalTokenData: Data?

  func loadOAuthTokensData() -> Data? {
    oauthTokensData
  }

  func saveOAuthTokensData(_ data: Data) {
    oauthTokensData = data
  }

  func clearOAuthTokensData() {
    oauthTokensData = nil
  }

  func loadPersonalTokenData() -> Data? {
    personalTokenData
  }

  func savePersonalTokenData(_ data: Data) {
    personalTokenData = data
  }

  func clearPersonalTokenData() {
    personalTokenData = nil
  }
}
