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

    guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId) else {
      workspace.open(url)
      return
    }

    let configuration = NSWorkspace.OpenConfiguration()
    workspace.open([url], withApplicationAt: appURL, configuration: configuration, completionHandler: nil)
  }
}
