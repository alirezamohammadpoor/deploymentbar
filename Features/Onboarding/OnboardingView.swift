import AppKit
import SwiftUI

/// First-run setup guide. Six wired steps modeled on the Figma onboarding tour.
struct OnboardingView: View {
  enum Step: Int, CaseIterable {
    case welcome, connect, github, projects, notifications, done
  }

  let onClose: () -> Void
  let openSettings: () -> Void

  @State private var step: Step = .welcome
  @ObservedObject private var auth = AuthSession.shared
  @ObservedObject private var settings = SettingsStore.shared
  @ObservedObject private var projectStore = ProjectStore.shared
  private let credentialStore = CredentialStore.shared

  @State private var patInput = ""
  @State private var githubInput = ""
  @State private var githubValidating = false
  @State private var githubLogin: String?
  @State private var githubError: String?

  private let pollingOptions: [(value: TimeInterval, label: String)] =
    [(10, "10s"), (30, "30s"), (60, "1m"), (300, "5m")]

  var body: some View {
    VStack(spacing: 0) {
      progressDots
        .padding(.bottom, Geist.Layout.spacingLG)

      VStack(alignment: .leading, spacing: Geist.Layout.spacingMD) {
        content
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Spacer(minLength: Geist.Layout.spacingLG)

      navBar
    }
    .padding(28)
    .frame(width: 480, height: 560)
    .background(Geist.Colors.backgroundPrimary)
    .onChange(of: auth.status) { _, newValue in
      if case .signedIn = newValue, step == .connect {
        // Let the green "Connected as …" state register before moving on.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
          if step == .connect { advance() }
        }
      }
    }
  }

  // MARK: - Progress

  private var progressDots: some View {
    HStack(spacing: 6) {
      ForEach(Step.allCases, id: \.rawValue) { s in
        Circle()
          .fill(s == step ? Geist.Colors.accent : Geist.Colors.gray400)
          .frame(width: 6, height: 6)
      }
      Spacer()
    }
  }

  // MARK: - Content

  @ViewBuilder
  private var content: some View {
    switch step {
    case .welcome: welcomeStep
    case .connect: connectStep
    case .github: githubStep
    case .projects: projectsStep
    case .notifications: notificationsStep
    case .done: doneStep
    }
  }

  private func title(_ text: String) -> some View {
    Text(text).font(.system(size: 20, weight: .semibold)).foregroundColor(Geist.Colors.textPrimary)
  }

  private func subtitle(_ text: String) -> some View {
    Text(text).font(.system(size: 13)).foregroundColor(Geist.Colors.textSecondary)
      .fixedSize(horizontal: false, vertical: true)
  }

