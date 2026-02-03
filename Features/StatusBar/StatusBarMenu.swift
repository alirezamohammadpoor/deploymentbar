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
  @State private var filter: EnvironmentFilter = .all

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      content
      Divider()
      footer
    }
    .frame(width: Theme.Layout.popoverWidth)
    .frame(maxHeight: Theme.Layout.popoverMaxHeight)
    .overlay(
      RoundedRectangle(cornerRadius: Theme.Layout.popoverCornerRadius)
        .strokeBorder(Theme.Colors.border, lineWidth: Theme.Layout.popoverBorderWidth)
    )
  }

  // MARK: - Header

  private var header: some View {
    HStack {
      Text("Deployments")
        .sectionHeaderStyle()
      Spacer()
      filterTabs
    }
    .padding(.horizontal, Theme.Layout.spacingMD)
    .padding(.vertical, Theme.Layout.spacingSM)
  }

  private var filterTabs: some View {
    HStack(spacing: Theme.Layout.spacingSM) {
      ForEach(EnvironmentFilter.allCases, id: \.self) { tab in
        Button {
          filter = tab
        } label: {
          VStack(spacing: 2) {
            Text(tab.title)
              .font(Theme.Typography.caption)
              .foregroundColor(filter == tab ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
            Rectangle()
              .fill(filter == tab ? Theme.Colors.textPrimary : Color.clear)
              .frame(height: 2)
          }
        }
        .buttonStyle(.plain)
      }
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
      if store.deployments.isEmpty {
        emptyState
      } else if refreshStatusStore.status.isStale, let error = refreshStatusStore.status.error {
        errorState(error)
      } else {
        deploymentList
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: Theme.Layout.spacingSM) {
      Image(systemName: "tray")
        .font(.system(size: 24))
        .foregroundColor(Theme.Colors.textTertiary)
      Text("No recent deployments")
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, Theme.Layout.spacingXL)
  }

  private func errorState(_ error: String) -> some View {
    HStack(spacing: Theme.Layout.spacingSM) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(Theme.Colors.statusError)
      Text(error)
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
        .lineLimit(2)
      Spacer()
      Button("Retry") {
        refreshNow()
      }
      .buttonStyle(.plain)
      .font(Theme.Typography.caption)
      .foregroundColor(Theme.Colors.textSecondary)
    }
    .padding(.horizontal, Theme.Layout.spacingMD)
    .padding(.vertical, Theme.Layout.spacingSM)
  }

  private var deploymentList: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(filteredDeployments) { deployment in
          let url = previewURL(for: deployment)
          Button {
            if let url { openURL(url) }
          } label: {
            DeploymentRowView(
              deployment: deployment,
              relativeTime: RelativeTimeFormatter.string(from: deployment.createdAt)
            )
          }
          .buttonStyle(.plain)
          .disabled(url == nil)
        }
      }
    }
  }

  // MARK: - Footer

  private var footer: some View {
    VStack(spacing: Theme.Layout.spacingXS) {
      refreshTimestamp

      HStack {
        Button("Refresh Now") {
          refreshNow()
        }
        .buttonStyle(.plain)
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)

        Spacer()

        SettingsLink {
          Text("Settings")
            .font(Theme.Typography.caption)
            .foregroundColor(Theme.Colors.textSecondary)
        }
        .buttonStyle(.plain)

        Spacer()

        Button("Sign Out") {
          signOut()
        }
        .buttonStyle(.plain)
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
      }

    }
    .padding(.horizontal, Theme.Layout.spacingMD)
    .padding(.vertical, Theme.Layout.spacingSM)
  }

  private var refreshTimestamp: some View {
    Group {
      if let lastRefresh = refreshStatusStore.status.lastRefresh {
        Text("Updated \(RelativeTimeFormatter.string(from: lastRefresh))")
      } else {
        Text("Waiting for first refresh")
      }
    }
    .font(Theme.Typography.captionSmall)
    .foregroundColor(Theme.Colors.textTertiary)
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func previewURL(for deployment: Deployment) -> URL? {
    guard let value = deployment.url, !value.isEmpty else { return nil }
    if let url = URL(string: value), url.scheme != nil {
      return url
    }
    return URL(string: "https://\(value)")
  }

}
