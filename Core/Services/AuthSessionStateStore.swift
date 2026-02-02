import Foundation

struct AuthSessionStateStore {
  struct Pending: Equatable {
    let state: String
    let verifier: String
    let redirectURI: String
  }

  private let defaults: UserDefaults
  private let stateKey = "vercelbar.oauth.state"
  private let verifierKey = "vercelbar.oauth.verifier"
  private let redirectKey = "vercelbar.oauth.redirect"

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  func save(_ pending: Pending) {
    defaults.set(pending.state, forKey: stateKey)
    defaults.set(pending.verifier, forKey: verifierKey)
    defaults.set(pending.redirectURI, forKey: redirectKey)
  }

  func load() -> Pending? {
    guard let state = defaults.string(forKey: stateKey),
          let verifier = defaults.string(forKey: verifierKey),
          let redirectURI = defaults.string(forKey: redirectKey) else {
      return nil
    }
    return Pending(state: state, verifier: verifier, redirectURI: redirectURI)
  }

  func clear() {
    defaults.removeObject(forKey: stateKey)
    defaults.removeObject(forKey: verifierKey)
    defaults.removeObject(forKey: redirectKey)
  }
}