  private var welcomeStep: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingMD) {
      Image(nsImage: NSApp.applicationIconImage)
        .resizable().frame(width: 44, height: 44).cornerRadius(10)
      title("Welcome to Deploymentbar")
      subtitle("Monitor every Vercel deployment from your menu bar — status, CI checks, and one-click actions.")
    }
  }

  private var connectStep: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingMD) {
      Image(systemName: "key.horizontal").font(.system(size: 28)).foregroundColor(Geist.Colors.accent)
      title("Add your Vercel token")
      subtitle("Deploymentbar reads your deployments with one Vercel token. Create it, paste it below — it stays only on this Mac.")

      if case .signedIn = auth.status {
        Label(auth.connectedAs.map { "Connected as \($0)" } ?? "Connected", systemImage: "checkmark.circle.fill")
          .font(Geist.Typography.caption).foregroundColor(Geist.Colors.statusReady)
      } else {
        tokenCreateRow(label: "Create a token on Vercel", url: VercelEndpoints.accountTokensPage)
        guideHints([
          "Name it anything — e.g. \"Deploymentbar\"",
          "Scope: your account for personal projects, or a team to watch that team",
          "Expiration: your call — \"No Expiration\" for set-and-forget",
        ])
        HStack(spacing: Geist.Layout.spacingSM) {
          SecureField("Paste token", text: $patInput)
            .textFieldStyle(.plain).vercelTextField()
          Button(auth.isConnecting ? "Verifying…" : "Connect") { auth.connect(token: patInput) }
            .buttonStyle(VercelPrimaryButtonStyle())
            .disabled(auth.isConnecting || patInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        if let message = auth.connectError {
          Text(message).font(Geist.Typography.caption).foregroundColor(Geist.Colors.statusError)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  private var githubStep: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingMD) {
      HStack(spacing: Geist.Layout.spacingSM) {
        Image(systemName: "checkmark.seal").font(.system(size: 26)).foregroundColor(Geist.Colors.textPrimary)
        Text("OPTIONAL")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(Geist.Colors.accent)
          .padding(.horizontal, 8).padding(.vertical, 2)
          .background(Geist.Colors.bgAccentSubtle)
          .overlay(Capsule().stroke(Geist.Colors.borderAccentSubtle, lineWidth: 1))
          .clipShape(Capsule())
      }
      title("Add a GitHub token for CI checks")
      subtitle("Shows lint, test, and build status on each deployment. Skip and add it later in Settings.")

      if let githubLogin {
        Label("Connected as @\(githubLogin)", systemImage: "checkmark.circle.fill")
          .font(Geist.Typography.caption).foregroundColor(Geist.Colors.statusReady)
      } else {
        tokenCreateRow(label: "Create a token on GitHub", url: GitHubEndpoints.newTokenPage)
        guideHints([
          "Scope \"repo\" is pre-selected — it reads CI checks on private repos",
          "Public repos only? \"public_repo\" is enough",
          "Set an expiration if you rotate tokens",
        ])
        HStack(spacing: Geist.Layout.spacingSM) {
          SecureField("Paste GitHub token", text: $githubInput)
            .textFieldStyle(.plain).vercelTextField()
          Button(githubValidating ? "Verifying…" : "Connect") { connectGitHub() }
            .buttonStyle(VercelPrimaryButtonStyle())
            .disabled(githubValidating || githubInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        if let githubError {
          Text(githubError).font(Geist.Typography.caption).foregroundColor(Geist.Colors.statusError)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  private func connectGitHub() {
    let token = githubInput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !token.isEmpty else { return }
    githubValidating = true
    githubError = nil
    Task {
      if let login = await GitHubValidator.fetchLogin(token: token) {
        credentialStore.saveGitHubToken(token)
        githubLogin = login
        githubInput = ""
      } else {
        githubError = "That token didn't work — check it has the repo scope and isn't expired."
      }
      githubValidating = false
    }
  }

  private var projectsStep: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingMD) {
      title("Pick projects to monitor")
      subtitle("Choose which projects appear — or leave all selected to watch everything.")
      Group {
        if projectStore.isLoading {
          ProgressView().controlSize(.small)
        } else if projectStore.projects.isEmpty {
          Text("No projects found").font(Geist.Typography.caption).foregroundColor(Geist.Colors.textTertiary)
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
              ForEach(projectStore.projects) { project in
                VercelCheckmarkRow(name: project.name, isSelected: binding(for: project.id))
              }
            }
          }
          .frame(maxHeight: 200)
        }
      }
    }
    .onAppear { if projectStore.projects.isEmpty { projectStore.refresh() } }
  }

  private var notificationsStep: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingMD) {
      title("Notifications & polling")
      subtitle("Get notified when deployments succeed or fail, and choose how often we check.")
      Toggle("Notify on ready", isOn: $settings.notifyOnReady)
        .toggleStyle(VercelToggleStyle()).font(Geist.Typography.Settings.fieldLabel).foregroundColor(Geist.Colors.gray1000)
      Toggle("Notify on failed", isOn: $settings.notifyOnFailed)
        .toggleStyle(VercelToggleStyle()).font(Geist.Typography.Settings.fieldLabel).foregroundColor(Geist.Colors.gray1000)
      HStack {
        Text("Polling interval").font(Geist.Typography.Settings.fieldLabel).foregroundColor(Geist.Colors.gray1000)
        Spacer()
        VercelSegmentedControl(selection: $settings.pollingInterval, options: pollingOptions).fixedSize()
      }
    }
  }

  private var doneStep: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingMD) {
      Image(systemName: "checkmark.circle.fill").font(.system(size: 40)).foregroundColor(Geist.Colors.statusReady)
      title("You're all set")
      VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
        tipRow("Find Deploymentbar in your menu bar")
        tipRow("Right-click a failed deploy → Copy Error")
        tipRow("Open Settings anytime to adjust")
      }
    }
  }

  private func tipRow(_ text: String) -> some View {
    HStack(spacing: Geist.Layout.spacingSM) {
      Image(systemName: "checkmark.circle.fill").font(.system(size: 13)).foregroundColor(Geist.Colors.statusReady)
      Text(text).font(.system(size: 12)).foregroundColor(Geist.Colors.textSecondary)
    }
  }

  // MARK: - Reusable guide pieces

  private func tokenCreateRow(label: String, url: URL) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Button {
        BrowserLauncher().open(url: url)
      } label: {
        HStack(spacing: 4) {
          Text(label)
          Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .semibold))
        }
      }
      .buttonStyle(VercelSecondaryButtonStyle())

      Button("Didn't open? Copy link") {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.absoluteString, forType: .string)
      }
      .buttonStyle(.plain)
      .font(Geist.Typography.caption)
      .foregroundColor(Geist.Colors.textTertiary)
    }
  }

  private func guideHints(_ items: [String]) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      ForEach(Array(items.enumerated()), id: \.offset) { _, item in
        HStack(alignment: .top, spacing: 8) {
          Circle().fill(Geist.Colors.textTertiary).frame(width: 4, height: 4).padding(.top, 6)
          Text(item).font(Geist.Typography.caption).foregroundColor(Geist.Colors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
    }
  }

  // MARK: - Nav

  private var navBar: some View {
    HStack(spacing: Geist.Layout.spacingSM) {
      if step != .welcome {
        Button("Back") { back() }.buttonStyle(.plain)
          .font(Geist.Typography.caption).foregroundColor(Geist.Colors.textSecondary)
      }
      Spacer()
      if step == .done {
        Button("Open Settings") { openSettings() }.buttonStyle(VercelSecondaryButtonStyle())
        Button("Finish") { finish() }.buttonStyle(VercelPrimaryButtonStyle())
      } else {
        Button(step == .github ? "Skip this step" : "Skip") { step == .github ? advance() : finish() }
          .buttonStyle(.plain).font(Geist.Typography.caption).foregroundColor(Geist.Colors.textSecondary)
        Button(step == .welcome ? "Get started" : "Next") { advance() }
          .buttonStyle(VercelPrimaryButtonStyle())
      }
    }
  }

  // MARK: - Actions

  private func advance() {
    guard let next = Step(rawValue: step.rawValue + 1) else { finish(); return }
    withAnimation(Geist.Motion.easeOut) { step = next }
  }

  private func back() {
    guard let prev = Step(rawValue: step.rawValue - 1) else { return }
    withAnimation(Geist.Motion.easeOut) { step = prev }
  }

  private func finish() {
    settings.hasCompletedOnboarding = true
    onClose()
  }

  private func binding(for projectId: String) -> Binding<Bool> {
    Binding(
      get: { settings.selectedProjectIds.contains(projectId) },
      set: { isOn in
        if isOn { settings.selectedProjectIds.insert(projectId) }
        else { settings.selectedProjectIds.remove(projectId) }
      }
    )
  }
}
