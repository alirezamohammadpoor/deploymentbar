import SwiftUI

@main
struct VercelBarApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

  var body: some Scene {
    Settings {
      Text("VercelBar")
    }
  }
}
