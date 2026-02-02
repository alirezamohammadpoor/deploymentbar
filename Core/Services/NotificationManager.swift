import Foundation
import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
  private let center = UNUserNotificationCenter.current()
  private let browserLauncher: BrowserLauncher

  init(browserLauncher: BrowserLauncher) {
    self.browserLauncher = browserLauncher
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
    guard deployment.state == .ready || deployment.state == .error else { return }

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

    center.add(request)
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let urlValue = response.notification.request.content.userInfo["url"] as? String,
       let url = URL(string: urlValue) ?? URL(string: "https://\(urlValue)") {
      browserLauncher.open(url: url)
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
}
