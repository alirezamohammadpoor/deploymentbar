import XCTest
@testable import VercelBar

final class TokenResponseParserTests: XCTestCase {
  func testParsesJSONResponse() {
    let json = """
    {\"access_token\":\"token\",\"refresh_token\":\"refresh\",\"expires_in\":3600}
    """.data(using: .utf8)!

    let parsed = TokenResponseParser.parse(data: json)

    XCTAssertEqual(parsed, .init(accessToken: "token", refreshToken: "refresh", expiresIn: 3600))
  }

  func testParsesFormResponse() {
    let body = "access_token=token&refresh_token=refresh&expires_in=3600".data(using: .utf8)!

    let parsed = TokenResponseParser.parse(data: body)

    XCTAssertEqual(parsed, .init(accessToken: "token", refreshToken: "refresh", expiresIn: 3600))
  }
}
