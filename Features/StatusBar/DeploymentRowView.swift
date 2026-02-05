import SwiftUI
import AppKit

struct DeploymentRowView: View {
  let deployment: Deployment
  let relativeTime: String
  let isExpanded: Bool
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

      // For failed deployments, show prominent View Build Log button
      if deployment.state == .error {
        failedDeploymentActions
      } else {
        regularActions
      }
    }
  }

  private var failedDeploymentActions: some View {
    VStack(alignment: .leading, spacing: Theme.Layout.spacingSM) {
      // Primary action: View Build Log
      Button {
        viewBuildLog()
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "doc.text.magnifyingglass")
            .font(.system(size: 12))
          Text("View Build Log")
            .font(Theme.Typography.caption)
        }
      }
      .buttonStyle(.borderedProminent)
      .tint(Theme.Colors.statusError)
      .controlSize(.small)

      // Secondary actions
      HStack(spacing: Theme.Layout.spacingSM) {
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

        Spacer()
      }
    }
    .padding(.leading, Theme.Layout.statusDotSize + Theme.Layout.spacingSM)
  }

  private var regularActions: some View {
    VStack(alignment: .leading, spacing: Theme.Layout.spacingSM) {
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

      // Action buttons row (Redeploy, Rollback)
      HStack(spacing: Theme.Layout.spacingSM) {
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
              .font(Theme.Typography.caption)
          }
          .foregroundColor(Theme.Colors.textSecondary)
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
                .font(Theme.Typography.caption)
            }
            .foregroundColor(Theme.Colors.statusError)
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .disabled(isRedeploying || isRollingBack)
        }

        Spacer()
      }

      Spacer()
    }
    .padding(.leading, Theme.Layout.statusDotSize + Theme.Layout.spacingSM)
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
      pulseOpacity = 0.3
    }
  }

  // MARK: - Redeploy / Rollback

  private func performRedeploy() {
    guard !isRedeploying else { return }
    isRedeploying = true
    actionError = nil

    Task {
      do {
        guard let config = VercelAuthConfig.load() else {
          throw APIError.invalidResponse
        }

        let credentialStore = CredentialStore()
        let tokenProvider: () -> String? = {
          credentialStore.loadPersonalToken() ?? credentialStore.loadTokens()?.accessToken
        }

        let client = VercelAPIClientImpl(config: config, tokenProvider: tokenProvider)
        let teamId = credentialStore.loadTokens()?.teamId

        // We need the git source info from the original deployment
        // For now, we'll use the branch info we have
        guard let branch = deployment.branch else {
          throw APIError.invalidResponse
        }

        // Note: A real redeploy would need the git source info from the deployment metadata
        // This is a simplified version that would need enhancement
        let gitSource = GitDeploymentSource(
          type: "github",
          ref: branch,
          repoId: "" // Would need to be extracted from deployment meta
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
          actionError = errorMessage(for: error)
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
        guard let config = VercelAuthConfig.load() else {
          throw APIError.invalidResponse
        }

        let credentialStore = CredentialStore()
        let tokenProvider: () -> String? = {
          credentialStore.loadPersonalToken() ?? credentialStore.loadTokens()?.accessToken
        }

        let client = VercelAPIClientImpl(config: config, tokenProvider: tokenProvider)
        let teamId = credentialStore.loadTokens()?.teamId

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
          actionError = errorMessage(for: error)
        }
      } catch {
        await MainActor.run {
          isRollingBack = false
          actionError = "Rollback failed"
        }
      }
    }
  }

  private func errorMessage(for error: APIError) -> String {
    switch error {
    case .forbidden:
      return "You don't have permission to perform this action"
    case .unauthorized:
      return "Please sign in again"
    case .rateLimited:
      return "Rate limited - try again later"
    case .serverError:
      return "Server error - try again"
    default:
      return "Action failed"
    }
  }
}
