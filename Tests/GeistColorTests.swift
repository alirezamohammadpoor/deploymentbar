import AppKit
import XCTest
@testable import VercelBar

final class GeistColorTests: XCTestCase {
  func testBuildingStatusBarColorUsesOrange() {
    guard let color = Geist.Colors.StatusBarIcon.color(for: .building),
          let rgb = color.usingColorSpace(.sRGB) else {
      XCTFail("Expected sRGB color for building status icon")
      return
    }

    XCTAssertEqual(rgb.redComponent, 0xF5 / 255.0, accuracy: 0.001)
    XCTAssertEqual(rgb.greenComponent, 0xA6 / 255.0, accuracy: 0.001)
    XCTAssertEqual(rgb.blueComponent, 0x23 / 255.0, accuracy: 0.001)
    XCTAssertEqual(rgb.alphaComponent, 1.0, accuracy: 0.001)
  }

  func testBuildingStatusTokenUsesOrange() {
    let color = NSColor(Geist.Colors.status(for: .building))
    guard let rgb = color.usingColorSpace(.sRGB) else {
      XCTFail("Expected sRGB color for building status token")
      return
    }

    XCTAssertEqual(rgb.redComponent, 0xF5 / 255.0, accuracy: 0.001)
    XCTAssertEqual(rgb.greenComponent, 0xA6 / 255.0, accuracy: 0.001)
    XCTAssertEqual(rgb.blueComponent, 0x23 / 255.0, accuracy: 0.001)
  }
}
