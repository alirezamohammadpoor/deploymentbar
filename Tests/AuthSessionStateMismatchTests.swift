import XCTest
@testable import VercelBar

final class AuthSessionStateMismatchTests: XCTestCase {
  func testMissingCode() {
    let message = AuthSession.stateMismatchMessage(expected: "expected", received: "received", code: nil)
    XCTAssertEqual(message, "OAuth state mismatch (missing code)")
  }

  func testMissingState() {
    let message = AuthSession.stateMismatchMessage(expected: "expected", received: nil, code: "code")
    XCTAssertEqual(message, "OAuth state mismatch (missing state)")
  }

  func testIncludesExpectedAndReceived() {
    let message = AuthSession.stateMismatchMessage(expected: "expected", received: "received", code: "code")
    XCTAssertEqual(message, "OAuth state mismatch (expected expected, got received)")
  }

  func testNilExpected() {
    let message = AuthSession.stateMismatchMessage(expected: nil, received: "received", code: "code")
    XCTAssertEqual(message, "OAuth state mismatch (expected nil, got received)")
  }
}
