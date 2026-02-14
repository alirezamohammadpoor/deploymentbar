import SwiftUI
import AppKit

struct DeploymentRowView: View {
  let deployment: Deployment
  let checkStatus: AggregateCheckStatus?
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
    VStack(alignment: .leading, spacing: 0) {
      // Collapsed content (always visible)
      collapsedContent
        .padding(.horizontal, Geist.Layout.rowPaddingH)
        .padding(.vertical, Geist.Layout.rowPaddingV)

      // Expanded actions in bordered container
      if isExpanded {
        expandedActionsContainer
          .padding(.horizontal, Geist.Layout.rowPaddingH)
          .padding(.bottom, Geist.Layout.spacingSM)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .background(isHovered ? Geist.Colors.rowHover : Color.clear)
    .overlay(
      RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
        .strokeBorder(Color.accentColor, lineWidth: 2)
        .opacity(isFocused ? 1 : 0)
        .padding(2)
    )
    .contentShape(Rectangle())
    .onTapGesture {
      onToggleExpand()
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
            .foregroundColor(Geist.Colors.gray700)

          Text("·")
            .font(Geist.Typography.timestamp)
            .foregroundColor(Geist.Colors.gray700)
            .padding(.horizontal, 2)
        }

        Text(relativeTime)
          .font(Geist.Typography.timestamp)
          .foregroundColor(Geist.Colors.gray700)
      }

      // Line 2: Commit message (indented to align with project name)
      HStack(spacing: Geist.Layout.spacingSM) {
        Color.clear
          .frame(width: Geist.Layout.statusDotSize)

        if let commitMessage = deployment.commitMessage {
          Text(commitMessage)
            .font(Geist.Typography.commitMessage)
            .foregroundColor(Geist.Colors.textSecondary)
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

        if let targetLabel {
          Text(targetLabel)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(targetTextColor)
            .lineLimit(1)
            .padding(.horizontal, Geist.Layout.badgePaddingH + 2)
            .padding(.vertical, Geist.Layout.badgePaddingV)
            .background(targetBackgroundColor)
            .clipShape(Capsule())
            .overlay(
              Capsule()
                .stroke(targetBorderColor, lineWidth: 1)
            )
        }

        // Branch badge
        Text(deployment.branch ?? "—")
          .font(Geist.Typography.branchName)
          .foregroundColor(Geist.Colors.gray1000)
          .lineLimit(1)
          .padding(.horizontal, Geist.Layout.badgePaddingH + 2)
          .padding(.vertical, Geist.Layout.badgePaddingV)
          .background(Geist.Colors.badgeBackground)
          .cornerRadius(Geist.Layout.badgeCornerRadius)

        // CI status icon
        if let checkStatus, checkStatus != .none {
          Image(systemName: checkStatusIcon(checkStatus))
            .font(.system(size: 12))
            .foregroundColor(checkStatusColor(checkStatus))
        }

        // Author
        if let author = deployment.commitAuthor {
          Text("by \(author)")
            .font(Geist.Typography.author)
            .foregroundColor(Geist.Colors.gray700)
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

  // MARK: - Expanded Actions Container

  private static let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

  private var expandedActionsContainer: some View {
    LazyVGrid(columns: Self.gridColumns, spacing: 4) {
      GridActionCell(
        icon: copiedURL ? "checkmark" : "doc.on.doc",
        label: copiedURL ? "Copied" : "Copy URL",
        isAccent: copiedURL,
        action: copyDeploymentURL
      )

      if let url = previewURL {
        GridActionCell(icon: "globe", label: "Browser") { openURL(url) }
      }

      if let url = vercelDashboardURL {
        GridActionCell(icon: "arrow.up.right.square", label: "Vercel") { openURL(url) }
      }

      if let prURL = deployment.prURL, let prId = deployment.prId {
        GridActionCell(icon: "arrow.triangle.pull", label: "PR #\(prId)") { openURL(prURL) }
      }

      GridActionCell(
        icon: "arrow.clockwise",
        label: isRedeploying ? "Deploying…" : "Redeploy"
      ) {
        showRedeployAlert = true
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Geist.Colors.expandedContainerBg)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Geist.Colors.gray100, lineWidth: 1)
    )
  }

  private func viewBuildLog() {
    BuildLogWindowController.shared.showLogs(for: deployment, openURL: openURL)
  }

  // MARK: - Helpers

  private var targetLabel: String? {
    guard let target = deployment.target?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased(),
      !target.isEmpty else {
      return nil
    }

    if target == "production" {
      return "production"
    }
    return target
  }

  private var isProductionTarget: Bool {
    targetLabel == "production"
  }

  private var targetTextColor: Color {
    isProductionTarget ? Geist.Colors.accent : Geist.Colors.textSecondary
  }

  private var targetBackgroundColor: Color {
    isProductionTarget ? Geist.Colors.accent.opacity(0.14) : Geist.Colors.gray100
  }

  private var targetBorderColor: Color {
    isProductionTarget ? Geist.Colors.accent.opacity(0.45) : Geist.Colors.borderSubtle
  }

  private var vercelDashboardURL: URL? {
    guard let urlString = deployment.inspectorUrl, !urlString.isEmpty else { return nil }
    return URL(string: urlString)
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

  private func checkStatusIcon(_ status: AggregateCheckStatus) -> String {
    switch status {
    case .running: return "circle.dashed"
    case .passed: return "checkmark.circle.fill"
    case .failed: return "xmark.circle.fill"
    case .none: return ""
    }
  }

  private func checkStatusColor(_ status: AggregateCheckStatus) -> Color {
    switch status {
    case .running: return Geist.Colors.statusBuilding
    case .passed: return Geist.Colors.statusReady
    case .failed: return Geist.Colors.statusError
    case .none: return .clear
    }
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

// MARK: - Grid Action Cell

private struct GridActionCell: View {
  let icon: String
  let label: String
  var isAccent: Bool = false
  let action: () -> Void

  @State private var isHovered = false

  var body: some View {
    Button(action: action) {
      VStack(spacing: 2) {
        Image(systemName: icon)
          .font(.system(size: 15))
        Text(label)
          .font(.system(size: 9))
          .lineLimit(1)
      }
      .foregroundColor(isAccent ? Geist.Colors.statusReady : Geist.Colors.textSecondary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 4)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(isHovered ? Color.white.opacity(0.08) : Color.clear)
      )
    }
    .buttonStyle(.plain)
    .onHover { hovering in isHovered = hovering }
  }
}
