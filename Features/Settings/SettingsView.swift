import SwiftUI

struct SettingsView: View {
  @StateObject private var settings = SettingsStore.shared
  @State private var browserOptions: [BrowserOption] = BrowserOption.availableOptions()
  private let launchAtLoginManager = LaunchAtLoginManager()

  private let pollingOptions: [TimeInterval] = [15, 30, 60, 120, 300]

  var body: some View {
    Form {
      Section("Notifications") {
        Toggle("Notify on ready", isOn: $settings.notifyOnReady)
        Toggle("Notify on failed", isOn: $settings.notifyOnFailed)
      }

      Section("Polling") {
        Picker("Interval", selection: $settings.pollingInterval) {
          ForEach(pollingOptions, id: \.self) { interval in
            Text(label(for: interval)).tag(interval)
          }
        }
        .pickerStyle(PopUpButtonPickerStyle())
      }

      Section("Projects") {
        ProjectFilterView()
      }

      Section("Personal Token") {
        PersonalTokenView()
      }

      Section("Browser") {
        Picker("Open links in", selection: $settings.browserBundleId) {
          ForEach(browserOptions) { option in
            Text(option.displayName).tag(option.id)
          }
        }
        .pickerStyle(PopUpButtonPickerStyle())
      }

      Section("Startup") {
        Toggle("Launch at login", isOn: $settings.launchAtLogin)
          .onChange(of: settings.launchAtLogin) { newValue in
            let success = launchAtLoginManager.setEnabled(newValue)
            if !success {
              settings.launchAtLogin = launchAtLoginManager.isEnabled()
            }
          }
      }
    }
    .padding(Theme.Layout.spacingLG)
    .frame(width: Theme.Layout.settingsWidth)
    .onAppear {
      browserOptions = BrowserOption.availableOptions()
    }
  }

  private func label(for interval: TimeInterval) -> String {
    if interval < 60 {
      return "\(Int(interval))s"
    }
    return "\(Int(interval / 60))m"
  }
}
