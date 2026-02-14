import SwiftUI

struct SettingsView: View {
  @StateObject private var settings = SettingsStore.shared
  @StateObject private var authSession = AuthSession.shared
  @StateObject private var updateManager = UpdateManager.shared
  @State private var browserOptions: [BrowserOption] = BrowserOption.availableOptions()
  @State private var showSignOutConfirmation = false
  private let launchAtLoginManager = LaunchAtLoginManager()

  private let pollingOptions: [(value: TimeInterval, label: String)] = [
    (10.0, "10s"),
    (15.0, "15s"),
    (30.0, "30s"),
    (60.0, "1m"),
    (300.0, "5m"),
  ]

  private let logLineOptions: [(value: Int, label: String)] = [
    (50, "50"),
    (100, "100"),
    (200, "200"),
  ]

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Geist.Layout.spacingXL) {
        section("Advanced", description: "Manual maintenance and update tasks.", isFirst: true) {
          VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
            HStack(alignment: .center, spacing: Geist.Layout.spacingSM) {
              Button {
                Task { await updateManager.checkForUpdates() }
              } label: {
                if updateManager.isChecking {
                  HStack(spacing: Geist.Layout.spacingXS) {
                    ProgressView()
                      .controlSize(.small)
                    Text("Checking for Updates…")
                  }
                } else {
                  Text("Check for Updates")
                }
              }
              .buttonStyle(VercelSecondaryButtonStyle())
              .disabled(updateManager.isChecking)

              Text("v\(appVersion)")
                .font(Geist.Typography.Settings.helperText)
                .foregroundColor(Geist.Colors.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Geist.Colors.gray100)
                .clipShape(Capsule())
            }

            if let statusText = updateManager.statusText {
              Text(statusText)
                .font(Geist.Typography.Settings.helperText)
                .foregroundColor(updateStatusColor)
            }
          }
        }

        section("Authentication", description: "Use a personal token for direct access without OAuth.") {
          PersonalTokenView()
        }

        section("GitHub CI Checks", description: "Add a GitHub token to show CI check status on deployments. Needs the repo scope.") {
          GitHubTokenView()
        }

        section("Projects", description: "Leave everything unchecked to monitor every project.") {
          ProjectFilterView()
        }

        section("Notifications", description: "Choose which events trigger desktop alerts.") {
          VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
            Toggle("Notify on ready", isOn: $settings.notifyOnReady)
              .toggleStyle(VercelToggleStyle())
              .font(Geist.Typography.Settings.fieldLabel)
              .foregroundColor(Geist.Colors.gray1000)

            VercelCardDivider()

            Toggle("Notify on failed", isOn: $settings.notifyOnFailed)
              .toggleStyle(VercelToggleStyle())
              .font(Geist.Typography.Settings.fieldLabel)
              .foregroundColor(Geist.Colors.gray1000)

            VercelCardDivider()

            Toggle("Notify on checks passed", isOn: $settings.notifyOnChecksPassed)
              .toggleStyle(VercelToggleStyle())
              .font(Geist.Typography.Settings.fieldLabel)
              .foregroundColor(Geist.Colors.gray1000)

            VercelCardDivider()

            Toggle("Notify on checks failed", isOn: $settings.notifyOnChecksFailed)
              .toggleStyle(VercelToggleStyle())
              .font(Geist.Typography.Settings.fieldLabel)
              .foregroundColor(Geist.Colors.gray1000)
          }
        }

        section("General", description: "Configure polling cadence, browser behavior, and startup.") {
          VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
            HStack {
              Text("Polling interval")
                .font(Geist.Typography.Settings.fieldLabel)
                .foregroundColor(Geist.Colors.gray1000)

              Spacer()

              VercelSegmentedControl(
                selection: $settings.pollingInterval,
                options: pollingOptions
              )
              .fixedSize()
            }

            VercelCardDivider()

            VercelDropdown(
              label: "Open links in",
              selection: $settings.browserBundleId,
              options: browserOptions.map { ($0.id, $0.displayName) }
            )

            VercelCardDivider()

            Toggle("Launch at login", isOn: $settings.launchAtLogin)
              .toggleStyle(VercelToggleStyle())
              .font(Geist.Typography.Settings.fieldLabel)
              .foregroundColor(Geist.Colors.gray1000)
              .onChange(of: settings.launchAtLogin) { _, newValue in
                let success = launchAtLoginManager.setEnabled(newValue)
                if !success {
                  settings.launchAtLogin = launchAtLoginManager.isEnabled()
                }
              }
          }
        }

        section("Build Logs", description: "Default number of lines loaded when opening a build log.") {
          HStack {
            Text("Default log lines")
              .font(Geist.Typography.Settings.fieldLabel)
              .foregroundColor(Geist.Colors.gray1000)

            Spacer()

            VercelSegmentedControl(
              selection: $settings.defaultLogLines,
              options: logLineOptions
            )
            .fixedSize()
          }
        }

        if authSession.status == .signedIn {
          section("Account", description: "Sign out from your current session.") {
            Button {
              showSignOutConfirmation = true
            } label: {
              HStack(spacing: Geist.Layout.spacingXS) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
              }
              .font(Geist.Typography.Settings.button)
            }
            .buttonStyle(VercelDestructiveButtonStyle())
          }
        }
      }
      .padding(.horizontal, Geist.Layout.settingsHPadding)
      .padding(.vertical, Geist.Layout.settingsVPadding)
    }
    .scrollIndicators(.visible)
    .frame(width: Geist.Layout.settingsWidth, height: Geist.Layout.settingsHeight)
    .background(Geist.Colors.backgroundPrimary)
    .alert("Sign Out", isPresented: $showSignOutConfirmation) {
      Button("Cancel", role: .cancel) { }
      Button("Sign Out", role: .destructive) {
        authSession.signOut()
      }
    } message: {
      Text("Are you sure you want to sign out?")
    }
    .onAppear {
      browserOptions = BrowserOption.availableOptions()

      // Snap non-standard polling values to 30s
      let validIntervals: Set<TimeInterval> = [10, 15, 30, 60, 300]
      if !validIntervals.contains(settings.pollingInterval) {
        settings.pollingInterval = 30
      }
    }
  }

  private var updateStatusColor: Color {
    switch updateManager.statusLevel {
    case .info:
      return Geist.Colors.textSecondary
    case .success:
      return Geist.Colors.statusReady
    case .error:
      return Geist.Colors.statusError
    }
  }

  private var appVersion: String {
    let info = Bundle.main.infoDictionary ?? [:]
    let short = (info["CFBundleShortVersionString"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let short, !short.isEmpty {
      return short
    }
    let build = (info["CFBundleVersion"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    return (build?.isEmpty == false) ? build! : "unknown"
  }

  // MARK: - Helpers

  private func section<Content: View>(
    _ title: String,
    description: String,
    isFirst: Bool = false,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
      VercelSectionHeader(title: title)
        .padding(.top, isFirst ? 0 : 0)

      Text(description)
        .font(Geist.Typography.Settings.helperText)
        .foregroundColor(Geist.Colors.textSecondary)

      VercelSectionCard {
        content()
      }
    }
  }
}
