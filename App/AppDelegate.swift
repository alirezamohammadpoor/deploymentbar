import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarController: StatusBarController?
  private var instanceLock: AppInstanceLock?
  private var isSecondaryInstance = false

  func applicationDidFinishLaunching(_ notification: Notification) {
    instanceLock = AppInstanceLock.acquire()
    if instanceLock == nil {
      isSecondaryInstance = true
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        NSApp.terminate(nil)
      }
      return
    }

    AppInstanceMessenger.shared.startObserving { url in
      OAuthCallbackHandler.shared.handle(url: url)
    }
    statusBarController = StatusBarController()
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else { return }
    if isSecondaryInstance {
      AppInstanceMessenger.shared.post(url: url)
      NSApp.terminate(nil)
      return
    }

    OAuthCallbackHandler.shared.handle(url: url)
  }
}
