import Foundation

final class AppInstanceMessenger {
  static let shared = AppInstanceMessenger()

  private let center = DistributedNotificationCenter.default()
  private let name = Notification.Name("vercelbar.oauth.callback")

  private init() {}

  func startObserving(handler: @escaping (URL) -> Void) {
    center.addObserver(
      forName: name,
      object: nil,
      queue: .main
    ) { notification in
      guard let payload = notification.userInfo?["url"] as? String,
            let url = URL(string: payload) else {
        return
      }
      handler(url)
    }
  }

  func post(url: URL) {
    center.post(name: name, object: nil, userInfo: ["url": url.absoluteString])
  }
}
