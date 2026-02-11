import AppKit
import XCTest
@testable import VercelBar

final class GeistColorTests: XCTestCase {
  func testBuildingStatusBarColorUsesVercelBlue() {
    guard let color = Geist.Colors.StatusBarIcon.color(for: .building),
          let rgb = color.usingColorSpace(.sRGB) else {
      XCTFail("Expected sRGB color for building status icon")
      return
    }

    XCTAssertEqual(rgb.redComponent, 0.0, accuracy: 0.001)
    XCTAssertEqual(rgb.greenComponent, 0x70 / 255.0, accuracy: 0.001)
    XCTAssertEqual(rgb.blueComponent, 0xF3 / 255.0, accuracy: 0.001)
    XCTAssertEqual(rgb.alphaComponent, 1.0, accuracy: 0.001)
  }
}
