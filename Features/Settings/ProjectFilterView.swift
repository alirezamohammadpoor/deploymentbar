import SwiftUI

struct ProjectFilterView: View {
  @StateObject private var projectStore = ProjectStore.shared
  @StateObject private var settingsStore = SettingsStore.shared

  var body: some View {
    VStack(alignment: .leading, spacing: Theme.Layout.spacingSM) {
      HStack {
        Text("Monitor projects")
          .font(Theme.Typography.projectName)
        Spacer()
        Button("Reload") {
          projectStore.refresh()
        }
        .buttonStyle(.plain)
        .font(Theme.Typography.caption)
      }

      if projectStore.isLoading {
        ProgressView()
          .controlSize(.small)
      } else if let error = projectStore.error {
        Text(error)
          .font(Theme.Typography.caption)
          .foregroundColor(Theme.Colors.statusError)
      } else if projectStore.projects.isEmpty {
        Text("No projects found")
          .font(Theme.Typography.caption)
          .foregroundColor(Theme.Colors.textSecondary)
      } else {
        VStack(alignment: .leading, spacing: Theme.Layout.spacingXS) {
          ForEach(projectStore.projects) { project in
            Toggle(project.name, isOn: binding(for: project.id))
          }
        }
      }

      Text("Leave all unchecked to monitor every project.")
        .font(Theme.Typography.captionSmall)
        .foregroundColor(Theme.Colors.textSecondary)
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
