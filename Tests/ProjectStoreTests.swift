import XCTest
@testable import VercelBar

final class ProjectStoreTests: XCTestCase {
  func testErrorMessageForOAuthError() {
    let message = APIError.oauthError("invalid_client").userMessage
    XCTAssertEqual(message, "invalid_client")
  }
}
