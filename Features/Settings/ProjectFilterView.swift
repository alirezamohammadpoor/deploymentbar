import SwiftUI

struct ProjectFilterView: View {
  @StateObject private var projectStore = ProjectStore.shared
  @StateObject private var settingsStore = SettingsStore.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Monitor projects")
          .font(Theme.Typography.Settings.fieldLabel)
          .foregroundColor(Theme.Colors.Settings.foreground)
        Spacer()
        VercelIconButton(systemName: "arrow.clockwise") {
          projectStore.refresh()
        }
      }

      if projectStore.isLoading {
        ProgressView()
          .controlSize(.small)
      } else if let error = projectStore.error {
        Text(error)
          .font(Theme.Typography.Settings.helperText)
          .foregroundColor(Theme.Colors.statusError)
      } else if projectStore.projects.isEmpty {
        Text("No projects found")
          .font(Theme.Typography.Settings.helperText)
          .foregroundColor(Theme.Colors.Settings.accents5)
      } else {
        VStack(alignment: .leading, spacing: 0) {
          ForEach(projectStore.projects) { project in
            VercelCheckmarkRow(name: project.name, isSelected: binding(for: project.id))
          }
        }
      }

      Text("Leave all unchecked to monitor every project.")
        .font(Theme.Typography.Settings.helperText)
        .foregroundColor(Theme.Colors.Settings.accents4)
    }
    .onAppear {
      if projectStore.projects.isEmpty {
        projectStore.refresh()
      }
    }
  }

  private func binding(for projectId: String) -> Binding<Bool> {
    Binding(
      get: { settingsStore.selectedProjectIds.contains(projectId) },
      set: { isSelected in
        if isSelected {
          settingsStore.selectedProjectIds.insert(projectId)
        } else {
          settingsStore.selectedProjectIds.remove(projectId)
        }
      }
    )
  }
}
