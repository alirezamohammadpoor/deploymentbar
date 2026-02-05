import SwiftUI
import AppKit

struct DeploymentRowView: View {
  let deployment: Deployment
  let relativeTime: String
  let isExpanded: Bool
  let onToggleExpand: () -> Void
  let openURL: (URL) -> Void

  @State private var isHovered = false
  @State private var pulseOpacity: Double = 1.0
  @State private var copiedURL = false

  private var shouldAnimate: Bool {
    (deployment.state == .building || deployment.state == .queued) &&
    !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Collapsed content (always shown)
      collapsedContent

      // Expanded content
      if isExpanded {
        expandedContent
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .frame(height: isExpanded ? Theme.Layout.rowExpandedHeight : Theme.Layout.rowHeight)
    .padding(.horizontal, Theme.Layout.spacingSM)
    .padding(.vertical, Theme.Layout.spacingXS)
    .background(isHovered || isExpanded ? Theme.Colors.backgroundSecondary : Color.clear)
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.spring(dampingFraction: 0.85)) {
        onToggleExpand()
      }
    }
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

  // MARK: - Collapsed Content

  private var collapsedContent: some View {
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
            .lineLimit(isExpanded ? 3 : 1)
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
  }

  // MARK: - Expanded Content

  private var expandedContent: some View {
    VStack(alignment: .leading, spacing: Theme.Layout.spacingSM) {
      Divider()
        .padding(.vertical, 4)

      // Action buttons
      HStack(spacing: Theme.Layout.spacingSM) {
        // Copy URL button
        Button {
          copyDeploymentURL()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: copiedURL ? "checkmark" : "doc.on.doc")
              .font(.system(size: 11))
            Text(copiedURL ? "Copied!" : "Copy URL")
              .font(Theme.Typography.caption)
          }
          .foregroundColor(copiedURL ? Theme.Colors.statusReady : Theme.Colors.textSecondary)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)

        // Open in Vercel button
        if let url = vercelDashboardURL {
          Button {
            openURL(url)
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "safari")
                .font(.system(size: 11))
              Text("Open in Vercel")
                .font(Theme.Typography.caption)
            }
            .foregroundColor(Theme.Colors.textSecondary)
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }

        // Open PR button
        if let prURL = deployment.prURL {
          Button {
            openURL(prURL)
          } label: {
            HStack(spacing: 4) {
              Image(systemName: "arrow.up.right.square")
                .font(.system(size: 11))
              Text("Open PR")
                .font(Theme.Typography.caption)
            }
            .foregroundColor(Theme.Colors.textSecondary)
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }

        Spacer()
      }
      .padding(.leading, Theme.Layout.statusDotSize + Theme.Layout.spacingSM)
    }
  }

  // MARK: - Helpers

  private var vercelDashboardURL: URL? {
    guard let projectId = deployment.projectId else { return nil }
    return URL(string: "https://vercel.com/~/\(projectId)/\(deployment.id)")
  }

  private func copyDeploymentURL() {
    guard let urlString = deployment.url else { return }
    let url = urlString.hasPrefix("http") ? urlString : "https://\(urlString)"
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(url, forType: .string)

    withAnimation {
      copiedURL = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      withAnimation {
        copiedURL = false
      }
    }
  }

  private func startPulseAnimation() {
    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
      pulseOpacity = 0.3
    }
  }
}
