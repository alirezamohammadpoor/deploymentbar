import Foundation

final class OAuthCallbackHandler {
  static let shared = OAuthCallbackHandler()

  func handle(url: URL) {
    // TODO: parse code/state and complete auth flow.
  }
}
