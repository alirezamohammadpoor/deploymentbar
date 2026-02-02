import Foundation

final class RefreshEngine {
  private(set) var interval: TimeInterval

  init(interval: TimeInterval = 30.0) {
    self.interval = interval
  }

  func start() {
    // TODO: schedule polling timer and handle backoff.
  }

  func stop() {
    // TODO: cancel polling.
  }

  func triggerImmediateRefresh() {
    // TODO: cancel current task and refresh now.
  }
}
