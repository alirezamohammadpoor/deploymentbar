import AppKit
import Foundation

enum URLSchemeRegistrar {
  static func registerCurrentBundle() -> Bool {
    let url = Bundle.main.bundleURL
    return register(bundleURL: url)
  }

  static func register(bundleURL: URL) -> Bool {
    guard shouldRegister(bundleURL: bundleURL) else { return false }
    return LSRegisterURL(bundleURL as CFURL, true) == noErr
  }

  static func shouldRegister(bundleURL: URL) -> Bool {
    bundleURL.pathExtension.lowercased() == "app"
  }
}
