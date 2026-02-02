import AppKit
import Combine
import SwiftUI

final class StatusBarController: NSObject {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let popover = NSPopover()
  private let browserLauncher = BrowserLauncher()
  private let deploymentStore = DeploymentStore()
  private let refreshStatusStore = RefreshStatusStore()
  private let authSession = AuthSession.shared
  private let credentialStore = CredentialStore()
  private let notificationManager: NotificationManager

  private var refreshEngine: RefreshEngine?
  private var cancellables = Set<AnyCancellable>()
  private var latestDeploymentState: DeploymentState?
  private var isStale: Bool = false

  override init() {
    notificationManager = NotificationManager(browserLauncher: browserLauncher)
    super.init()

    notificationManager.configure()

    if let config = VercelAuthConfig.load() {
      let client = VercelAPIClientImpl(config: config, tokenProvider: { [weak self] in
        self?.credentialStore.loadTokens()?.accessToken
      })
      refreshEngine = RefreshEngine(
        store: deploymentStore,
        credentialStore: credentialStore,
        apiClient: client,
        authSession: authSession,
        statusStore: refreshStatusStore
      )
    }

    if let button = statusItem.button {
      button.image = NSImage(systemSymbolName: "bolt.horizontal", accessibilityDescription: "VercelBar")
      button.image?.isTemplate = true
      button.target = self
      button.action = #selector(togglePopover(_:))
    }

    popover.behavior = .transient
    popover.contentViewController = NSHostingController(
      rootView: StatusBarMenu(
        store: deploymentStore,
        refreshStatusStore: refreshStatusStore,
        openURL: { [weak self] url in
          self?.browserLauncher.open(url: url)
        }
      )
    )

    deploymentStore.onStateChange = { [weak self] deployment, _, newState in
      guard newState == .ready || newState == .error else { return }
      self?.notificationManager.postDeploymentNotification(deployment: deployment)
    }

    deploymentStore.$deployments
      .receive(on: RunLoop.main)
      .sink { [weak self] deployments in
        self?.latestDeploymentState = deployments.first?.state
        self?.updateStatusIcon()
      }
      .store(in: &cancellables)

    refreshStatusStore.$status
      .receive(on: RunLoop.main)
      .sink { [weak self] status in
        self?.isStale = status.isStale
        self?.updateStatusIcon()
      }
      .store(in: &cancellables)

    authSession.$status
      .receive(on: RunLoop.main)
      .sink { [weak self] status in
        self?.handleAuthStatus(status)
      }
      .store(in: &cancellables)

    handleAuthStatus(authSession.status)
  }

  @objc private func togglePopover(_ sender: Any?) {
    guard let button = statusItem.button else { return }
    if popover.isShown {
      popover.performClose(sender)
    } else {
      popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
      NSApp.activate(ignoringOtherApps: true)
    }
  }

  private func handleAuthStatus(_ status: AuthSession.Status) {
    switch status {
    case .signedIn:
      notificationManager.requestAuthorizationIfNeeded()
      refreshEngine?.start()
    case .signedOut:
      refreshEngine?.stop()
      deploymentStore.apply(deployments: [])
    case .signingIn:
      break
    case .error:
      break
    }
  }

  private func updateStatusIcon() {
    guard let button = statusItem.button else { return }
    let symbolName: String

    switch latestDeploymentState {
    case .some(.ready):
      symbolName = "checkmark.circle"
    case .some(.building):
      symbolName = "arrow.triangle.2.circlepath"
    case .some(.error):
      symbolName = "xmark.octagon"
    case .some(.canceled):
      symbolName = "slash.circle"
    case .none:
      symbolName = "bolt.horizontal"
    }

    button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "VercelBar")
    button.image?.isTemplate = true
    button.alphaValue = isStale ? 0.4 : 1.0
    button.toolTip = isStale ? "Last refresh failed" : "VercelBar"
  }
}
