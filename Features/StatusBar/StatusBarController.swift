import AppKit
import SwiftUI

final class StatusBarController: NSObject {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let popover = NSPopover()

  override init() {
    super.init()
    // TODO: configure statusItem button and popover content.
  }

  @objc private func togglePopover(_ sender: Any?) {
    // TODO: implement popover toggle.
  }
}
