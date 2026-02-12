import AppKit
import SwiftUI

@MainActor
final class BuildLogWindowController {
  static let shared = BuildLogWindowController()

  private var windows: [String: NSWindow] = [:]

  private init() {}

  func showLogs(for deployment: Deployment, openURL: @escaping (URL) -> Void) {
    // Check if window already exists for this deployment
    if let existingWindow = windows[deployment.id] {
      existingWindow.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
      return
    }

    // Create the log view
    let logView = BuildLogWindow(
      deploymentId: deployment.id,
      projectName: deployment.projectName,
      openURL: openURL
    )

    // Create the hosting controller
    let hostingController = NSHostingController(rootView: logView)

    // Create the window
    let window = NSWindow(contentViewController: hostingController)
    window.title = "\(deployment.projectName) — Build Log"
    window.setContentSize(NSSize(width: 600, height: 500))
    window.minSize = NSSize(width: 400, height: 300)
    window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
    window.isReleasedWhenClosed = false
    window.center()

    // Store reference
    windows[deployment.id] = window

    // Clean up on close
    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: window,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.windows.removeValue(forKey: deployment.id)
      }
    }

    // Show the window
    window.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}
