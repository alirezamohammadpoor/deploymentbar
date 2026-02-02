import AppKit
import Combine
import SwiftUI

final class StatusBarController: NSObject {
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
  private let popover = NSPopover()
  private let browserLauncher = BrowserLauncher()
  private let deploymentStore = DeploymentStore()
  private let authSession = AuthSession.shared
  private let credentialStore = CredentialStore()

  private var refreshEngine: RefreshEngine?
  private var cancellables = Set<AnyCancellable>()

  override init() {
    super.init()

    if let config = VercelAuthConfig.load() {
      let client = VercelAPIClientImpl(config: config, tokenProvider: { [weak self] in
        self?.credentialStore.loadTokens()?.accessToken
      })
      refreshEngine = RefreshEngine(
        store: deploymentStore,
        credentialStore: credentialStore,
        apiClient: client,
        authSession: authSession
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
        openURL: { [weak self] url in
          self?.browserLauncher.open(url: url)
        }
      )
    )

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
}
