import XCTest
@testable import VercelBar

final class TokenPairTests: XCTestCase {
  func testDoesNotRefreshWithoutRefreshToken() {
    let tokens = TokenPair(
      accessToken: "access",
      refreshToken: nil,
      expiresAt: Date().addingTimeInterval(30)
    )

    XCTAssertFalse(tokens.canRefresh)
    XCTAssertFalse(tokens.shouldRefreshSoon)
  }

  func testRefreshSoonWithRefreshToken() {
    let tokens = TokenPair(
      accessToken: "access",
      refreshToken: "refresh",
      expiresAt: Date().addingTimeInterval(30)
    )

    XCTAssertTrue(tokens.canRefresh)
    XCTAssertTrue(tokens.shouldRefreshSoon)
  }
}
