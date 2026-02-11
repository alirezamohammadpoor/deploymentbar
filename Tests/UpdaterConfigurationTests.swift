import XCTest
@testable import VercelBar

final class UpdaterConfigurationTests: XCTestCase {
  func testReturnsNilWhenFeedURLMissing() {
    let config = UpdaterConfiguration.from(infoDictionary: [:])
    XCTAssertNil(config)
  }

  func testReturnsNilWhenFeedURLInvalid() {
    let config = UpdaterConfiguration.from(infoDictionary: [
      "SUFeedURL": "not-a-url"
    ])
    XCTAssertNil(config)
  }

  func testParsesFeedURLAndOptionalKey() {
    let config = UpdaterConfiguration.from(infoDictionary: [
      "SUFeedURL": "https://updates.example.com/appcast.xml",
      "SUPublicEDKey": " abc123 "
    ])

    XCTAssertEqual(config?.feedURL.absoluteString, "https://updates.example.com/appcast.xml")
    XCTAssertEqual(config?.publicEDKey, "abc123")
  }
}
