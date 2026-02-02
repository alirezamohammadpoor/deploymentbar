import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarController: StatusBarController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    AppInstanceMessenger.shared.startObserving { url in
      OAuthCallbackHandler.shared.handle(url: url)
    }
    statusBarController = StatusBarController()
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else { return }
    guard let bundleId = Bundle.main.bundleIdentifier else {
      OAuthCallbackHandler.shared.handle(url: url)
      return
    }

    let currentPID = ProcessInfo.processInfo.processIdentifier
    let running = AppInstanceChecker.runningApps(for: bundleId)
    let isDuplicate = AppInstanceChecker.isDuplicate(bundleId: bundleId, currentPID: currentPID, runningApps: running)

    if isDuplicate {
      AppInstanceMessenger.shared.post(url: url)
      NSApp.terminate(nil)
      return
    }

    OAuthCallbackHandler.shared.handle(url: url)
  }
}
