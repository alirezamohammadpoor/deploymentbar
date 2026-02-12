import SwiftUI

@main
struct VercelBarApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  init() {
    UpdateManager.shared.start()
  }

  var body: some Scene {
    Settings {
      SettingsView()
    }
  }
}
