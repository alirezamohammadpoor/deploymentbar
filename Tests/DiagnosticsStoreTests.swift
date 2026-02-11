import XCTest
@testable import VercelBar

@MainActor
final class DiagnosticsStoreTests: XCTestCase {
  override func tearDown() {
    DebugLog.setLogPathForTesting(nil)
    DebugLog.clear()
    super.tearDown()
  }

  func testRecentLogLinesReturnsTail() {
    let logPath = tempLogPath(named: "DiagnosticsStoreTests-\(UUID().uuidString).log")
    DebugLog.setLogPathForTesting(logPath)
    DebugLog.clear()

    try? """
    line-1
    line-2
    line-3
    """.write(toFile: logPath, atomically: true, encoding: .utf8)

    let diagnosticsStore = DiagnosticsStore(
      authSession: makeSignedOutSession(),
      refreshStatusStore: makeRefreshStore(),
      settingsStore: .shared,
      logPathProvider: { logPath }
    )

    let lines = diagnosticsStore.recentLogLines(limit: 2)
    XCTAssertEqual(lines, ["line-2", "line-3"])
  }

  func testBuildSnapshotContainsCoreSections() {
    let logPath = tempLogPath(named: "DiagnosticsStoreTests-\(UUID().uuidString).log")
    DebugLog.setLogPathForTesting(logPath)
    DebugLog.clear()

    let refreshStore = makeRefreshStore()
    refreshStore.mutate { status in
      status.isStale = true
      status.error = "Network error"
    }

    let diagnosticsStore = DiagnosticsStore(
      authSession: makeSignedOutSession(),
      refreshStatusStore: refreshStore,
      settingsStore: .shared,
      bundle: .main,
      logPathProvider: { logPath },
      nowProvider: { Date(timeIntervalSince1970: 1234) }
    )

    let snapshot = diagnosticsStore.buildSnapshot()
    XCTAssertTrue(snapshot.contains("VercelBar Diagnostics"))
    XCTAssertTrue(snapshot.contains("Auth"))
    XCTAssertTrue(snapshot.contains("Refresh"))
    XCTAssertTrue(snapshot.contains("Settings"))
    XCTAssertTrue(snapshot.contains("Status: signedOut"))
    XCTAssertTrue(snapshot.contains("Error: Network error"))
  }

  func testClearLogsRemovesLogFile() {
    let logPath = tempLogPath(named: "DiagnosticsStoreTests-\(UUID().uuidString).log")
    DebugLog.setLogPathForTesting(logPath)
    DebugLog.clear()

    FileManager.default.createFile(atPath: logPath, contents: Data("hello".utf8))
    XCTAssertTrue(FileManager.default.fileExists(atPath: logPath))

    let diagnosticsStore = DiagnosticsStore(
      authSession: makeSignedOutSession(),
      refreshStatusStore: makeRefreshStore(),
      settingsStore: .shared,
      logPathProvider: { logPath }
    )
    diagnosticsStore.clearLogs()

    XCTAssertFalse(FileManager.default.fileExists(atPath: logPath))
  }

  private func makeSignedOutSession() -> AuthSession {
    AuthSession.makeForTesting(
      credentialStore: TestCredentialStore(tokens: nil),
      stateStore: AuthSessionStateStore(defaults: UserDefaults(suiteName: UUID().uuidString)!)
    )
  }

  private func makeRefreshStore() -> RefreshStatusStore {
    let refreshStore = RefreshStatusStore()
    refreshStore.status = .idle
    return refreshStore
  }

  private func tempLogPath(named name: String) -> String {
    FileManager.default.temporaryDirectory.appendingPathComponent(name).path
  }
}

private final class TestCredentialStore: CredentialStoring {
  private let tokens: TokenPair?

  init(tokens: TokenPair?) {
    self.tokens = tokens
  }

  func loadTokens() -> TokenPair? { tokens }
  func saveTokens(_ tokens: TokenPair) {}
  func clearTokens() {}
  func loadPersonalToken() -> String? { nil }
  func savePersonalToken(_ token: String) {}
  func clearPersonalToken() {}
}
