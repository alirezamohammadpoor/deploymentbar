import SwiftUI

struct StatusBarMenu: View {
  @ObservedObject var store: DeploymentStore
  @ObservedObject var refreshStatusStore: RefreshStatusStore
  let openURL: (URL) -> Void
  let refreshNow: () -> Void
  let signOut: () -> Void

  @StateObject private var authSession = AuthSession.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Deployments")
        .font(.headline)

      switch authSession.status {
      case .signedIn:
        deploymentsView
      case .signedOut, .signingIn, .error:
        OAuthFlowView(authSession: authSession)
      }
    }
    .padding(12)
    .frame(width: 360)
  }

  private var deploymentsView: some View {
    VStack(alignment: .leading, spacing: 8) {
      if store.deployments.isEmpty {
        Text("No deployments yet")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
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

      refreshFooter

      HStack {
        Button("Refresh Now") {
          refreshNow()
        }
        .buttonStyle(.plain)
        .font(.caption)

        Spacer()

        Button("Sign Out") {
          signOut()
        }
        .buttonStyle(.plain)
        .font(.caption)
      }
    }
  }

  private var refreshFooter: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let lastRefresh = refreshStatusStore.status.lastRefresh {
        Text("Updated \(RelativeTimeFormatter.string(from: lastRefresh))")
          .font(.caption2)
          .foregroundColor(.secondary)
      } else {
        Text("Waiting for first refresh")
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      if refreshStatusStore.status.isStale, let error = refreshStatusStore.status.error {
        Text(error)
          .font(.caption2)
          .foregroundColor(.red)
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
}
