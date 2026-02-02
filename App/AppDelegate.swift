import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarController: StatusBarController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    statusBarController = StatusBarController()
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else { return }
    OAuthCallbackHandler.shared.handle(url: url)
  }
}
