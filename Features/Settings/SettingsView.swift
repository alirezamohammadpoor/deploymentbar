import SwiftUI

struct SettingsView: View {
  @StateObject private var settings = SettingsStore.shared
  @StateObject private var authSession = AuthSession.shared
  @StateObject private var updaterStore = UpdaterStore.shared
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
      VStack(alignment: .leading, spacing: 0) {
        // AUTHENTICATION
        section(
          "Authentication",
          description: "Use a personal token for direct access without OAuth.",
          isFirst: true
        ) {
          PersonalTokenView()
        }

        // PROJECTS
        section(
          "Projects",
          description: "Leave everything unchecked to monitor every project."
        ) {
          ProjectFilterView()
        }

        // NOTIFICATIONS
        section("Notifications", description: "Choose which deployment states trigger alerts.") {
          VStack(alignment: .leading, spacing: 12) {
            Toggle("Notify on ready", isOn: $settings.notifyOnReady)
              .toggleStyle(VercelToggleStyle())
              .font(Geist.Typography.Settings.fieldLabel)
              .foregroundColor(Geist.Colors.gray1000)
            Toggle("Notify on failed", isOn: $settings.notifyOnFailed)
              .toggleStyle(VercelToggleStyle())
              .font(Geist.Typography.Settings.fieldLabel)
              .foregroundColor(Geist.Colors.gray1000)
          }
        }

        // GENERAL
        section("General", description: "Configure polling cadence, browser behavior, and startup.") {
          VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
              Text("Polling interval")
                .font(Geist.Typography.Settings.fieldLabel)
                .foregroundColor(Geist.Colors.gray1000)
              VercelSegmentedControl(
                selection: $settings.pollingInterval,
                options: pollingOptions
              )
            }

            VercelDropdown(
              label: "Open links in",
              selection: $settings.browserBundleId,
              options: browserOptions.map { ($0.id, $0.displayName) }
            )

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

        // UPDATES
        section("Updates", description: "Use Sparkle to check for new direct-download releases.") {
          VStack(alignment: .leading, spacing: 8) {
            Button("Check for Updates…") {
              updaterStore.checkForUpdates()
            }
            .buttonStyle(VercelSecondaryButtonStyle())

            if let feedHost = updaterStore.feedHost {
              Text("Feed: \(feedHost)")
                .font(Geist.Typography.Settings.helperText)
                .foregroundColor(Geist.Colors.textSecondary)
            } else {
              Text("Sparkle feed is not configured (set SPARKLE_FEED_URL).")
                .font(Geist.Typography.Settings.helperText)
                .foregroundColor(Geist.Colors.statusWarning)
            }

            if let updateError = updaterStore.lastError {
              Text(updateError)
                .font(Geist.Typography.Settings.helperText)
                .foregroundColor(Geist.Colors.statusError)
            }
          }
        }

        // BUILD LOGS
        section("Build Logs", description: "Default number of lines loaded when opening a build log.") {
          VStack(alignment: .leading, spacing: 6) {
            Text("Default log lines")
              .font(Geist.Typography.Settings.fieldLabel)
              .foregroundColor(Geist.Colors.gray1000)
            VercelSegmentedControl(
              selection: $settings.defaultLogLines,
              options: logLineOptions
            )
          }
        }

        // DIAGNOSTICS
        section("Diagnostics", description: "Export runtime state and logs for troubleshooting.") {
          DiagnosticsView()
        }

        // DESIGN PREVIEW
        section("Design Preview", description: "Visual token preview for current theme and components.") {
          DesignPreviewView()
        }

        // ACCOUNT
        if authSession.status == .signedIn {
          section("Account", description: "Sign out from your current session.") {
            Button {
              showSignOutConfirmation = true
            } label: {
              HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
              }
              .font(Geist.Typography.Settings.button)
              .foregroundColor(.red)
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.horizontal, Geist.Layout.settingsHPadding)
      .padding(.vertical, Geist.Layout.settingsVPadding)
    }
    .frame(width: Geist.Layout.settingsWidth)
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

  // MARK: - Helpers

  private func section<Content: View>(
    _ title: String,
    description: String,
    isFirst: Bool = false,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
      VercelSectionHeader(title: title)
        .padding(.top, isFirst ? 0 : Geist.Layout.spacingXL)

      Text(description)
        .font(Geist.Typography.Settings.helperText)
        .foregroundColor(Geist.Colors.textSecondary)

      VercelSectionCard {
        content()
      }
    }
  }
}
