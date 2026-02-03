import AppKit
import Foundation

@MainActor
final class BrowserLauncher {
  private let settings: SettingsStore
  private let workspace: NSWorkspace

  init(settings: SettingsStore = .shared, workspace: NSWorkspace = .shared) {
    self.settings = settings
    self.workspace = workspace
  }

  func open(url: URL) {
    let bundleId = settings.browserBundleId
    guard !bundleId.isEmpty else {
      workspace.open(url)
      return
    }

    guard workspace.urlForApplication(withBundleIdentifier: bundleId) != nil else {
      workspace.open(url)
      return
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    process.arguments = ["-b", bundleId, url.absoluteString]
    try? process.run()
  }
}
