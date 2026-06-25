import XCTest
@testable import VercelBar

final class AppInstanceCoordinatorTests: XCTestCase {
  func testPrimaryInstanceAcquiresLock() {
    let coordinator = AppInstanceCoordinator(lockProvider: FakeLockProvider(lock: FakeLock()))
    XCTAssertTrue(coordinator.startPrimaryIfPossible())
  }

  func testSecondaryInstanceFailsToAcquireLock() {
    let coordinator = AppInstanceCoordinator(lockProvider: FakeLockProvider(lock: nil))
    XCTAssertFalse(coordinator.startPrimaryIfPossible())
  }

  func testStartIsIdempotentForPrimary() {
    let coordinator = AppInstanceCoordinator(lockProvider: FakeLockProvider(lock: FakeLock()))
    XCTAssertTrue(coordinator.startPrimaryIfPossible())
    XCTAssertTrue(coordinator.startPrimaryIfPossible())
  }
}

private final class FakeLockProvider: AppInstanceLockProviding {
  private let lock: AppInstanceLockToken?

  init(lock: AppInstanceLockToken?) {
    self.lock = lock
  }

  func acquire() -> AppInstanceLockToken? {
    lock
  }
}

private final class FakeLock: AppInstanceLockToken {}
