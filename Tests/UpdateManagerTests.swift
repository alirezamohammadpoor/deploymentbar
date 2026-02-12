import Combine
import Foundation
import XCTest
@testable import VercelBar

@MainActor
final class UpdateManagerTests: XCTestCase {
  func testCheckForUpdatesDelegatesToService() async {
    let service = MockSparkleUpdateService()
    let manager = UpdateManager(service: service)

    await manager.checkForUpdates()

    XCTAssertEqual(service.checkForUpdatesCallCount, 1)
  }

  func testCheckingStatusMapsToLoadingText() {
    let service = MockSparkleUpdateService()
    let manager = UpdateManager(service: service)

    service.send(.checking)

    XCTAssertEqual(manager.status, .checking)
    XCTAssertTrue(manager.isChecking)
    XCTAssertEqual(manager.statusText, "Checking for updates...")
    XCTAssertEqual(manager.statusLevel, .info)
  }

  func testUpToDateStatusMapsToInfoText() {
    let service = MockSparkleUpdateService()
    let manager = UpdateManager(service: service)

    service.send(.upToDate)

    XCTAssertEqual(manager.status, .upToDate)
    XCTAssertEqual(manager.statusText, "You are up to date.")
    XCTAssertEqual(manager.statusLevel, .info)
  }

  func testUpdateFoundStatusMapsToSuccessText() {
    let service = MockSparkleUpdateService()
    let manager = UpdateManager(service: service)

    service.send(.updateInitiated(version: "1.0.2"))

    XCTAssertEqual(manager.status, .updateInitiated)
    XCTAssertEqual(manager.statusText, "Update found (1.0.2). Follow Sparkle prompts to install.")
    XCTAssertEqual(manager.statusLevel, .success)
  }

  func testFailureStatusMapsToErrorText() {
    let service = MockSparkleUpdateService()
    let manager = UpdateManager(service: service)

    service.send(.failed(message: "Network timeout"))

    XCTAssertEqual(manager.status, .failed)
    XCTAssertEqual(manager.statusText, "Update check failed: Network timeout")
    XCTAssertEqual(manager.statusLevel, .error)
  }
}

@MainActor
private final class MockSparkleUpdateService: SparkleUpdateServicing {
  private let subject = CurrentValueSubject<SparkleUpdateState, Never>(.idle)
  private(set) var checkForUpdatesCallCount = 0
  private(set) var startCallCount = 0

  var status: SparkleUpdateState { subject.value }
  var statusPublisher: AnyPublisher<SparkleUpdateState, Never> { subject.eraseToAnyPublisher() }

  func start() {
    startCallCount += 1
  }

  func checkForUpdates() {
    checkForUpdatesCallCount += 1
  }

  func send(_ state: SparkleUpdateState) {
    subject.send(state)
  }
}
