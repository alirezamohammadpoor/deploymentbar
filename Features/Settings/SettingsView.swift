import SwiftUI

struct SettingsView: View {
  @StateObject private var settings = SettingsStore.shared
  @State private var browserOptions: [BrowserOption] = BrowserOption.availableOptions()
  private let launchAtLoginManager = LaunchAtLoginManager()

  var body: some View {
    Form {
      Section("Notifications") {
        Toggle("Notify on ready", isOn: $settings.notifyOnReady)
        Toggle("Notify on failed", isOn: $settings.notifyOnFailed)
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
    .padding(16)
    .frame(width: 360)
    .onAppear {
      browserOptions = BrowserOption.availableOptions()
    }
  }
}
