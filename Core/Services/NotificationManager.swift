import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
  private let center = UNUserNotificationCenter.current()
  private let browserLauncher: BrowserLauncher
  private let settings: SettingsStore
  private let historyStore: NotificationHistoryStore

  init(browserLauncher: BrowserLauncher, settings: SettingsStore, historyStore: NotificationHistoryStore = NotificationHistoryStore()) {
    self.browserLauncher = browserLauncher
    self.settings = settings
    self.historyStore = historyStore
  }

  func configure() {
    center.delegate = self
  }

  func requestAuthorizationIfNeeded() {
    center.getNotificationSettings { [weak self] settings in
      guard settings.authorizationStatus == .notDetermined else { return }
      self?.center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
  }

  func postDeploymentNotification(deployment: Deployment) {
    Task { @MainActor in
      guard shouldNotify(for: deployment.state) else { return }
      guard historyStore.shouldNotify(id: deployment.id, state: deployment.state) else { return }

      let content = UNMutableNotificationContent()
      content.title = deployment.projectName
      content.body = deployment.state == .ready
        ? "Deployment ready"
        : "Deployment failed"

      if let url = deployment.url {
        content.userInfo["url"] = url
      }

      let request = UNNotificationRequest(
        identifier: "vercelbar.deployment.\(deployment.id).\(deployment.state.rawValue)",
        content: content,
        trigger: nil
      )

      center.add(request) { [weak self] error in
        guard error == nil else { return }
        self?.historyStore.markNotified(id: deployment.id, state: deployment.state)
      }
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let urlValue = response.notification.request.content.userInfo["url"] as? String,
       let url = URL(string: urlValue) ?? URL(string: "https://\(urlValue)") {
      Task { @MainActor in
        browserLauncher.open(url: url)
      }
    }
    completionHandler()
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .sound])
  }

  @MainActor
  private func shouldNotify(for state: DeploymentState) -> Bool {
    switch state {
    case .ready:
      return settings.notifyOnReady
    case .error:
      return settings.notifyOnFailed
    case .building, .canceled:
      return false
    }
  }
}
