import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {
  static let shared = OnboardingWindowController()

  private var window: NSWindow?

  private init() {}

  func show() {
    if let window {
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    let view = OnboardingView(
      onClose: { [weak self] in self?.close() },
      openSettings: { OnboardingWindowController.openSettings() }
    )
    let hosting = NSHostingController(rootView: view)
    let window = NSWindow(contentViewController: hosting)
    window.title = "Welcome to Deploymentbar"
    window.styleMask = [.titled, .closable]
    window.setContentSize(NSSize(width: 480, height: 560))
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

  private func close() {
    window?.close()
    window = nil
  }

  /// Opens the SwiftUI Settings scene from AppKit (macOS 14+).
  static func openSettings() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
  }
}
