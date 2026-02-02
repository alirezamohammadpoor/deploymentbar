import SwiftUI

struct StatusBarMenu: View {
  let deployments: [Deployment]
  let openURL: (URL) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Deployments")
        .font(.headline)

      if deployments.isEmpty {
        Text("No deployments yet")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        ForEach(deployments) { deployment in
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
    .padding(12)
    .frame(width: 360)
  }

  private func previewURL(for deployment: Deployment) -> URL? {
    guard let value = deployment.url, !value.isEmpty else { return nil }
    if let url = URL(string: value), url.scheme != nil {
      return url
    }
    return URL(string: "https://\(value)")
  }
}

extension StatusBarMenu {
  static var mockDeployments: [Deployment] {
    let now = Date()
    return (0..<10).map { index in
      let state: DeploymentState
      switch index % 3 {
      case 0: state = .ready
      case 1: state = .building
      default: state = .error
      }

      return Deployment(
        id: "mock-\(index)",
        projectName: "Project \(10 - index)",
        branch: index % 2 == 0 ? "main" : "feature/alpha",
        state: state,
        url: "project-\(index).vercel.app",
        createdAt: now.addingTimeInterval(TimeInterval(-index * 90)),
        readyAt: state == .ready ? now.addingTimeInterval(TimeInterval(-index * 60)) : nil
      )
    }
  }
}
