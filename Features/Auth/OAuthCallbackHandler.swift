import Foundation

final class OAuthCallbackHandler {
  static let shared = OAuthCallbackHandler()

  func handle(url: URL) {
    Task { @MainActor in
      AuthSession.shared.handleCallback(url: url)
    }
  }
}
