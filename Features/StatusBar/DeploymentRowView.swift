import SwiftUI

struct DeploymentRowView: View {
  let deployment: Deployment
  let relativeTime: String

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(deployment.projectName)
          .font(.subheadline)
        Text(deployment.branch ?? "-")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 4) {
        statusBadge
        Text(relativeTime)
          .font(.caption2)
          .foregroundColor(.secondary)
      }
    }
    .padding(.vertical, 6)
  }

  private var statusBadge: some View {
    Text(statusText)
      .font(.caption2)
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(statusColor.opacity(0.15))
      .foregroundColor(statusColor)
      .clipShape(Capsule())
  }

  private var statusText: String {
    switch deployment.state {
    case .building: return "Building"
    case .ready: return "Ready"
    case .error: return "Failed"
    case .canceled: return "Canceled"
    }
  }

  private var statusColor: Color {
    switch deployment.state {
    case .building: return .orange
    case .ready: return .green
    case .error: return .red
    case .canceled: return .gray
    }
  }
}
