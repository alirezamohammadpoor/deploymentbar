import XCTest
@testable import VercelBar

final class GeistLayoutTests: XCTestCase {
  func testStatusDotAndBadgeMetricsMatchSpec() {
    XCTAssertEqual(Geist.Layout.statusDotSize, 8)
    XCTAssertEqual(Geist.Layout.rowPaddingH, 12)
    XCTAssertEqual(Geist.Layout.rowPaddingV, 8)
    XCTAssertEqual(Geist.Layout.rowSeparatorInset, 12)
    XCTAssertEqual(Geist.Layout.badgePaddingH, 4)
    XCTAssertEqual(Geist.Layout.badgePaddingV, 2)
    XCTAssertEqual(Geist.Layout.badgeCornerRadius, 9999)
  }

  func testPopoverLayoutMatchesRefreshSpec() {
    XCTAssertEqual(Geist.Layout.popoverWidth, 392)
    XCTAssertEqual(Geist.Layout.rowHeight, 82)
    XCTAssertEqual(Geist.Layout.rowExpandedHeight, 166)
    XCTAssertEqual(Geist.Layout.headerHeight, 52)
  }
}
