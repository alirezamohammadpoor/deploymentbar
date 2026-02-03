import SwiftUI

struct SettingsView: View {
  @StateObject private var settings = SettingsStore.shared
  @State private var browserOptions: [BrowserOption] = BrowserOption.availableOptions()
  private let launchAtLoginManager = LaunchAtLoginManager()

  private let pollingOptions: [(value: TimeInterval, label: String)] = [
    (30.0, "30s"),
    (60.0, "1m"),
    (300.0, "5m"),
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
              .font(Theme.Typography.Settings.fieldLabel)
              .foregroundColor(Theme.Colors.Settings.foreground)
            Toggle("Notify on failed", isOn: $settings.notifyOnFailed)
              .toggleStyle(VercelToggleStyle())
              .font(Theme.Typography.Settings.fieldLabel)
              .foregroundColor(Theme.Colors.Settings.foreground)
          }
        }

        // GENERAL
        section("General") {
          VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
              Text("Polling interval")
                .font(Theme.Typography.Settings.fieldLabel)
                .foregroundColor(Theme.Colors.Settings.foreground)
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
              .font(Theme.Typography.Settings.fieldLabel)
              .foregroundColor(Theme.Colors.Settings.foreground)
              .onChange(of: settings.launchAtLogin) { newValue in
                let success = launchAtLoginManager.setEnabled(newValue)
                if !success {
                  settings.launchAtLogin = launchAtLoginManager.isEnabled()
                }
              }
          }
        }
      }
      .padding(.horizontal, Theme.Layout.settingsHPadding)
      .padding(.vertical, Theme.Layout.settingsVPadding)
    }
    .frame(width: Theme.Layout.settingsWidth)
    .background(Theme.Colors.Settings.background100)
    .preferredColorScheme(.dark)
    .onAppear {
      browserOptions = BrowserOption.availableOptions()

      // Snap non-standard polling values to 30s
      let validIntervals: Set<TimeInterval> = [30, 60, 300]
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
