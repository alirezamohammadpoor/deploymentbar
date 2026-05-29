import AppKit
import SwiftUI

@MainActor
final class UpdateWindowController {
  static let shared = UpdateWindowController()

  private var window: NSWindow?

  private init() {}

  func show() {
    if let window {
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let view = UpdateView(onSeeWhatsNew: { UpdateWindowController.openReleases() })
    let hosting = NSHostingController(rootView: view)
    let window = NSWindow(contentViewController: hosting)
    window.title = "Software Update"
    window.styleMask = [.titled, .closable]
    window.setContentSize(NSSize(width: 560, height: 440))
    window.isReleasedWhenClosed = false
    window.center()
    self.window = window

    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: window,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in self?.window = nil }
    }

    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  static func openReleases() {
    if let url = URL(string: "https://github.com/alirezamohammadpoor/deploymentbar/releases/latest") {
      NSWorkspace.shared.open(url)
    }
  }
}
