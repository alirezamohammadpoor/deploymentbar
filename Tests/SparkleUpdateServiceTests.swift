import XCTest
@testable import VercelBar

@MainActor
final class SparkleUpdateServiceTests: XCTestCase {
  func testCheckForUpdatesStartsCheckingAndCallsDriver() {
    let driver = MockSparkleDriver()
    let service = SparkleUpdateService(driver: driver)

    service.checkForUpdates()

    XCTAssertEqual(service.status, .checking)
    XCTAssertEqual(driver.checkForUpdatesCallCount, 1)
  }

  func testStartCallsDriver() {
    let driver = MockSparkleDriver()
    let service = SparkleUpdateService(driver: driver)

    service.start()

    XCTAssertEqual(driver.startCallCount, 1)
  }

  func testDidFindUpdateTransitionsToUpdateInitiated() {
    let driver = MockSparkleDriver()
    let service = SparkleUpdateService(driver: driver)

    driver.emit(.didFindUpdate(version: "1.0.2"))

    XCTAssertEqual(service.status, .updateInitiated(version: "1.0.2"))
  }

  func testDidNotFindUpdateTransitionsToUpToDate() {
    let driver = MockSparkleDriver()
    let service = SparkleUpdateService(driver: driver)

    driver.emit(.didNotFindUpdate)

    XCTAssertEqual(service.status, .upToDate)
  }

  func testDidFailTransitionsToFailed() {
    let driver = MockSparkleDriver()
    let service = SparkleUpdateService(driver: driver)

    driver.emit(.didFail(message: "Signature check failed"))

    XCTAssertEqual(service.status, .failed(message: "Signature check failed"))
  }
}

@MainActor
private final class MockSparkleDriver: SparkleUpdateDriving {
  var onEvent: ((SparkleUpdateEvent) -> Void)?
  private(set) var startCallCount = 0
  private(set) var checkForUpdatesCallCount = 0

  func start() {
    startCallCount += 1
  }

  func checkForUpdates() {
    checkForUpdatesCallCount += 1
  }

  func emit(_ event: SparkleUpdateEvent) {
    onEvent?(event)
  }
}
