import XCTest
@testable import VercelBar

final class DebugLogTests: XCTestCase {
  override func tearDown() {
    DebugLog.setLogPathForTesting(nil)
    DebugLog.clear()
    super.tearDown()
  }

  func testWriteIncludesLevelAndComponent() {
    let logPath = tempLogPath(named: "DebugLogTests-\(UUID().uuidString).log")
    DebugLog.setLogPathForTesting(logPath)
    DebugLog.clear()

    DebugLog.write("hello world", level: .info, component: "tests")
    DebugLog.flush()

    let contents = (try? String(contentsOfFile: logPath, encoding: .utf8)) ?? ""
    XCTAssertTrue(contents.contains("[INFO] [tests] hello world"))
  }

  func testRotateWhenLogExceedsMaxSize() {
    let logPath = tempLogPath(named: "DebugLogTests-\(UUID().uuidString).log")
    DebugLog.setLogPathForTesting(logPath)
    DebugLog.clear()

    let oversizedData = Data(count: 1_000_000)
    FileManager.default.createFile(atPath: logPath, contents: oversizedData)

    DebugLog.write("after-rotation", level: .warn, component: "rotation")
    DebugLog.flush()

    XCTAssertTrue(FileManager.default.fileExists(atPath: "\(logPath).1"))
    let activeContents = (try? String(contentsOfFile: logPath, encoding: .utf8)) ?? ""
    XCTAssertTrue(activeContents.contains("after-rotation"))
  }

  private func tempLogPath(named name: String) -> String {
    FileManager.default.temporaryDirectory.appendingPathComponent(name).path
  }
}
