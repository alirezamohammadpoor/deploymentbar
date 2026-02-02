import XCTest
@testable import VercelBar

final class OAuthErrorParserTests: XCTestCase {
  func testParsesOAuthErrorDescription() {
    let json = #"{"error":"invalid_grant","error_description":"Invalid code"}"#.data(using: .utf8)!
    let message = OAuthErrorParser.parseMessage(data: json)
    XCTAssertEqual(message, "invalid_grant: Invalid code")
  }

  func testReturnsNilForNonOAuthPayload() {
    let json = #"{"message":"oops"}"#.data(using: .utf8)!
    let message = OAuthErrorParser.parseMessage(data: json)
    XCTAssertNil(message)
  }
}
