import AppKit

struct BrowserOption: Identifiable, Equatable {
  let id: String
  let displayName: String

  static var defaultOption: BrowserOption {
    BrowserOption(id: "", displayName: "System Default")
  }

  static func availableOptions(workspace: NSWorkspace = .shared) -> [BrowserOption] {
    var options: [BrowserOption] = [defaultOption]
    for bundleId in knownBrowsers {
      guard let appURL = workspace.urlForApplication(withBundleIdentifier: bundleId) else { continue }
      let name = Bundle(url: appURL)?.object(forInfoDictionaryKey: "CFBundleName") as? String
      options.append(BrowserOption(id: bundleId, displayName: name ?? bundleId))
    }
    return options
  }

  private static var knownBrowsers: [String] {
    [
      "com.apple.Safari",
      "com.apple.SafariTechnologyPreview",
      "com.google.Chrome",
      "com.google.Chrome.canary",
      "org.mozilla.firefox",
      "org.mozilla.nightly",
      "com.microsoft.edgemac",
      "com.brave.Browser",
      "com.operasoftware.Opera",
      "com.vivaldi.Vivaldi"
    ]
  }
}
