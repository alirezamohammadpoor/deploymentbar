import Foundation
import Sparkle

@MainActor
final class UpdaterStore: ObservableObject {
  static let shared = UpdaterStore()

  @Published private(set) var isConfigured = false
  @Published private(set) var lastError: String?
  @Published private(set) var feedHost: String?

  var canCheckForUpdates: Bool {
    updaterController?.updater.canCheckForUpdates ?? false
  }

  private let bundle: Bundle
  private let updaterControllerFactory: (SPUUpdaterDelegate?) -> SPUStandardUpdaterController
  private let delegateProxy = UpdaterDelegateProxy()
  private var updaterController: SPUStandardUpdaterController?

  init(
    bundle: Bundle = .main,
    updaterControllerFactory: ((SPUUpdaterDelegate?) -> SPUStandardUpdaterController)? = nil
  ) {
    self.bundle = bundle
    self.updaterControllerFactory = updaterControllerFactory ?? { delegate in
      SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: delegate,
        userDriverDelegate: nil
      )
    }

    delegateProxy.onAbort = { [weak self] error in
      guard let self else { return }
      self.lastError = error.localizedDescription
      DebugLog.write(
        "Sparkle aborted update check: \(error.localizedDescription)",
        level: .warn,
        component: "updater"
      )
    }
  }

  func startIfConfigured() {
    guard updaterController == nil else { return }

    guard let config = UpdaterConfiguration.load(bundle: bundle) else {
      isConfigured = false
      feedHost = nil
      DebugLog.write(
        "Sparkle disabled: SUFeedURL missing or invalid",
        level: .info,
        component: "updater"
      )
      return
    }

    updaterController = updaterControllerFactory(delegateProxy)
    isConfigured = true
    feedHost = config.feedURL.host ?? config.feedURL.absoluteString
    lastError = nil

    DebugLog.write(
      "Sparkle updater started with feed host \(feedHost ?? "unknown")",
      level: .info,
      component: "updater"
    )
  }

  func checkForUpdates() {
    if updaterController == nil {
      startIfConfigured()
    }

    guard let updaterController else {
      lastError = "Updater not configured. Set SUFeedURL / SPARKLE_FEED_URL."
      return
    }

    guard updaterController.updater.canCheckForUpdates else {
      lastError = "Updater is not ready yet. Try again in a moment."
      return
    }

    lastError = nil
    updaterController.checkForUpdates(nil)
  }
}

private final class UpdaterDelegateProxy: NSObject, SPUUpdaterDelegate {
  var onAbort: ((Error) -> Void)?

  func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
    onAbort?(error)
  }
}
