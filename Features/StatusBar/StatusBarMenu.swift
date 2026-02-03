import SwiftUI

struct StatusBarMenu: View {
  @ObservedObject var store: DeploymentStore
  @ObservedObject var refreshStatusStore: RefreshStatusStore
  let openURL: (URL) -> Void
  let refreshNow: () -> Void
  let signOut: () -> Void

  @StateObject private var authSession = AuthSession.shared

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
    }
    .padding(.horizontal, Theme.Layout.spacingMD)
    .padding(.vertical, Theme.Layout.spacingSM)
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
        ForEach(store.deployments) { deployment in
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

        Button("Sign Out") {
          signOut()
        }
        .buttonStyle(.plain)
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
      }

      buildStamp
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

  private var buildStamp: some View {
    Text(Bundle.main.buildStamp)
      .font(Theme.Typography.captionSmall)
      .foregroundColor(Theme.Colors.textTertiary)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private extension Bundle {
  var buildStamp: String {
    let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    let build = infoDictionary?["CFBundleVersion"] as? String ?? "0"
    return "Build \(version) (\(build))"
  }
}
