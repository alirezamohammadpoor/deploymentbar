import SwiftUI

struct SettingsView: View {
  @StateObject private var settings = SettingsStore.shared

  var body: some View {
    Form {
      Section("Notifications") {
        Toggle("Notify on ready", isOn: $settings.notifyOnReady)
        Toggle("Notify on failed", isOn: $settings.notifyOnFailed)
      }
    }
    .padding(16)
    .frame(width: 360)
  }
}
