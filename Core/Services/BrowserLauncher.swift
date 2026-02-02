import AppKit
import Foundation

final class BrowserLauncher {
  func open(url: URL) {
    NSWorkspace.shared.open(url)
  }
}
