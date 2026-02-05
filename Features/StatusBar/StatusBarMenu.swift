import SwiftUI

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
  @State private var filter: EnvironmentFilter = .all
  @State private var refreshRotation: Double = 0
  @State private var isRefreshing: Bool = false
  @State private var isInitialLoad: Bool = true
  @State private var expandedDeploymentId: String?
  @State private var focusedDeploymentId: String?

  var body: some View {
    VStack(spacing: 0) {
      if !networkMonitor.isConnected {
        offlineBanner
      }
      header
      Divider()
      content
    }
    .frame(width: Theme.Layout.popoverWidth)
    .frame(maxHeight: Theme.Layout.popoverMaxHeight)
    .overlay(
      RoundedRectangle(cornerRadius: Theme.Layout.popoverCornerRadius)
        .strokeBorder(Theme.Colors.border, lineWidth: Theme.Layout.popoverBorderWidth)
    )
    .onReceive(store.$deployments) { deployments in
      if !deployments.isEmpty && isInitialLoad {
        isInitialLoad = false
      }
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
    HStack(spacing: Theme.Layout.spacingSM) {
      Image(systemName: "wifi.slash")
        .font(.system(size: 12))
      Text("No internet connection")
        .font(Theme.Typography.caption)
    }
    .foregroundColor(Theme.Colors.statusBuilding)
    .frame(maxWidth: .infinity)
    .padding(.vertical, Theme.Layout.spacingXS)
    .background(Theme.Colors.statusBuilding.opacity(0.15))
  }

  // MARK: - Header

  private var header: some View {
    HStack(spacing: Theme.Layout.spacingSM) {
      // Segmented filter picker
      Picker("", selection: $filter) {
        ForEach(EnvironmentFilter.allCases, id: \.self) { tab in
          Text(tab.title).tag(tab)
        }
      }
      .pickerStyle(.segmented)
      .controlSize(.small)
      .labelsHidden()
      .frame(maxWidth: 200)

      Spacer()

      // Refresh button
      Button {
        performRefresh()
      } label: {
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(Theme.Colors.textSecondary)
          .rotationEffect(.degrees(refreshRotation))
      }
      .buttonStyle(.plain)
      .help("Refresh deployments")

      // Settings button
      SettingsLink {
        Image(systemName: "gearshape")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(Theme.Colors.textSecondary)
      }
      .buttonStyle(.plain)
      .help("Open settings")
    }
    .padding(.horizontal, Theme.Layout.spacingMD)
    .padding(.vertical, Theme.Layout.spacingSM)
    .frame(height: 32)
  }

  private func performRefresh() {
    guard !isRefreshing else { return }
    isRefreshing = true

    withAnimation(.easeInOut(duration: 0.5)) {
      refreshRotation += 360
    }

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

  private var filteredDeployments: [Deployment] {
    switch filter {
    case .all:
      return store.deployments
    case .production:
      return store.deployments.filter { $0.target == "production" }
    case .preview:
      return store.deployments.filter { $0.target != "production" }
    }
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
    HStack(spacing: Theme.Layout.spacingSM) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 12))
      Text(error)
        .font(Theme.Typography.caption)
        .lineLimit(1)
      Spacer()
      Button("Retry") {
        performRefresh()
      }
      .buttonStyle(.plain)
      .font(Theme.Typography.caption)
      .foregroundColor(Theme.Colors.textSecondary)
    }
    .foregroundColor(Theme.Colors.statusError)
    .padding(.horizontal, Theme.Layout.spacingMD)
    .padding(.vertical, Theme.Layout.spacingXS)
    .background(Theme.Colors.statusError.opacity(0.1))
  }

  private var emptyState: some View {
    VStack(spacing: Theme.Layout.spacingSM) {
      Image(systemName: "cloud.slash")
        .font(.system(size: 48))
        .foregroundColor(Theme.Colors.textTertiary)
      Text("No deployments found")
        .font(.system(size: 13))
        .foregroundColor(Theme.Colors.textSecondary)
      Text("Deploy a project to see it here")
        .font(.system(size: 12))
        .foregroundColor(Theme.Colors.textTertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, Theme.Layout.spacingXL)
  }

  private func errorState(_ error: String) -> some View {
    VStack(spacing: Theme.Layout.spacingSM) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 32))
        .foregroundColor(Theme.Colors.statusBuilding)
      Text(error)
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
        .multilineTextAlignment(.center)
        .lineLimit(3)
      Button("Retry") {
        performRefresh()
      }
      .buttonStyle(.bordered)
      .controlSize(.small)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, Theme.Layout.spacingXL)
    .padding(.horizontal, Theme.Layout.spacingMD)
  }

  private var deploymentList: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(filteredDeployments) { deployment in
          DeploymentRowView(
            deployment: deployment,
            relativeTime: RelativeTimeFormatter.string(from: deployment.createdAt),
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
        }
      }
    }
  }

  private func toggleExpand(for deploymentId: String) {
    withAnimation(.spring(dampingFraction: 0.85)) {
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
      withAnimation(.spring(dampingFraction: 0.85)) {
        expandedDeploymentId = nil
      }
    } else if focusedDeploymentId != nil {
      // Second escape: clear focus
      focusedDeploymentId = nil
    }
    // Note: Third escape would close the popover, but that's handled by the popover behavior
  }

}
