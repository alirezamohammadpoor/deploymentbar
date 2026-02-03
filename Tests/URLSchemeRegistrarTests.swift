import XCTest
@testable import VercelBar

final class URLSchemeRegistrarTests: XCTestCase {
  func testShouldRegisterAppBundle() {
    let url = URL(fileURLWithPath: "/Applications/VercelBar.app")
    XCTAssertTrue(URLSchemeRegistrar.shouldRegister(bundleURL: url))
  }

  func testShouldNotRegisterNonApp() {
    let url = URL(fileURLWithPath: "/Applications/VercelBar")
    XCTAssertFalse(URLSchemeRegistrar.shouldRegister(bundleURL: url))
  }
}
