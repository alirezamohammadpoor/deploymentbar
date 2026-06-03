import SwiftUI

/// Custom update screen (Figma "Update" flow), Vercel-skinned.
/// Presentational only — Sparkle still performs the actual download/install.
struct UpdateView: View {
  let onSeeWhatsNew: () -> Void

  @ObservedObject private var updateManager = UpdateManager.shared

  var body: some View {
    VStack(spacing: Geist.Layout.spacingLG) {
      Spacer()
      indicator
      VStack(spacing: Geist.Layout.spacingSM) {
        Text(title)
          .font(.system(size: 20, weight: .semibold))
          .foregroundColor(Geist.Colors.textPrimary)
        Text(subtitle)
          .font(.system(size: 13))
          .foregroundColor(Geist.Colors.textSecondary)
          .multilineTextAlignment(.center)
      }
      actions
      Spacer()
      Text("v\(appVersion)")
        .font(Geist.Typography.Settings.helperText)
        .foregroundColor(Geist.Colors.textTertiary)
    }
    .padding(Geist.Layout.spacingXL)
    .frame(width: 560, height: 440)
    .background(Geist.Colors.backgroundPrimary)
    .onAppear { Task { await updateManager.checkForUpdates() } }
  }

  // MARK: - Indicator

  @ViewBuilder
  private var indicator: some View {
    switch updateManager.status {
    case .idle, .checking:
      RingSpinner(animated: true)
    case .updateInitiated:
      RingSpinner(animated: false)
    case .upToDate:
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 52)).foregroundColor(Geist.Colors.statusReady)
    case .failed:
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 48)).foregroundColor(Geist.Colors.statusWarning)
    }
  }

  // MARK: - Actions

  @ViewBuilder
  private var actions: some View {
    switch updateManager.status {
    case .updateInitiated:
      HStack(spacing: Geist.Layout.spacingSM) {
        Button("Install Update") { Task { await updateManager.checkForUpdates() } }
          .buttonStyle(VercelPrimaryButtonStyle())
        Button("See what's new") { onSeeWhatsNew() }
          .buttonStyle(VercelSecondaryButtonStyle())
      }
    case .failed:
      Button("Retry") { Task { await updateManager.checkForUpdates() } }
        .buttonStyle(VercelPrimaryButtonStyle())
    case .idle, .checking, .upToDate:
      EmptyView()
    }
  }

  // MARK: - Copy

  private var title: String {
    switch updateManager.status {
    case .idle, .checking: return "Checking for updates"
    case .updateInitiated: return "Update ready to install"
    case .upToDate: return "You're up to date"
    case .failed: return "Update check failed"
    }
  }

  private var subtitle: String {
    switch updateManager.status {
    case .idle, .checking: return "Looking for a new version of Deploymentbar…"
    case .updateInitiated: return "A new version is ready. Follow the prompts to install."
    case .upToDate: return "You're running the latest version of Deploymentbar."
    case .failed: return updateManager.statusText ?? "Something went wrong. Try again."
    }
  }

  private var appVersion: String {
    let info = Bundle.main.infoDictionary ?? [:]
    return (info["CFBundleShortVersionString"] as? String) ?? "unknown"
  }
}

/// Accent ring; spins continuously when `animated`.
struct RingSpinner: View {
  var animated: Bool
  @State private var rotate = false

  var body: some View {
    Circle()
      .trim(from: 0, to: 0.78)
      .stroke(Geist.Colors.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
      .frame(width: 56, height: 56)
      .rotationEffect(.degrees(rotate ? 360 : 0))
      .onAppear {
        guard animated, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) { rotate = true }
      }
  }
}
