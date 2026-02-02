import XCTest
@testable import VercelBar

final class ProjectStoreTests: XCTestCase {
  func testErrorMessageForOAuthError() {
    let message = ProjectStore.errorMessage(for: .oauthError("invalid_client"))
    XCTAssertEqual(message, "invalid_client")
  }
}
