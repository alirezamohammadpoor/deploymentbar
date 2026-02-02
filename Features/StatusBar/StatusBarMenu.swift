import SwiftUI

struct StatusBarMenu: View {
  @ObservedObject var store: DeploymentStore
  let openURL: (URL) -> Void

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
