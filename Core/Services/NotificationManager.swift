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
      DebugLog.write("Notification authorization status: \(settings.authorizationStatus.rawValue)")
      guard settings.authorizationStatus == .notDetermined else { return }
      self?.center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        DebugLog.write("Notification authorization granted=\(granted) error=\(String(describing: error))")
      }
    }
  }

  func postDeploymentNotification(deployment: Deployment) {
    Task { @MainActor in
      DebugLog.write("postDeploymentNotification: \(deployment.projectName) state=\(deployment.state.rawValue)")

      guard shouldNotify(for: deployment.state) else {
        DebugLog.write("postDeploymentNotification: skipped by settings (notifyOnReady=\(settings.notifyOnReady), notifyOnFailed=\(settings.notifyOnFailed))")
        return
      }
      guard historyStore.shouldNotify(id: deployment.id, state: deployment.state) else {
        DebugLog.write("postDeploymentNotification: skipped by history (already notified)")
        return
      }

      let authStatus = await center.notificationSettings().authorizationStatus
      guard authStatus == .authorized || authStatus == .provisional else {
        DebugLog.write("postDeploymentNotification: not authorized (status=\(authStatus.rawValue)), requesting authorization")
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
          DebugLog.write("postDeploymentNotification: authorization result granted=\(granted) error=\(String(describing: error))")
        }
        return
      }

      let content = UNMutableNotificationContent()
      content.title = deployment.projectName
      content.body = deployment.state == .ready
        ? "Deployment ready"
        : "Deployment failed"
      content.sound = .default

      if let url = deployment.url {
        content.userInfo["url"] = url
      }

      let request = UNNotificationRequest(
        identifier: "vercelbar.deployment.\(deployment.id).\(deployment.state.rawValue)",
        content: content,
        trigger: nil
      )

      center.add(request) { [weak self] error in
        if let error {
          DebugLog.write("postDeploymentNotification: center.add failed: \(error)")
          return
        }
        DebugLog.write("postDeploymentNotification: notification posted for \(deployment.projectName)")
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
