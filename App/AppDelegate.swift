import AppKit

@MainActor
protocol ApplicationIconTarget: AnyObject {
  var applicationIconImage: NSImage! { get set }
}

extension NSApplication: ApplicationIconTarget {}

@MainActor
protocol WorkspaceIconSetting: AnyObject {
  @discardableResult
  func setIcon(_ image: NSImage?, forFile fullPath: String, options: NSWorkspace.IconCreationOptions) -> Bool
}

extension NSWorkspace: WorkspaceIconSetting {}

final class AppDelegate: NSObject, NSApplicationDelegate {
  private var statusBarController: StatusBarController?
  private var minimalStatusItem: NSStatusItem?
  private let instanceCoordinator = AppInstanceCoordinator(
    lockProvider: DefaultAppInstanceLockProvider()
  )

  func applicationDidFinishLaunching(_ notification: Notification) {
    applyApplicationIconIfAvailable()
    DebugLog.write("AppDelegate did finish launching")

    if !instanceCoordinator.startPrimaryIfPossible() {
      Task { @MainActor in
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        NSApp.terminate(nil)
      }
      DebugLog.write("Secondary instance detected; exiting")
      return
    }

    DebugLog.write("Primary instance starting")
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

      if !SettingsStore.shared.hasCompletedOnboarding {
        DebugLog.write("First run — showing onboarding")
        OnboardingWindowController.shared.show()
      }
    }
  }

  @MainActor
  func applyApplicationIconIfAvailable(
    bundle: Bundle = .main,
    application: ApplicationIconTarget? = nil,
    workspace: WorkspaceIconSetting? = nil
  ) {
    guard let icnsPath = bundle.path(forResource: "AppIcon", ofType: "icns"),
          let icon = NSImage(contentsOfFile: icnsPath) else {
      return
    }

    applyApplicationIcon(
      icon,
      bundlePath: bundle.bundlePath,
      application: application ?? NSApplication.shared,
      workspace: workspace ?? NSWorkspace.shared
    )
  }

  @MainActor
  func applyApplicationIcon(
    _ icon: NSImage,
    bundlePath: String,
    application: ApplicationIconTarget? = nil,
    workspace: WorkspaceIconSetting? = nil
  ) {
    let application = application ?? NSApplication.shared
    let workspace = workspace ?? NSWorkspace.shared

    application.applicationIconImage = icon
    // Do not call NSWorkspace.setIcon(_:forFile:): it mutates bundle metadata
    // (Icon\r / FinderInfo), which breaks subsequent CodeSign in local builds.
    _ = bundlePath
    _ = workspace
  }
}
