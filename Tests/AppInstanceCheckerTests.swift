import XCTest
@testable import VercelBar

final class AppInstanceCheckerTests: XCTestCase {
  func testDetectsDuplicate() {
    let bundleId = "com.example.VercelBar"
    let currentPID: pid_t = 100
    let runningApps = [
      AppInstanceChecker.RunningApp(bundleIdentifier: bundleId, processIdentifier: 100),
      AppInstanceChecker.RunningApp(bundleIdentifier: bundleId, processIdentifier: 200)
    ]

    XCTAssertTrue(AppInstanceChecker.isDuplicate(bundleId: bundleId, currentPID: currentPID, runningApps: runningApps))
  }

  func testDetectsSingleInstance() {
    let bundleId = "com.example.VercelBar"
    let currentPID: pid_t = 100
    let runningApps = [
      AppInstanceChecker.RunningApp(bundleIdentifier: bundleId, processIdentifier: 100)
    ]

    XCTAssertFalse(AppInstanceChecker.isDuplicate(bundleId: bundleId, currentPID: currentPID, runningApps: runningApps))
  }
}
