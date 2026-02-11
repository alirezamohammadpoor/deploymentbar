import SwiftUI
import AppKit

struct DeploymentRowView: View {
  let deployment: Deployment
  let relativeTime: String
  let isExpanded: Bool
  let isFocused: Bool
  let onToggleExpand: () -> Void
  let openURL: (URL) -> Void
  let onRefresh: () -> Void

  @State private var isHovered = false
  @State private var pulseOpacity: Double = 1.0
  @State private var copiedURL = false
  @State private var showRedeployAlert = false
  @State private var showRollbackAlert = false
  @State private var isRedeploying = false
  @State private var isRollingBack = false
  @State private var actionError: String?

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
    .frame(height: isExpanded ? Geist.Layout.rowExpandedHeight : Geist.Layout.rowHeight)
    .padding(.horizontal, Geist.Layout.rowPaddingH)
    .padding(.vertical, Geist.Layout.rowPaddingV)
    .background(isExpanded ? Geist.Colors.rowExpanded : isHovered ? Geist.Colors.rowHover : Color.clear)
    .overlay(
      RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
        .strokeBorder(Color.accentColor, lineWidth: 2)
        .opacity(isFocused ? 1 : 0)
        .padding(2)
    )
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
    .contextMenu {
      Button {
        copyDeploymentURL()
      } label: {
        Label("Copy Deploy URL", systemImage: "doc.on.doc")
      }

      if let sha = deployment.shortCommitSha {
        Button {
          copyCommitHash()
        } label: {
          Label("Copy Commit Hash (\(sha))", systemImage: "number")
        }
      }

      Divider()

      if let url = vercelDashboardURL {
        Button {
          openURL(url)
        } label: {
          Label("Open in Vercel", systemImage: "safari")
        }
      }

      if let url = previewURL {
        Button {
          openURL(url)
        } label: {
          Label("Open Preview URL", systemImage: "globe")
        }
      }

      if let prURL = deployment.prURL {
        Button {
          openURL(prURL)
        } label: {
          Label("Open PR in GitHub", systemImage: "arrow.up.right.square")
        }
      }

      Divider()

      // View Build Log
      Button {
        viewBuildLog()
      } label: {
        Label("View Build Log", systemImage: "doc.text.magnifyingglass")
      }

      // Redeploy
      Button {
        showRedeployAlert = true
      } label: {
        Label("Redeploy...", systemImage: "arrow.clockwise.circle")
      }
      .disabled(isRedeploying)

      // Rollback (only for production deploys)
      if deployment.target == "production" && deployment.state == .ready {
        Button(role: .destructive) {
          showRollbackAlert = true
        } label: {
          Label("Rollback to Previous...", systemImage: "arrow.uturn.backward.circle")
        }
        .disabled(isRollingBack)
      }
    }
    .alert("Redeploy", isPresented: $showRedeployAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Redeploy") {
        performRedeploy()
      }
    } message: {
      Text("Are you sure you want to redeploy \(deployment.projectName)?")
    }
    .alert("Rollback", isPresented: $showRollbackAlert) {
      Button("Cancel", role: .cancel) { }
      Button("Rollback", role: .destructive) {
        performRollback()
      }
    } message: {
      Text("Are you sure you want to rollback \(deployment.projectName) to this deployment?")
    }
    .alert("Error", isPresented: .constant(actionError != nil)) {
      Button("OK") {
        actionError = nil
      }
    } message: {
      if let error = actionError {
        Text(error)
      }
    }
  }

  // MARK: - Collapsed Content

  private var collapsedContent: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Line 1: Status dot, project name, build duration, relative time
      HStack(spacing: Geist.Layout.spacingSM) {
        Circle()
          .fill(Geist.Colors.status(for: deployment.state))
          .frame(width: Geist.Layout.statusDotSize, height: Geist.Layout.statusDotSize)
          .opacity(shouldAnimate ? pulseOpacity : 1.0)

        Text(deployment.projectName)
          .font(Geist.Typography.projectName)
          .foregroundColor(Geist.Colors.textPrimary)
          .lineLimit(1)

        Spacer()

        if deployment.state == .ready, let _ = deployment.buildDuration {
          Text(deployment.formattedBuildDuration)
            .font(Geist.Typography.buildDuration)
            .foregroundColor(Geist.Colors.textTertiary)

          Text("·")
            .font(Geist.Typography.timestamp)
            .foregroundColor(Geist.Colors.textTertiary)
            .padding(.horizontal, 2)
        }

        Text(relativeTime)
          .font(Geist.Typography.timestamp)
          .foregroundColor(Geist.Colors.textTertiary)
      }

      // Line 2: Commit message (indented to align with project name)
      HStack(spacing: Geist.Layout.spacingSM) {
        Color.clear
          .frame(width: Geist.Layout.statusDotSize)

        if let commitMessage = deployment.commitMessage {
          Text(commitMessage)
            .font(Geist.Typography.commitMessage)
            .foregroundColor(Geist.Colors.textPrimary)
            .lineLimit(isExpanded ? 3 : 1)
        } else {
          Text("No commit message")
            .font(Geist.Typography.commitMessage)
            .foregroundColor(Geist.Colors.textTertiary)
            .italic()
            .lineLimit(1)
        }
      }

      // Line 3: Branch badge, author, PR link
      HStack(spacing: Geist.Layout.spacingSM) {
        Color.clear
          .frame(width: Geist.Layout.statusDotSize)

        // Branch badge
        Text(deployment.branch ?? "—")
          .font(Geist.Typography.branchName)
          .foregroundColor(Geist.Colors.textSecondary)
          .lineLimit(1)
          .padding(.horizontal, Geist.Layout.badgePaddingH)
          .padding(.vertical, Geist.Layout.badgePaddingV)
          .background(Geist.Colors.badgeBackground)
          .cornerRadius(Geist.Layout.badgeCornerRadius)

        // Author
        if let author = deployment.commitAuthor {
          Text("by \(author)")
            .font(Geist.Typography.author)
            .foregroundColor(Geist.Colors.textTertiary)
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
                .font(Geist.Typography.captionSmall)
            }
          }
          .foregroundColor(Geist.Colors.textTertiary)
        }
      }
    }
  }

  // MARK: - Expanded Content

  private var expandedContent: some View {
    VStack(alignment: .leading, spacing: 0) {
      Divider()
        .padding(.top, 4)
        .padding(.bottom, 8)

      // For failed deployments, show prominent View Build Log button
      if deployment.state == .error {
        failedDeploymentActions
      } else {
        regularActions
      }
    }
    .padding(.bottom, 8)
  }

  private var failedDeploymentActions: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
      // Primary action: View Build Log
      Button {
        viewBuildLog()
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "doc.text.magnifyingglass")
            .font(.system(size: 12))
          Text("View Build Log")
            .font(Geist.Typography.caption)
        }
      }
      .buttonStyle(.borderedProminent)
      .tint(Geist.Colors.statusError)
      .controlSize(.small)

      // Secondary actions
      HStack(alignment: .center, spacing: 8) {
        ActionButton(
          icon: copiedURL ? "checkmark" : "doc.on.doc",
          label: copiedURL ? "Copied!" : "Copy URL",
          color: copiedURL ? Geist.Colors.statusReady : Geist.Colors.buttonText,
          action: copyDeploymentURL
        )

        if let url = vercelDashboardURL {
          ActionButton(icon: "safari", label: "Open in Vercel") { openURL(url) }
        }

        Spacer()
      }
    }
    .padding(.leading, Geist.Layout.statusDotSize + Geist.Layout.spacingSM)
  }

  private var regularActions: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .center, spacing: 8) {
        ActionButton(
          icon: copiedURL ? "checkmark" : "doc.on.doc",
          label: copiedURL ? "Copied!" : "Copy URL",
          color: copiedURL ? Geist.Colors.statusReady : Geist.Colors.buttonText,
          action: copyDeploymentURL
        )

        if let url = previewURL {
          ActionButton(icon: "globe", label: "Open in Browser") { openURL(url) }
        }

        if let url = vercelDashboardURL {
          ActionButton(icon: "safari", label: "Open in Vercel") { openURL(url) }
        }

        if let prURL = deployment.prURL, let prId = deployment.prId {
          ActionButton(icon: "arrow.up.right.square", label: "#\(prId)") { openURL(prURL) }
        }

        Spacer()
      }

      // Action buttons row (Redeploy, Rollback)
      HStack(alignment: .center, spacing: 8) {
        // Redeploy button
        Button {
          showRedeployAlert = true
        } label: {
          HStack(spacing: 4) {
            if isRedeploying {
              ProgressView()
                .scaleEffect(0.6)
                .frame(width: 12, height: 12)
            } else {
              Image(systemName: "arrow.clockwise.circle")
                .font(.system(size: 11))
            }
            Text("Redeploy")
              .font(Geist.Typography.caption)
          }
          .foregroundColor(Geist.Colors.buttonText)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(isRedeploying || isRollingBack)

        // Rollback button (only for production deploys)
        if deployment.target == "production" && deployment.state == .ready {
          Button {
            showRollbackAlert = true
          } label: {
            HStack(spacing: 4) {
              if isRollingBack {
                ProgressView()
                  .scaleEffect(0.6)
                  .frame(width: 12, height: 12)
              } else {
                Image(systemName: "arrow.uturn.backward.circle")
                  .font(.system(size: 11))
              }
              Text("Rollback")
                .font(Geist.Typography.caption)
            }
            .foregroundColor(Geist.Colors.statusError)
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .disabled(isRedeploying || isRollingBack)
        }

        Spacer()
      }

      Spacer()
    }
    .padding(.leading, Geist.Layout.statusDotSize + Geist.Layout.spacingSM)
  }

  private func viewBuildLog() {
    BuildLogWindowController.shared.showLogs(for: deployment, openURL: openURL)
  }

  // MARK: - Helpers

  private var vercelDashboardURL: URL? {
    guard let projectId = deployment.projectId else { return nil }
    return URL(string: "https://vercel.com/~/\(projectId)/\(deployment.id)")
  }

  private var previewURL: URL? {
    guard let urlString = deployment.url, !urlString.isEmpty else { return nil }
    if urlString.hasPrefix("http") {
      return URL(string: urlString)
    }
    return URL(string: "https://\(urlString)")
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

  private func copyCommitHash() {
    guard let sha = deployment.commitSha else { return }
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(sha, forType: .string)
  }

  private func startPulseAnimation() {
    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
      pulseOpacity = 0.4
    }
  }

  // MARK: - Redeploy / Rollback

  private func performRedeploy() {
    guard !isRedeploying else { return }
    isRedeploying = true
    actionError = nil

    Task {
      do {
        let (client, teamId) = try APIClientFactory.create()

        guard let branch = deployment.branch else {
          throw APIError.invalidResponse
        }

        let gitSource = GitDeploymentSource(
          type: "github",
          ref: branch,
          repoId: ""
        )

        _ = try await client.createDeployment(
          name: deployment.projectName,
          target: deployment.target,
          gitSource: gitSource,
          teamId: teamId
        )

        await MainActor.run {
          isRedeploying = false
          onRefresh()
        }
      } catch let error as APIError {
        await MainActor.run {
          isRedeploying = false
          actionError = error.userMessage
        }
      } catch {
        await MainActor.run {
          isRedeploying = false
          actionError = "Redeploy failed"
        }
      }
    }
  }

  private func performRollback() {
    guard !isRollingBack else { return }
    guard let projectId = deployment.projectId else { return }
    isRollingBack = true
    actionError = nil

    Task {
      do {
        let (client, teamId) = try APIClientFactory.create()

        try await client.rollbackProject(
          projectId: projectId,
          deploymentId: deployment.id,
          teamId: teamId
        )

        await MainActor.run {
          isRollingBack = false
          onRefresh()
        }
      } catch let error as APIError {
        await MainActor.run {
          isRollingBack = false
          actionError = error.userMessage
        }
      } catch {
        await MainActor.run {
          isRollingBack = false
          actionError = "Rollback failed"
        }
      }
    }
  }
}

// MARK: - Reusable Action Button

private struct ActionButton: View {
  let icon: String
  let label: String
  var color: Color = Geist.Colors.buttonText
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 11))
        Text(label)
          .font(Geist.Typography.caption)
      }
      .foregroundColor(color)
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
  }
}
