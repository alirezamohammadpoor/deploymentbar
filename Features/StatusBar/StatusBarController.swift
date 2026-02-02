import AppKit
import SwiftUI

final class StatusBarController: NSObject {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let popover = NSPopover()
  private let browserLauncher = BrowserLauncher()

  override init() {
    super.init()

    if let button = statusItem.button {
      button.image = NSImage(systemSymbolName: "bolt.horizontal", accessibilityDescription: "VercelBar")
      button.image?.isTemplate = true
      button.target = self
      button.action = #selector(togglePopover(_:))
    }

    popover.behavior = .transient
    popover.contentViewController = NSHostingController(
      rootView: StatusBarMenu(
        deployments: StatusBarMenu.mockDeployments,
        openURL: { [weak self] url in
          self?.browserLauncher.open(url: url)
        }
      )
    )
  }

  @objc private func togglePopover(_ sender: Any?) {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      popover.performClose(sender)
    } else {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}
