import Foundation

@MainActor
final class SettingsStore: ObservableObject {
  static let shared = SettingsStore()

  @Published var notifyOnReady: Bool {
    didSet { defaults.set(notifyOnReady, forKey: Keys.notifyOnReady) }
  }

  @Published var notifyOnFailed: Bool {
    didSet { defaults.set(notifyOnFailed, forKey: Keys.notifyOnFailed) }
  }

  @Published var browserBundleId: String {
    didSet { defaults.set(browserBundleId, forKey: Keys.browserBundleId) }
  }

  @Published var launchAtLogin: Bool {
    didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
  }

  private let defaults: UserDefaults
  private let launchAtLoginManager = LaunchAtLoginManager()

  private init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    defaults.register(defaults: [
      Keys.notifyOnReady: true,
      Keys.notifyOnFailed: true,
      Keys.browserBundleId: ""
    ])

    self.notifyOnReady = defaults.bool(forKey: Keys.notifyOnReady)
    self.notifyOnFailed = defaults.bool(forKey: Keys.notifyOnFailed)
    self.browserBundleId = defaults.string(forKey: Keys.browserBundleId) ?? ""

    if let storedLaunch = defaults.object(forKey: Keys.launchAtLogin) as? Bool {
      self.launchAtLogin = storedLaunch
    } else {
      let systemEnabled = launchAtLoginManager.isEnabled()
      self.launchAtLogin = systemEnabled
      defaults.set(systemEnabled, forKey: Keys.launchAtLogin)
    }
  }

  private enum Keys {
    static let notifyOnReady = "settings.notifyOnReady"
    static let notifyOnFailed = "settings.notifyOnFailed"
    static let browserBundleId = "settings.browserBundleId"
    static let launchAtLogin = "settings.launchAtLogin"
  }
}
