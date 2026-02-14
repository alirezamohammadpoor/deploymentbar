import SwiftUI
import AppKit

// MARK: - Visual Effect Background

struct VisualEffectBackground: NSViewRepresentable {
  let material: NSVisualEffectView.Material
  let blendingMode: NSVisualEffectView.BlendingMode

  init(
    material: NSVisualEffectView.Material = .menu,
    blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
  ) {
    self.material = material
    self.blendingMode = blendingMode
  }

  func makeNSView(context: Context) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.material = material
    view.blendingMode = blendingMode
    view.state = .active
    return view
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
  }
}

enum EnvironmentFilter: String, CaseIterable {
  case all
  case production
  case preview

  var title: String {
    switch self {
    case .all: return "All"
    case .production: return "Production"
    case .preview: return "Preview"
    }
  }
}

struct StatusBarMenu: View {
  @ObservedObject var store: DeploymentStore
  @ObservedObject var refreshStatusStore: RefreshStatusStore
  let openURL: (URL) -> Void
  let refreshNow: () -> Void
  let signOut: () -> Void

  @StateObject private var authSession = AuthSession.shared
  @StateObject private var networkMonitor = NetworkMonitor.shared
  @StateObject private var projectStore = ProjectStore.shared
  @State private var filter: EnvironmentFilter = .all
  @State private var selectedMenuProjectIds: Set<String> = []
  @State private var isRefreshing: Bool = false
  @State private var isInitialLoad: Bool = true
  @State private var expandedDeploymentId: String?
  @State private var focusedDeploymentId: String?
  @State private var isHoveringProject = false
  @State private var now = Date()
  private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

  private enum FooterRefreshTone {
    case fresh
    case stale
    case waiting

    var dotColor: Color {
      switch self {
      case .fresh: return Geist.Colors.statusReady
      case .stale: return Geist.Colors.statusError
      case .waiting: return Geist.Colors.statusQueued
      }
    }

    var textColor: Color {
      switch self {
      case .stale: return Geist.Colors.statusError
      case .fresh, .waiting: return Geist.Colors.textSecondary
      }
    }

    var backgroundColor: Color {
      switch self {
      case .fresh: return Geist.Colors.gray100
      case .stale: return Geist.Colors.statusError.opacity(0.1)
      case .waiting: return Geist.Colors.gray100
      }
    }

    var borderColor: Color {
      switch self {
      case .stale: return Geist.Colors.statusError.opacity(0.4)
      case .fresh, .waiting: return Geist.Colors.borderSubtle
      }
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      if !networkMonitor.isConnected {
        offlineBanner
      }
      header
      Divider()
      content
    }
    .frame(width: Geist.Layout.popoverWidth)
    .frame(maxHeight: Geist.Layout.popoverMaxHeight)
    .background(Geist.Colors.backgroundPrimary)
    .overlay(
      RoundedRectangle(cornerRadius: Geist.Layout.popoverCornerRadius)
        .strokeBorder(Geist.Colors.border, lineWidth: Geist.Layout.popoverBorderWidth)
    )
    .onReceive(store.$deployments) { deployments in
      if !deployments.isEmpty && isInitialLoad {
        isInitialLoad = false
      }
    }
    .onReceive(clock) { tick in
      now = tick
    }
    .onKeyPress(keys: [.upArrow]) { _ in
      navigateUp()
      return .handled
    }
    .onKeyPress(keys: [.downArrow]) { _ in
      navigateDown()
      return .handled
    }
    .onKeyPress(keys: [.return]) { _ in
      toggleExpandFocused()
      return .handled
    }
    .onKeyPress(keys: [.space]) { _ in
      toggleExpandFocused()
      return .handled
    }
    .onKeyPress(keys: [.escape]) { _ in
      handleEscape()
      return .handled
    }
    .keyboardShortcut("r", modifiers: .command)
  }

  // MARK: - Offline Banner

  private var offlineBanner: some View {
    HStack(spacing: Geist.Layout.spacingSM) {
      Image(systemName: "wifi.slash")
        .font(.system(size: Geist.Layout.iconSizeMD))
      Text("No internet connection")
        .font(Geist.Typography.caption)
    }
    .foregroundColor(Geist.Colors.statusWarning)
    .frame(maxWidth: .infinity)
    .padding(.vertical, Geist.Layout.spacingXS)
    .background(Geist.Colors.statusWarning.opacity(0.15))
  }

  // MARK: - Header

