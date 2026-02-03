import XCTest
@testable import VercelBar

final class AppInstanceCoordinatorTests: XCTestCase {
  func testPrimaryInstanceHandlesURL() {
    let lockProvider = FakeLockProvider(lock: FakeLock())
    let messenger = FakeMessenger()
    let coordinator = AppInstanceCoordinator(lockProvider: lockProvider, messenger: messenger)
    let url = URL(string: "vercelbar://oauth/callback")!
    var didForward = false
    var didHandle = false

    coordinator.handleOpenURL(url, onForward: { didForward = true }, onHandle: { didHandle = true })

    XCTAssertFalse(didForward)
    XCTAssertTrue(didHandle)
    XCTAssertTrue(messenger.postedURLs.isEmpty)
  }

  func testSecondaryInstanceForwardsURL() {
    let lockProvider = FakeLockProvider(lock: nil)
    let messenger = FakeMessenger()
    let coordinator = AppInstanceCoordinator(lockProvider: lockProvider, messenger: messenger)
    let url = URL(string: "vercelbar://oauth/callback")!
    var didForward = false
    var didHandle = false

    coordinator.handleOpenURL(url, onForward: { didForward = true }, onHandle: { didHandle = true })

    XCTAssertTrue(didForward)
    XCTAssertFalse(didHandle)
    XCTAssertEqual(messenger.postedURLs, [url])
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

private final class FakeMessenger: AppInstanceMessaging {
  private(set) var postedURLs: [URL] = []

  func post(url: URL) {
    postedURLs.append(url)
  }
}
