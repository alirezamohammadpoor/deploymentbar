import Foundation

protocol AppInstanceLockProviding {
  func acquire() -> AppInstanceLockToken?
}

struct DefaultAppInstanceLockProvider: AppInstanceLockProviding {
  func acquire() -> AppInstanceLockToken? {
    AppInstanceLock.acquire()
  }
}

protocol AppInstanceMessaging {
  func post(url: URL)
}

extension AppInstanceMessenger: AppInstanceMessaging {}

final class AppInstanceCoordinator {
  private let lockProvider: AppInstanceLockProviding
  private let messenger: AppInstanceMessaging
  private var lock: AppInstanceLockToken?
  private var isSecondary = false

  init(lockProvider: AppInstanceLockProviding, messenger: AppInstanceMessaging) {
    self.lockProvider = lockProvider
    self.messenger = messenger
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

  func handleOpenURL(_ url: URL, onForward: () -> Void, onHandle: () -> Void) {
    if !startPrimaryIfPossible() {
      messenger.post(url: url)
      onForward()
      return
    }

    onHandle()
  }
}