  private var header: some View {
    VStack(spacing: 0) {
      // Title bar
      HStack(spacing: Geist.Layout.spacingMD) {
        HStack(spacing: Geist.Layout.spacingSM) {
          Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .frame(width: 18, height: 18)
            .cornerRadius(4)
          Text("DeployBar")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(Geist.Colors.textPrimary)
        }

        Spacer()

        HStack(spacing: Geist.Layout.spacingMD) {
          // Project filter dropdown
          if !projectStore.projects.isEmpty {
            Menu {
              Button {
                selectedMenuProjectIds = []
              } label: {
                if selectedMenuProjectIds.isEmpty {
                  Label("All Projects", systemImage: "checkmark")
                } else {
                  Text("All Projects")
                }
              }

              Divider()

              ForEach(availableProjects, id: \.id) { project in
                Button {
                  toggleProjectFilter(project.id)
                } label: {
                  if selectedMenuProjectIds.contains(project.id) {
                    Label(project.name, systemImage: "checkmark")
                  } else {
                    Text(project.name)
                  }
                }
              }
            } label: {
              HStack(spacing: 5) {
                Text(projectFilterLabel)
                  .font(Geist.Typography.caption)
                  .foregroundColor(Geist.Colors.textSecondary)
                Image(systemName: "chevron.down")
                  .font(.system(size: Geist.Layout.iconSizeSM, weight: .medium))
                  .foregroundColor(Geist.Colors.textTertiary)
              }
              .padding(.horizontal, Geist.Layout.spacingSM)
              .padding(.vertical, 5)
              .background(isHoveringProject ? Geist.Colors.gray200 : Geist.Colors.gray100)
              .clipShape(RoundedRectangle(cornerRadius: Geist.Layout.headerDropdownRadius))
              .onHover { hovering in isHoveringProject = hovering }
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
          }

          Button {
            performRefresh()
          } label: {
            HeaderIconButtonContent(systemName: "arrow.clockwise")
          }
          .buttonStyle(.plain)
          .help("Refresh deployments")

          // Settings button
          SettingsLink {
            HeaderIconButtonContent(systemName: "gearshape")
          }
          .buttonStyle(.plain)
          .help("Open settings")
        }
      }
      .padding(.horizontal, Geist.Layout.spacingMD)
      .padding(.vertical, Geist.Layout.spacingSM)

      Divider()

      // Filter tabs
      environmentFilterControl
    }
  }

  private var environmentFilterControl: some View {
    HStack(spacing: 0) {
      ForEach(EnvironmentFilter.allCases, id: \.self) { tab in
        Button {
          withAnimation(.easeInOut(duration: 0.15)) {
            filter = tab
          }
        } label: {
          Text(tab.title)
            .font(.system(size: 12, weight: filter == tab ? .medium : .regular))
            .foregroundColor(filter == tab ? Geist.Colors.textPrimary : Geist.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .overlay(alignment: .bottom) {
              Rectangle()
                .fill(filter == tab ? Geist.Colors.accent : Color.clear)
                .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func performRefresh() {
    guard !isRefreshing else { return }
    isRefreshing = true

    refreshNow()

    // Reset refreshing state after animation
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      isRefreshing = false
    }
  }

  // MARK: - Content

  @ViewBuilder
  private var content: some View {
    switch authSession.status {
    case .signedIn:
      deploymentsView
    case .signedOut, .signingIn, .error:
      OAuthFlowView(authSession: authSession)
    }
  }

  // MARK: - Deployments

  private var footer: some View {
    HStack(spacing: Geist.Layout.spacingSM) {
      HStack(spacing: Geist.Layout.spacingXS) {
        Circle()
          .fill(footerTone.dotColor)
          .frame(width: 6, height: 6)

        Text(refreshSummaryText)
          .font(Geist.Typography.caption)
          .foregroundColor(footerTone.textColor)
          .lineLimit(1)
      }
      .padding(.horizontal, Geist.Layout.spacingSM)
      .padding(.vertical, Geist.Layout.spacingXS)
      .background(footerTone.backgroundColor)
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .stroke(footerTone.borderColor, lineWidth: 1)
      )

      Spacer()

      Button {
        performRefresh()
      } label: {
        Label("Refresh", systemImage: "arrow.clockwise")
      }
      .buttonStyle(FooterActionButtonStyle(tone: .primary))

      if case .signedIn = authSession.status {
        Button {
          signOut()
        } label: {
          Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
        }
        .buttonStyle(FooterActionButtonStyle(tone: .secondary))
      }
    }
    .padding(.horizontal, Geist.Layout.spacingMD)
    .padding(.vertical, Geist.Layout.spacingSM)
  }

  private var footerTone: FooterRefreshTone {
    let status = refreshStatusStore.status
    if status.isStale {
      return .stale
    }
    if status.lastRefresh == nil {
      return .waiting
    }
    return .fresh
  }

  private var refreshSummaryText: String {
    let status = refreshStatusStore.status
    if status.isStale {
      if let lastRefresh = status.lastRefresh {
        return "Update failed (\(RelativeTimeFormatter.string(from: lastRefresh, now: now)))"
      }
      return "Update failed"
    }

    if let lastRefresh = status.lastRefresh {
      return "Updated \(RelativeTimeFormatter.string(from: lastRefresh, now: now))"
    }

    return "Waiting for first refresh"
  }

  private var filteredDeployments: [Deployment] {
    var deployments: [Deployment]
    switch filter {
    case .all:
      deployments = store.deployments
    case .production:
      deployments = store.deployments.filter { $0.target == "production" }
    case .preview:
      deployments = store.deployments.filter { $0.target != "production" }
    }

    if !selectedMenuProjectIds.isEmpty {
      deployments = deployments.filter { d in
        guard let pid = d.projectId else { return true }
        return selectedMenuProjectIds.contains(pid)
      }
    }

    return deployments
  }

  private var deploymentsView: some View {
    Group {
      if store.deployments.isEmpty && isInitialLoad && !refreshStatusStore.status.isStale {
        // Show skeleton while loading initial data
        SkeletonLoadingView()
      } else if store.deployments.isEmpty && !isInitialLoad {
        emptyState
      } else if store.deployments.isEmpty && refreshStatusStore.status.isStale {
        if let error = refreshStatusStore.status.error {
          errorState(error)
        } else {
          emptyState
        }
      } else if refreshStatusStore.status.isStale, let error = refreshStatusStore.status.error {
        // Show error state but keep existing data
        VStack(spacing: 0) {
          errorBanner(error)
          deploymentList
        }
      } else {
        deploymentList
      }
    }
  }

  private func errorBanner(_ error: String) -> some View {
    HStack(spacing: Geist.Layout.spacingSM) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 12))
      Text(error)
        .font(Geist.Typography.caption)
        .lineLimit(1)
      Spacer()
      Button("Retry") {
        performRefresh()
      }
      .buttonStyle(.plain)
      .font(Geist.Typography.caption)
      .foregroundColor(Geist.Colors.textSecondary)
    }
    .foregroundColor(Geist.Colors.statusError)
    .padding(.horizontal, Geist.Layout.spacingMD)
    .padding(.vertical, Geist.Layout.spacingXS)
    .background(Geist.Colors.statusError.opacity(0.1))
  }

  private var emptyState: some View {
    VStack(spacing: Geist.Layout.spacingSM) {
      Image(systemName: "cloud.slash")
        .font(.system(size: 48))
        .foregroundColor(Geist.Colors.textTertiary)
      Text("No deployments found")
        .font(Geist.Typography.projectName)
        .foregroundColor(Geist.Colors.textSecondary)
      Text("Deploy a project to see it here")
        .font(Geist.Typography.commitMessage)
        .foregroundColor(Geist.Colors.textTertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, Geist.Layout.spacingXL)
  }

  private func errorState(_ error: String) -> some View {
    VStack(spacing: Geist.Layout.spacingSM) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 32))
        .foregroundColor(Geist.Colors.statusError)
      Text(error)
        .font(Geist.Typography.caption)
        .foregroundColor(Geist.Colors.textSecondary)
        .multilineTextAlignment(.center)
        .lineLimit(3)
      Button("Retry") {
        performRefresh()
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, Geist.Layout.spacingXL)
    .padding(.horizontal, Geist.Layout.spacingMD)
  }

  private var deploymentList: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(Array(filteredDeployments.enumerated()), id: \.element.id) { index, deployment in
          DeploymentRowView(
            deployment: deployment,
            checkStatus: store.checkStatuses[deployment.id],
            relativeTime: RelativeTimeFormatter.string(from: deployment.createdAt, now: now),
            isExpanded: expandedDeploymentId == deployment.id,
            isFocused: focusedDeploymentId == deployment.id,
            onToggleExpand: {
              toggleExpand(for: deployment.id)
            },
            openURL: openURL,
            onRefresh: {
              performRefresh()
            }
          )

          // Row separator (inset to align with project name, past status dot)
          if index < filteredDeployments.count - 1 {
            Divider()
              .padding(.leading, Geist.Layout.rowSeparatorInset)
          }
        }
      }
    }
  }

  private func toggleExpand(for deploymentId: String) {
    let animation = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
      ? Animation?.none
      : .spring(dampingFraction: 0.85)

    withAnimation(animation) {
      if expandedDeploymentId == deploymentId {
        expandedDeploymentId = nil
      } else {
        expandedDeploymentId = deploymentId
      }
    }
  }

  private func previewURL(for deployment: Deployment) -> URL? {
    guard let value = deployment.url, !value.isEmpty else { return nil }
    if let url = URL(string: value), url.scheme != nil {
      return url
    }
    return URL(string: "https://\(value)")
  }

  // MARK: - Project Filter

  private var availableProjects: [Project] {
    let settingsIds = SettingsStore.shared.selectedProjectIds
    if settingsIds.isEmpty {
      return projectStore.projects
    }
    return projectStore.projects.filter { settingsIds.contains($0.id) }
  }

  private var projectFilterLabel: String {
    if selectedMenuProjectIds.isEmpty {
      return "Project"
    }
    if selectedMenuProjectIds.count == 1,
       let pid = selectedMenuProjectIds.first,
       let project = projectStore.projects.first(where: { $0.id == pid }) {
      return project.name
    }
    return "\(selectedMenuProjectIds.count) Projects"
  }

  private func toggleProjectFilter(_ projectId: String) {
    if selectedMenuProjectIds.contains(projectId) {
      selectedMenuProjectIds.remove(projectId)
    } else {
      selectedMenuProjectIds.insert(projectId)
    }
  }

  // MARK: - Keyboard Navigation

  private func navigateUp() {
    let deployments = filteredDeployments
    guard !deployments.isEmpty else { return }

    if let currentId = focusedDeploymentId,
       let currentIndex = deployments.firstIndex(where: { $0.id == currentId }),
       currentIndex > 0 {
      focusedDeploymentId = deployments[currentIndex - 1].id
    } else {
      focusedDeploymentId = deployments.last?.id
    }
  }

  private func navigateDown() {
    let deployments = filteredDeployments
    guard !deployments.isEmpty else { return }

    if let currentId = focusedDeploymentId,
       let currentIndex = deployments.firstIndex(where: { $0.id == currentId }),
       currentIndex < deployments.count - 1 {
      focusedDeploymentId = deployments[currentIndex + 1].id
    } else {
      focusedDeploymentId = deployments.first?.id
    }
  }

  private func toggleExpandFocused() {
    guard let focusedId = focusedDeploymentId else {
      // If nothing focused, focus the first deployment
      focusedDeploymentId = filteredDeployments.first?.id
      return
    }

    toggleExpand(for: focusedId)
  }

  private func handleEscape() {
    if expandedDeploymentId != nil {
      // First escape: collapse expanded row
      let animation = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        ? Animation?.none
        : .spring(dampingFraction: 0.85)

      withAnimation(animation) {
        expandedDeploymentId = nil
      }
    } else if focusedDeploymentId != nil {
      // Second escape: clear focus
      focusedDeploymentId = nil
    }
    // Note: Third escape would close the popover, but that's handled by the popover behavior
  }

}

