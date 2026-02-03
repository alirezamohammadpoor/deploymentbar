import AppKit
import Carbon

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarController: StatusBarController?
  private var minimalStatusItem: NSStatusItem?
  private let instanceCoordinator = AppInstanceCoordinator(
    lockProvider: DefaultAppInstanceLockProvider(),
    messenger: AppInstanceMessenger.shared
  )

  func applicationDidFinishLaunching(_ notification: Notification) {
    DebugLog.write("AppDelegate did finish launching")
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
      DebugLog.write("Secondary instance detected; exiting")
      return
    }

    DebugLog.write("Primary instance starting")
    _ = URLSchemeRegistrar.registerCurrentBundle()
    AppInstanceMessenger.shared.startObserving { url in
      DebugLog.write("Received forwarded OAuth URL: \(url.absoluteString)")
      OAuthCallbackHandler.shared.handle(url: url)
    }
    Task { @MainActor in
      let forceStandalone = ProcessInfo.processInfo.environment["VERCELBAR_STANDALONE_STATUSITEM"] == "1"
      if forceStandalone {
        DebugLog.write("Standalone status item mode enabled")
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
          button.title = "VB"
          button.toolTip = "Standalone"
        }
        self.minimalStatusItem = item
        DebugLog.write("Standalone status item created")
        return
      }

      let minimalMode = ProcessInfo.processInfo.environment["VERCELBAR_MINIMAL"] == "1"
      if minimalMode {
        DebugLog.write("Creating minimal status item in AppDelegate")
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
          button.title = "VB"
        }
        self.minimalStatusItem = item
        DebugLog.write("Minimal status item created")
        return
      }

      DebugLog.write("Creating StatusBarController")
      let controller = StatusBarController(minimalMode: minimalMode)
      controller.configure()
      self.statusBarController = controller
      DebugLog.write("StatusBarController created")
    }
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    guard let url = urls.first else { return }
    DebugLog.write("application(_:open:) received URL: \(url.absoluteString)")
    instanceCoordinator.handleOpenURL(url, onForward: {
      DebugLog.write("Forwarding URL to primary instance")
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
      NSApp.terminate(nil)
    }, onHandle: {
      DebugLog.write("Handling URL in primary instance")
      OAuthCallbackHandler.shared.handle(url: url)
    })
  }

  @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
    guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
          let url = URL(string: urlString) else {
      return
    }

    DebugLog.write("AppleEvent received URL: \(url.absoluteString)")
    instanceCoordinator.handleOpenURL(url, onForward: {
      DebugLog.write("AppleEvent forwarding URL to primary instance")
      RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
      NSApp.terminate(nil)
    }, onHandle: {
      DebugLog.write("AppleEvent handling URL in primary instance")
      OAuthCallbackHandler.shared.handle(url: url)
    })
  }
}
