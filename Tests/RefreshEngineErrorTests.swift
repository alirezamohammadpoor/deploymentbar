import XCTest
@testable import VercelBar

final class RefreshEngineErrorTests: XCTestCase {
  func testErrorMessageForOAuthError() {
    let message = RefreshEngine.errorMessage(for: .oauthError("invalid_client"))
    XCTAssertEqual(message, "invalid_client")
  }
}
