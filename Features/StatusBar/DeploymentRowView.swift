import SwiftUI

struct DeploymentRowView: View {
  let deployment: Deployment
  let relativeTime: String

  @State private var isHovered = false
  @State private var pulseOpacity: Double = 1.0

  private var shouldAnimate: Bool {
    (deployment.state == .building || deployment.state == .queued) &&
    !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Line 1: Status dot, project name, build duration, relative time
      HStack(spacing: Theme.Layout.spacingSM) {
        Circle()
          .fill(Theme.Colors.status(for: deployment.state))
          .frame(width: Theme.Layout.statusDotSize, height: Theme.Layout.statusDotSize)
          .opacity(shouldAnimate ? pulseOpacity : 1.0)

        Text(deployment.projectName)
          .font(Theme.Typography.projectName)
          .foregroundColor(Theme.Colors.textPrimary)
          .lineLimit(1)

        Spacer()

        if deployment.state == .ready, let _ = deployment.buildDuration {
          Text(deployment.formattedBuildDuration)
            .font(Theme.Typography.buildDuration)
            .foregroundColor(Theme.Colors.textTertiary)
        }

        Text(relativeTime)
          .font(Theme.Typography.timestamp)
          .foregroundColor(Theme.Colors.textTertiary)
      }

      // Line 2: Commit message (indented to align with project name)
      HStack(spacing: Theme.Layout.spacingSM) {
        Color.clear
          .frame(width: Theme.Layout.statusDotSize)

        if let commitMessage = deployment.commitMessage {
          Text(commitMessage)
            .font(Theme.Typography.commitMessage)
            .foregroundColor(Theme.Colors.textSecondary)
            .lineLimit(1)
        } else {
          Text("No commit message")
            .font(Theme.Typography.commitMessage)
            .foregroundColor(Theme.Colors.textTertiary)
            .italic()
            .lineLimit(1)
        }
      }

      // Line 3: Branch badge, author, PR link
      HStack(spacing: Theme.Layout.spacingSM) {
        Color.clear
          .frame(width: Theme.Layout.statusDotSize)

        // Branch badge
        Text(deployment.branch ?? "—")
          .font(Theme.Typography.branchName)
          .foregroundColor(Theme.Colors.textSecondary)
          .lineLimit(1)
          .padding(.horizontal, Theme.Layout.badgePaddingH)
          .padding(.vertical, Theme.Layout.badgePaddingV)
          .background(Theme.Colors.backgroundSecondary)
          .cornerRadius(Theme.Layout.badgeCornerRadius)

        // Author
        if let author = deployment.commitAuthor {
          Text("by \(author)")
            .font(Theme.Typography.author)
            .foregroundColor(Theme.Colors.textTertiary)
            .lineLimit(1)
        }

        Spacer()

        // PR link indicator
        if deployment.prURL != nil {
          HStack(spacing: 2) {
            Image(systemName: "arrow.up.right.square")
              .font(.system(size: 10))
            if let prId = deployment.prId {
              Text("#\(prId)")
                .font(Theme.Typography.captionSmall)
            }
          }
          .foregroundColor(Theme.Colors.textTertiary)
        }
      }
    }
    .frame(height: Theme.Layout.rowHeight)
    .padding(.horizontal, Theme.Layout.spacingSM)
    .padding(.vertical, Theme.Layout.spacingXS)
    .background(isHovered ? Theme.Colors.backgroundSecondary : Color.clear)
    .contentShape(Rectangle())
    .onHover { hovering in
      isHovered = hovering
    }
    .onAppear {
      if shouldAnimate {
        startPulseAnimation()
      }
    }
    .onChange(of: deployment.state) { _, newState in
      if newState == .building || newState == .queued {
        if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
          startPulseAnimation()
        }
      }
    }
  }

  private func startPulseAnimation() {
    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
      pulseOpacity = 0.3
    }
  }
}
