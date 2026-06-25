import XCTest
@testable import VercelBar

final class CredentialStoreTests: XCTestCase {
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

  func testSavePersonalTokenWritesToKeychainAndClearsLegacyCopy() {
    let keychain = InMemoryKeychainStore()
    let legacy = InMemoryLegacyCredentialStore()
    legacy.personalTokenData = Data("stale".utf8)

    let store = CredentialStore(keychain: keychain, legacyStore: legacy)
    store.savePersonalToken("new-pat")

    XCTAssertEqual(
      String(data: keychain.values[CredentialStore.Account.personalToken] ?? Data(), encoding: .utf8),
      "new-pat"
    )
    XCTAssertNil(legacy.personalTokenData)
  }

  func testClearPersonalTokenRemovesKeychainAndLegacyData() {
    let keychain = InMemoryKeychainStore()
    let legacy = InMemoryLegacyCredentialStore()
    keychain.values[CredentialStore.Account.personalToken] = Data("pat".utf8)
    legacy.personalTokenData = Data("legacy-pat".utf8)

    let store = CredentialStore(keychain: keychain, legacyStore: legacy)
    store.clearPersonalToken()

    XCTAssertNil(keychain.values[CredentialStore.Account.personalToken])
    XCTAssertNil(legacy.personalTokenData)
  }

  func testGitHubTokenRoundTrips() {
    let keychain = InMemoryKeychainStore()
    let store = CredentialStore(keychain: keychain, legacyStore: InMemoryLegacyCredentialStore())

    store.saveGitHubToken("ghp_abc")
    XCTAssertEqual(store.loadGitHubToken(), "ghp_abc")

    store.clearGitHubToken()
    XCTAssertNil(store.loadGitHubToken())
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
  var personalTokenData: Data?

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
