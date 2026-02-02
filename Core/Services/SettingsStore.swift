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

  private let defaults: UserDefaults

  private init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    defaults.register(defaults: [
      Keys.notifyOnReady: true,
      Keys.notifyOnFailed: true
    ])

    self.notifyOnReady = defaults.bool(forKey: Keys.notifyOnReady)
    self.notifyOnFailed = defaults.bool(forKey: Keys.notifyOnFailed)
  }

  private enum Keys {
    static let notifyOnReady = "settings.notifyOnReady"
    static let notifyOnFailed = "settings.notifyOnFailed"
  }
}
