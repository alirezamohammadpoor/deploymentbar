import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarController: StatusBarController?
  private let instanceCoordinator = AppInstanceCoordinator(
    lockProvider: DefaultAppInstanceLockProvider(),
    messenger: AppInstanceMessenger.shared
  )

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSAppleEventManager.shared().setEventHandler(
      self,
      andSelector: #selector(handleGetURLEvent(_:replyEvent:)),
      forEventClass: AEEventClass(kInternetEventClass),
      andEventID: AEEventID(kAEGetURL)
    )

    if !instanceCoordinator.startPrimaryIfPossible() {
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        NSApp.terminate(nil)
      }
      return
    }

    _ = URLSchemeRegistrar.registerCurrentBundle()
    AppInstanceMessenger.shared.startObserving { url in
      OAuthCallbackHandler.shared.handle(url: url)
    }
    statusBarController = StatusBarController()
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else { return }
    instanceCoordinator.handleOpenURL(url, onForward: {
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
      NSApp.terminate(nil)
    }, onHandle: {
      OAuthCallbackHandler.shared.handle(url: url)
    })
  }

  @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
    guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
          let url = URL(string: urlString) else {
      return
    }

    instanceCoordinator.handleOpenURL(url, onForward: {
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
      NSApp.terminate(nil)
    }, onHandle: {
      OAuthCallbackHandler.shared.handle(url: url)
    })
  }
}
