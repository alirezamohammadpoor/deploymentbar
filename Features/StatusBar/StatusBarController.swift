import AppKit
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
  private let statusItem: NSStatusItem
  private let popover = NSPopover()
  private var browserLauncher: BrowserLauncher?
  private var deploymentStore: DeploymentStore?
  private var refreshStatusStore: RefreshStatusStore?
  private var authSession: AuthSession?
  private var credentialStore: CredentialStore?
  private var settingsStore: SettingsStore?
  private var projectStore: ProjectStore?
  private var notificationManager: NotificationManager?
  private var refreshEngine: RefreshEngine?
  private var cancellables = Set<AnyCancellable>()
  private var latestDeploymentState: DeploymentState?
  private var isStale: Bool = false

  // Pulse animation state
  private var pulseTimer: Timer?
  private var isPulseHigh: Bool = true

  init(minimalMode: Bool = false) {
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    super.init()

    if let button = statusItem.button {
      DebugLog.write("StatusBarController button available")
      statusItem.length = NSStatusItem.variableLength
      let titleOnly = ProcessInfo.processInfo.environment["VERCELBAR_TITLE_ONLY"] == "1"
      if titleOnly {
        button.title = "VercelBar"
        button.image = nil
        button.imagePosition = .noImage
      } else {
        button.title = ""
        button.image = NSImage(systemSymbolName: "bolt.horizontal", accessibilityDescription: "VercelBar")
        button.image?.isTemplate = true
        button.imagePosition = .imageOnly
      }
      DebugLog.write("Status item title: \(button.title)")
      button.target = self
      button.action = #selector(togglePopover(_:))
    } else {
      DebugLog.write("StatusBarController button missing")
    }

    popover.behavior = .transient
    popover.contentViewController = NSHostingController(
      rootView: Text(minimalMode ? "Minimal mode" : "Loading…")
        .font(.caption)
        .padding(12)
    )

    DebugLog.write("StatusBarController init complete")
  }

  func configure() {
    DebugLog.write("StatusBarController configure start")
    let browserLauncher = BrowserLauncher()
    DebugLog.write("Configured BrowserLauncher")
    let deploymentStore = DeploymentStore()
    DebugLog.write("Configured DeploymentStore")
    let refreshStatusStore = RefreshStatusStore()
    DebugLog.write("Configured RefreshStatusStore")

    self.browserLauncher = browserLauncher
    self.deploymentStore = deploymentStore
    self.refreshStatusStore = refreshStatusStore
    DebugLog.write("StatusBarController configure deferred")

    DispatchQueue.main.async { [weak self] in
      self?.finishConfigure()
    }
  }

  private func finishConfigure() {
    DebugLog.write("StatusBarController finishConfigure start")
    let authSession = AuthSession.shared
    DebugLog.write("Configured AuthSession")
    let credentialStore = CredentialStore()
    DebugLog.write("Configured CredentialStore")
    let settingsStore = SettingsStore.shared
    DebugLog.write("Configured SettingsStore")
    let projectStore = ProjectStore.shared
    DebugLog.write("Configured ProjectStore")
    let notificationManager = NotificationManager(
      browserLauncher: browserLauncher ?? BrowserLauncher(),
      settings: settingsStore
    )
    DebugLog.write("Configured NotificationManager")

    self.authSession = authSession
    self.credentialStore = credentialStore
    self.settingsStore = settingsStore
    self.projectStore = projectStore
    self.notificationManager = notificationManager

    notificationManager.configure()
    DebugLog.write("NotificationManager configured")
    DebugLog.write("StatusBarController configured")

    authSession.loadInitialStatusIfNeeded()

    guard let deploymentStore = deploymentStore,
          let refreshStatusStore = refreshStatusStore else {
      DebugLog.write("StatusBarController finishConfigure missing dependencies")
      return
    }

    if let config = VercelAuthConfig.load() {
      let client = VercelAPIClientImpl(config: config, tokenProvider: { [weak self] in
        self?.credentialStore?.loadPersonalToken() ?? self?.credentialStore?.loadTokens()?.accessToken
      })
      projectStore.configure(apiClient: client)
      refreshEngine = RefreshEngine(
        store: deploymentStore,
        credentialStore: credentialStore,
        apiClient: client,
        authSession: authSession,
        statusStore: refreshStatusStore,
        settingsStore: settingsStore,
        interval: settingsStore.pollingInterval
      )
    }

    let hostingController = NSHostingController(
      rootView: StatusBarMenu(
        store: deploymentStore,
        refreshStatusStore: refreshStatusStore,
        openURL: { [weak self] url in
          self?.browserLauncher?.open(url: url)
        },
        refreshNow: { [weak self] in
          self?.refreshEngine?.triggerImmediateRefresh()
        },
        signOut: { [weak self] in
          self?.authSession?.signOut(revokeToken: true)
        }
      )
    )
    popover.contentViewController = hostingController

    deploymentStore.onStateChange = { [weak self] deployment, _, newState in
      guard newState == .ready || newState == .error else { return }
      self?.notificationManager?.postDeploymentNotification(deployment: deployment)
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

    settingsStore.$pollingInterval
      .receive(on: RunLoop.main)
      .sink { [weak self] interval in
        self?.refreshEngine?.updateInterval(interval)
      }
      .store(in: &cancellables)

    authSession.$status
      .receive(on: RunLoop.main)
      .sink { [weak self] status in
        self?.handleAuthStatus(status)
      }
      .store(in: &cancellables)

    handleAuthStatus(authSession.status)
    DebugLog.write("StatusBarController configure complete")
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
      notificationManager?.requestAuthorizationIfNeeded()
      refreshEngine?.start()
      projectStore?.refresh()
    case .signedOut:
      refreshEngine?.stop()
      deploymentStore?.apply(deployments: [])
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
    button.toolTip = isStale ? "Last refresh failed" : "VercelBar"

    if latestDeploymentState == .building && !isStale {
      startPulse()
    } else {
      stopPulse()
    }
  }

  // MARK: - Pulse Animation

  private func startPulse() {
    guard pulseTimer == nil else { return }
    isPulseHigh = true
    pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      DispatchQueue.main.async {
        self?.togglePulse()
      }
    }
  }

  private func stopPulse() {
    pulseTimer?.invalidate()
    pulseTimer = nil
    isPulseHigh = true
    if let button = statusItem.button {
      NSAnimationContext.runAnimationGroup { context in
        context.duration = 0.15
        button.animator().alphaValue = 1.0
      }
    }
  }

  private func togglePulse() {
    isPulseHigh.toggle()
    guard let button = statusItem.button else { return }
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.3
      button.animator().alphaValue = isPulseHigh ? 1.0 : 0.3
    }
  }
}
