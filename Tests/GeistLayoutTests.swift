import XCTest
@testable import VercelBar

final class GeistLayoutTests: XCTestCase {
  func testStatusDotAndBadgeMetricsMatchSpec() {
    XCTAssertEqual(Geist.Layout.statusDotSize, 8)
    XCTAssertEqual(Geist.Layout.badgePaddingH, 4)
    XCTAssertEqual(Geist.Layout.badgePaddingV, 2)
    XCTAssertEqual(Geist.Layout.badgeCornerRadius, 9999)
  }
}
