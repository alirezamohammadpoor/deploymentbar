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
  private var latestDeploymentDate: Date?
  private var isStale: Bool = false
  private var staleTimer: Timer?

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
        button.title = "Deploymentbar"
        button.image = nil
        button.imagePosition = .noImage
      } else {
        button.title = ""
        button.image = NSImage(named: "vercel-icon")
        button.image?.isTemplate = true
        button.imagePosition = .imageOnly
      }
      DebugLog.write("Status item title: \(button.title)")
      button.target = self
      button.action = #selector(handleStatusItemClick(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
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
    let refreshStatusStore = RefreshStatusStore.shared
    DebugLog.write("Configured RefreshStatusStore")

    self.browserLauncher = browserLauncher
    self.deploymentStore = deploymentStore
    self.refreshStatusStore = refreshStatusStore

    finishConfigure()
  }

  private func finishConfigure() {
    DebugLog.write("StatusBarController finishConfigure start")
    let authSession = AuthSession.shared
    DebugLog.write("Configured AuthSession")
    let credentialStore = CredentialStore.shared
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

    let client = VercelAPIClientImpl(tokenProvider: { [weak self] in
      let pat = self?.credentialStore?.loadPersonalToken()
      DebugLog.write("tokenProvider called: hasPAT=\(pat != nil)")
      return pat
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
    DebugLog.write("RefreshEngine created")

    let menuView = StatusBarMenu(
      store: deploymentStore,
      refreshStatusStore: refreshStatusStore,
      openURL: { [weak self] url in
        self?.browserLauncher?.open(url: url)
      },
      refreshNow: { [weak self] in
        self?.refreshEngine?.triggerImmediateRefresh()
      },
      signOut: { [weak self] in
        self?.authSession?.signOut()
      }
    )
    let hostingController = NSHostingController(rootView: menuView)
    popover.contentViewController = hostingController

    deploymentStore.onStateChange = { [weak self] deployment, _, newState in
      guard newState == .ready || newState == .error else { return }
      self?.notificationManager?.postDeploymentNotification(deployment: deployment)
    }

    deploymentStore.onCheckStatusChange = { [weak self] deployment, status in
      self?.notificationManager?.postCheckNotification(deployment: deployment, status: status)
    }

    deploymentStore.$deployments
      .receive(on: RunLoop.main)
      .sink { [weak self] deployments in
        self?.latestDeploymentState = deployments.first?.state
        self?.latestDeploymentDate = deployments.first?.createdAt
        self?.scheduleStaleTimer()
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

  @objc private func handleStatusItemClick(_ sender: Any?) {
    guard let event = NSApp.currentEvent else { togglePopover(sender); return }
    if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
      showContextMenu()
    } else {
      togglePopover(sender)
    }
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

  // MARK: - Right-click menu

  private func showContextMenu() {
    let menu = NSMenu()
    menu.autoenablesItems = false

    let version = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? ""
    let header = NSMenuItem(
      title: version.isEmpty ? "Deploymentbar" : "Deploymentbar \(version)",
      action: nil,
      keyEquivalent: ""
    )
    header.isEnabled = false
    menu.addItem(header)
    menu.addItem(.separator())

    addMenuItem(to: menu, title: "Refresh Now", action: #selector(menuRefreshNow), key: "r")
    addMenuItem(to: menu, title: "Settings…", action: #selector(menuOpenSettings), key: ",")
    addMenuItem(to: menu, title: "Check for Updates…", action: #selector(menuCheckForUpdates), key: "")
    menu.addItem(.separator())
    addMenuItem(to: menu, title: "Open Vercel Dashboard", action: #selector(menuOpenDashboard), key: "")
    menu.addItem(.separator())
    addMenuItem(to: menu, title: "Quit Deploymentbar", action: #selector(menuQuit), key: "q")

    statusItem.menu = menu
    defer { statusItem.menu = nil }
    statusItem.button?.performClick(nil)
  }

  private func addMenuItem(to menu: NSMenu, title: String, action: Selector, key: String) {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
    item.target = self
    item.isEnabled = true
    menu.addItem(item)
  }

  @objc private func menuRefreshNow() {
    refreshEngine?.triggerImmediateRefresh()
  }

  @objc private func menuOpenSettings() {
    NSApp.activate(ignoringOtherApps: true)
    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
  }

  @objc private func menuCheckForUpdates() {
    UpdateWindowController.shared.show()
  }

  @objc private func menuOpenDashboard() {
    guard let url = URL(string: "https://vercel.com/dashboard") else { return }
    browserLauncher?.open(url: url)
  }

  @objc private func menuQuit() {
    NSApp.terminate(nil)
  }

  private func handleAuthStatus(_ status: AuthSession.Status) {
    DebugLog.write("handleAuthStatus: \(status), refreshEngine=\(refreshEngine != nil)")
    switch status {
    case .signedIn:
      notificationManager?.requestAuthorizationIfNeeded()
      refreshEngine?.start()
      projectStore?.refresh()
      DebugLog.write("handleAuthStatus: called refreshEngine.start()")
    case .signedOut:
      refreshEngine?.stop()
      deploymentStore?.apply(deployments: [])
    case .signingIn:
      break
    }
  }

  private func scheduleStaleTimer() {
    staleTimer?.invalidate()
    staleTimer = nil
    guard let created = latestDeploymentDate else { return }
    let elapsed = Date().timeIntervalSince(created)
    let remaining = 300 - elapsed
    guard remaining > 0 else { return }
    staleTimer = Timer.scheduledTimer(withTimeInterval: remaining, repeats: false) { [weak self] _ in
      DispatchQueue.main.async {
        self?.updateStatusIcon()
      }
    }
  }

  private func updateStatusIcon() {
    guard let button = statusItem.button else { return }

    let isRecent: Bool = {
      guard let created = latestDeploymentDate else { return false }
      return Date().timeIntervalSince(created) < 300
    }()

    button.toolTip = isStale ? "Last refresh failed" : "Deploymentbar"

    if isRecent, let tintColor = Geist.Colors.StatusBarIcon.color(for: latestDeploymentState) {
      button.image = tintedIcon(color: tintColor)
      button.image?.isTemplate = false
    } else {
      button.image = NSImage(named: "vercel-icon")
      button.image?.isTemplate = true
    }

    if isRecent && (latestDeploymentState == .building || latestDeploymentState == .queued) && !isStale {
      startPulse()
    } else {
      stopPulse()
    }
  }

  private func tintedIcon(color: NSColor) -> NSImage? {
    guard let base = NSImage(named: "vercel-icon") else { return nil }
    let img = NSImage(size: base.size, flipped: false) { rect in
      base.draw(in: rect)
      color.setFill()
      rect.fill(using: .sourceAtop)
      return true
    }
    img.isTemplate = false
    return img
  }

  // MARK: - Pulse Animation

  private func startPulse() {
    guard pulseTimer == nil else { return }
    // Respect Reduce Motion — leave the icon tinted at full alpha. The tint
    // color (warning yellow for building) is already enough of a signal.
    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
    isPulseHigh = true
    pulseTimer = Timer.scheduledTimer(
      withTimeInterval: Geist.Motion.statusBarPulseInterval,
      repeats: true
    ) { [weak self] _ in
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
        context.duration = Geist.Motion.statusBarPulseStep / 2
        button.animator().alphaValue = 1.0
      }
    }
  }

  private func togglePulse() {
    isPulseHigh.toggle()
    guard let button = statusItem.button else { return }
    NSAnimationContext.runAnimationGroup { context in
      context.duration = Geist.Motion.statusBarPulseStep
      button.animator().alphaValue = isPulseHigh ? 1.0 : 0.4
    }
  }
}
