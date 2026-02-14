import AppKit
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
    Task { @MainActor in
      let settings = await center.notificationSettings()
      DebugLog.write("Notification authorization status: \(settings.authorizationStatus.rawValue)")
      guard settings.authorizationStatus == .notDetermined else { return }
      // Activate the app briefly so macOS shows the permission dialog
      // (LSUIElement apps may not show it otherwise)
      NSApp.activate(ignoringOtherApps: true)
      do {
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        DebugLog.write("Notification authorization granted=\(granted)")
      } catch {
        DebugLog.write("Notification authorization error=\(error)")
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
      if authStatus == .notDetermined {
        DebugLog.write("postDeploymentNotification: not determined, requesting authorization")
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        DebugLog.write("postDeploymentNotification: authorization result granted=\(String(describing: granted))")
        guard granted == true else { return }
      } else if authStatus != .authorized && authStatus != .provisional {
        DebugLog.write("postDeploymentNotification: not authorized (status=\(authStatus.rawValue))")
        return
      }

      let content = UNMutableNotificationContent()
      content.title = deployment.projectName
      content.body = deployment.state == .ready
        ? "Deployment ready"
        : "Deployment failed"
      content.sound = .default

      if let rawURL = deployment.url, !rawURL.isEmpty {
        if let parsed = URL(string: rawURL), parsed.scheme != nil {
          content.userInfo["url"] = rawURL
        } else {
          content.userInfo["url"] = "https://\(rawURL)"
        }
      }

      let request = UNNotificationRequest(
        identifier: "vercelbar.deployment.\(deployment.id).\(deployment.state.rawValue)",
        content: content,
        trigger: nil
      )

      do {
        try await center.add(request)
        DebugLog.write("postDeploymentNotification: notification posted for \(deployment.projectName)")
        historyStore.markNotified(id: deployment.id, state: deployment.state)
      } catch {
        DebugLog.write("postDeploymentNotification: center.add failed: \(error)")
      }
    }
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let urlValue = response.notification.request.content.userInfo["url"] as? String,
       !urlValue.isEmpty {
      let url: URL?
      if let parsed = URL(string: urlValue), parsed.scheme != nil {
        url = parsed
      } else {
        url = URL(string: "https://\(urlValue)")
      }
      if let url {
        Task { @MainActor in
          browserLauncher.open(url: url)
        }
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

  func postCheckNotification(deployment: Deployment, status: AggregateCheckStatus) {
    Task { @MainActor in
      DebugLog.write("postCheckNotification: \(deployment.projectName) status=\(status)")

      guard status == .passed || status == .failed else { return }

      let allowed: Bool
      switch status {
      case .passed: allowed = settings.notifyOnChecksPassed
      case .failed: allowed = settings.notifyOnChecksFailed
      default: allowed = false
      }
      guard allowed else {
        DebugLog.write("postCheckNotification: skipped by settings")
        return
      }

      let checkKey = "check-\(deployment.id)"
      let pseudoState: DeploymentState = status == .passed ? .ready : .error
      guard historyStore.shouldNotify(id: checkKey, state: pseudoState) else {
        DebugLog.write("postCheckNotification: skipped by history (already notified)")
        return
      }

      let authStatus = await center.notificationSettings().authorizationStatus
      guard authStatus == .authorized || authStatus == .provisional else {
        DebugLog.write("postCheckNotification: not authorized (status=\(authStatus.rawValue))")
        return
      }

      let content = UNMutableNotificationContent()
      content.title = deployment.projectName
      content.body = status == .passed
        ? "All CI checks passed"
        : "CI checks failed"
      content.sound = .default

      // Prefer PR URL, fall back to deployment URL
      if let prURL = deployment.prURL {
        content.userInfo["url"] = prURL.absoluteString
      } else if let rawURL = deployment.url, !rawURL.isEmpty {
        if let parsed = URL(string: rawURL), parsed.scheme != nil {
          content.userInfo["url"] = rawURL
        } else {
          content.userInfo["url"] = "https://\(rawURL)"
        }
      }

      let statusLabel = status == .passed ? "passed" : "failed"
      let request = UNNotificationRequest(
        identifier: "vercelbar.check.\(deployment.id).\(statusLabel)",
        content: content,
        trigger: nil
      )

      do {
        try await center.add(request)
        DebugLog.write("postCheckNotification: notification posted for \(deployment.projectName)")
        historyStore.markNotified(id: checkKey, state: pseudoState)
      } catch {
        DebugLog.write("postCheckNotification: center.add failed: \(error)")
      }
    }
  }

  @MainActor
  private func shouldNotify(for state: DeploymentState) -> Bool {
    switch state {
    case .ready:
      return settings.notifyOnReady
    case .error:
      return settings.notifyOnFailed
    case .building, .canceled, .queued:
      return false
    }
  }
}
