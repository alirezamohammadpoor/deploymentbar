import XCTest
@testable import VercelBar

@MainActor
final class StatusBarControllerTests: XCTestCase {
  func testStatusBarControllerInitializesOnMainActor() {
    let controller = StatusBarController()
    XCTAssertNotNil(controller)
  }
}