private struct HeaderIconButtonContent: View {
  let systemName: String

  var body: some View {
    Image(systemName: systemName)
      .font(.system(size: Geist.Layout.iconSizeMD, weight: .medium))
      .foregroundColor(Geist.Colors.textSecondary)
      .frame(width: 24, height: 24)
  }
}

private struct FooterActionButtonStyle: ButtonStyle {
  enum Tone {
    case primary
    case secondary
  }

  let tone: Tone
  @State private var isHovered = false

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(Geist.Typography.caption)
      .foregroundColor(tone == .primary ? Geist.Colors.textPrimary : Geist.Colors.textSecondary)
      .padding(.horizontal, Geist.Layout.spacingSM)
      .padding(.vertical, Geist.Layout.spacingXS)
      .background(
        RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
          .fill(backgroundColor(configuration: configuration))
      )
      .overlay(
        RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
          .stroke(borderColor, lineWidth: 1)
      )
      .onHover { hovering in
        isHovered = hovering
      }
  }

  private var borderColor: Color {
    tone == .primary ? Geist.Colors.border : Geist.Colors.borderSubtle
  }

  private func backgroundColor(configuration: Configuration) -> Color {
    if configuration.isPressed {
      return Geist.Colors.gray300
    }
    if isHovered {
      return Geist.Colors.gray200
    }
    return Geist.Colors.gray100
  }
}
