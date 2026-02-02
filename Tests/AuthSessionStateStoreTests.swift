import XCTest
@testable import VercelBar

final class AuthSessionStateStoreTests: XCTestCase {
  func testRoundTrip() {
    let suiteName = "AuthSessionStateStoreTests.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    let store = AuthSessionStateStore(defaults: defaults)

    let pending = AuthSessionStateStore.Pending(
      state: "state",
      verifier: "verifier",
      redirectURI: "vercelbar://oauth/callback"
    )

    store.save(pending)

    XCTAssertEqual(store.load(), pending)

    store.clear()

    XCTAssertNil(store.load())
  }
}
