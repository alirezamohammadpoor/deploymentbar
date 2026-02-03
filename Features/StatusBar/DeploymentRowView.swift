import SwiftUI

struct DeploymentRowView: View {
  let deployment: Deployment
  let relativeTime: String

  @State private var isHovered = false

  var body: some View {
    HStack(spacing: Theme.Layout.spacingSM) {
      Circle()
        .fill(Theme.Colors.status(for: deployment.state))
        .frame(width: Theme.Layout.statusDotSize, height: Theme.Layout.statusDotSize)

      Text(deployment.projectName)
        .font(Theme.Typography.projectName)
        .foregroundColor(Theme.Colors.textPrimary)
        .lineLimit(1)

      Text(deployment.branch ?? "-")
        .font(Theme.Typography.branchName)
        .foregroundColor(Theme.Colors.textSecondary)
        .lineLimit(1)
        .padding(.horizontal, Theme.Layout.badgePaddingH)
        .padding(.vertical, Theme.Layout.badgePaddingV)
        .background(Theme.Colors.backgroundSecondary)
        .cornerRadius(Theme.Layout.badgeCornerRadius)

      Spacer()

      Text(relativeTime)
        .font(Theme.Typography.timestamp)
        .foregroundColor(Theme.Colors.textTertiary)
    }
    .frame(height: Theme.Layout.rowHeight)
    .padding(.horizontal, Theme.Layout.spacingSM)
    .background(isHovered ? Theme.Colors.backgroundSecondary : Color.clear)
    .contentShape(Rectangle())
    .onHover { hovering in
      isHovered = hovering
    }
  }
}
