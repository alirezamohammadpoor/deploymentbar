import XCTest
@testable import VercelBar

final class OAuthErrorParserTests: XCTestCase {
  func testParsesOAuthErrorDescription() {
    let json = #"{"error":"invalid_grant","error_description":"Invalid code"}"#.data(using: .utf8)!
    let message = OAuthErrorParser.parseMessage(data: json, statusCode: 400)
    XCTAssertEqual(message, "invalid_grant: Invalid code")
  }

  func testFormatsFallbackMessageForNonOAuthPayload() {
    let json = #"{"message":"oops"}"#.data(using: .utf8)!
    let message = OAuthErrorParser.parseMessage(data: json, statusCode: 400)
    XCTAssertEqual(message, "OAuth error (HTTP 400): {\"message\":\"oops\"}")
  }

  func testFormatsFallbackMessageForEmptyBody() {
    let message = OAuthErrorParser.parseMessage(data: Data(), statusCode: 500)
    XCTAssertEqual(message, "OAuth error (HTTP 500)")
  }
}
