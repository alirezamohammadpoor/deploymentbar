import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    // TODO: wire StatusBarController, NotificationManager delegate, and Auth handling.
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    // TODO: forward OAuth callback URLs to OAuthCallbackHandler.
  }
}
