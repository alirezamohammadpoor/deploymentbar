import Foundation

protocol AppInstanceLockProviding {
  func acquire() -> AppInstanceLockToken?
}

struct DefaultAppInstanceLockProvider: AppInstanceLockProviding {
  func acquire() -> AppInstanceLockToken? {
    AppInstanceLock.acquire()
  }
}

final class AppInstanceCoordinator {
  private let lockProvider: AppInstanceLockProviding
  private var lock: AppInstanceLockToken?
  private var isSecondary = false

  init(lockProvider: AppInstanceLockProviding) {
    self.lockProvider = lockProvider
  }

  func startPrimaryIfPossible() -> Bool {
    if lock != nil {
      return !isSecondary
    }

    lock = lockProvider.acquire()
    if lock == nil {
      isSecondary = true
    }
    return !isSecondary
  }
}
