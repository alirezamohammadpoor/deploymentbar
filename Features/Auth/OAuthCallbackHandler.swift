import Foundation

final class OAuthCallbackHandler {
  static let shared = OAuthCallbackHandler()

  func handle(url: URL) {
    AuthSession.shared.handleCallback(url: url)
  }
}
