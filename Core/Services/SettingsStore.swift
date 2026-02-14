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

  @Published var pollingInterval: TimeInterval {
    didSet { defaults.set(pollingInterval, forKey: Keys.pollingInterval) }
  }

  @Published var selectedProjectIds: Set<String> {
    didSet { defaults.set(Array(selectedProjectIds), forKey: Keys.selectedProjectIds) }
  }

  @Published var notifyOnChecksPassed: Bool {
    didSet { defaults.set(notifyOnChecksPassed, forKey: Keys.notifyOnChecksPassed) }
  }

  @Published var notifyOnChecksFailed: Bool {
    didSet { defaults.set(notifyOnChecksFailed, forKey: Keys.notifyOnChecksFailed) }
  }

  @Published var defaultLogLines: Int {
    didSet { defaults.set(defaultLogLines, forKey: Keys.defaultLogLines) }
  }

  private let defaults: UserDefaults
  private let launchAtLoginManager = LaunchAtLoginManager()

  private init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    defaults.register(defaults: [
      Keys.notifyOnReady: true,
      Keys.notifyOnFailed: true,
      Keys.notifyOnChecksPassed: true,
      Keys.notifyOnChecksFailed: true,
      Keys.browserBundleId: "",
      Keys.pollingInterval: 30.0,
      Keys.selectedProjectIds: [],
      Keys.defaultLogLines: 100
    ])

    self.notifyOnReady = defaults.bool(forKey: Keys.notifyOnReady)
    self.notifyOnFailed = defaults.bool(forKey: Keys.notifyOnFailed)
    self.notifyOnChecksPassed = defaults.bool(forKey: Keys.notifyOnChecksPassed)
    self.notifyOnChecksFailed = defaults.bool(forKey: Keys.notifyOnChecksFailed)
    self.browserBundleId = defaults.string(forKey: Keys.browserBundleId) ?? ""
    self.pollingInterval = defaults.double(forKey: Keys.pollingInterval)

    let storedProjects = defaults.array(forKey: Keys.selectedProjectIds) as? [String] ?? []
    self.selectedProjectIds = Set(storedProjects)
    self.defaultLogLines = defaults.integer(forKey: Keys.defaultLogLines)

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
    static let notifyOnChecksPassed = "settings.notifyOnChecksPassed"
    static let notifyOnChecksFailed = "settings.notifyOnChecksFailed"
    static let browserBundleId = "settings.browserBundleId"
    static let launchAtLogin = "settings.launchAtLogin"
    static let pollingInterval = "settings.pollingInterval"
    static let selectedProjectIds = "settings.selectedProjectIds"
    static let defaultLogLines = "settings.defaultLogLines"
  }
}
