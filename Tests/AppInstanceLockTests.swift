import XCTest
@testable import VercelBar

final class AppInstanceLockTests: XCTestCase {
  func testSecondAcquireFails() {
    let path = NSTemporaryDirectory() + "/vercelbar.lock.\(UUID().uuidString)"
    let first = AppInstanceLock.acquire(path: path)
    let second = AppInstanceLock.acquire(path: path)

    XCTAssertNotNil(first)
    XCTAssertNil(second)
  }
}
