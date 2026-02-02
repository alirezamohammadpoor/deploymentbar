import SwiftUI

struct ProjectFilterView: View {
  @StateObject private var projectStore = ProjectStore.shared
  @StateObject private var settingsStore = SettingsStore.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text("Monitor projects")
          .font(.subheadline)
        Spacer()
        Button("Reload") {
          projectStore.refresh()
        }
        .buttonStyle(.plain)
        .font(.caption)
      }

      if projectStore.isLoading {
        ProgressView()
          .controlSize(.small)
      } else if let error = projectStore.error {
        Text(error)
          .font(.caption)
          .foregroundColor(.red)
      } else if projectStore.projects.isEmpty {
        Text("No projects found")
          .font(.caption)
          .foregroundColor(.secondary)
      } else {
        VStack(alignment: .leading, spacing: 4) {
          ForEach(projectStore.projects) { project in
            Toggle(project.name, isOn: binding(for: project.id))
          }
        }
      }

      Text("Leave all unchecked to monitor every project.")
        .font(.caption2)
        .foregroundColor(.secondary)
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
