import SwiftUI

struct SettingsView: View {
  @StateObject private var settings = SettingsStore.shared
  @StateObject private var authSession = AuthSession.shared
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
        section("Authentication", isFirst: true) {
          PersonalTokenView()
        }

        // PROJECTS
        section("Projects") {
          ProjectFilterView()
        }

        // NOTIFICATIONS
        section("Notifications") {
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
        section("General") {
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
              .onChange(of: settings.launchAtLogin) { newValue in
                let success = launchAtLoginManager.setEnabled(newValue)
                if !success {
                  settings.launchAtLogin = launchAtLoginManager.isEnabled()
                }
              }
          }
        }

        // BUILD LOGS
        buildLogsSection

        // DESIGN PREVIEW
        section("Design Preview") {
          DesignPreviewView()
        }

        // ACCOUNT
        if authSession.status == .signedIn {
          section("Account") {
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
    .preferredColorScheme(.dark)
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

      // Make window background black with transparent titlebar
      DispatchQueue.main.async {
        if let window = NSApp.windows.first(where: { $0.title == "Settings" || $0.identifier?.rawValue == "settings" }) {
          window.backgroundColor = .black
          window.titlebarAppearsTransparent = true
        }
      }
    }
  }

  // MARK: - Build Logs Section

  private var buildLogsSection: some View {
    section("Build Logs") {
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
  }

  // MARK: - Helpers

  @ViewBuilder
  private func section<Content: View>(_ title: String, isFirst: Bool = false, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      VercelSectionHeader(title: title)
        .padding(.top, isFirst ? 0 : 32)
      content()
    }
  }
}
