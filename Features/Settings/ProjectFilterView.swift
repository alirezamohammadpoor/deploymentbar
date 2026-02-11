import SwiftUI

struct ProjectFilterView: View {
  @StateObject private var projectStore = ProjectStore.shared
  @StateObject private var settingsStore = SettingsStore.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Monitor projects")
          .font(Geist.Typography.Settings.fieldLabel)
          .foregroundColor(Geist.Colors.gray1000)
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
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(Geist.Colors.statusError)
      } else if projectStore.projects.isEmpty {
        Text("No projects found")
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(Geist.Colors.gray800)
      } else {
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(projectStore.projects) { project in
              VercelCheckmarkRow(name: project.name, isSelected: binding(for: project.id))
            }
          }
        }
        .frame(maxHeight: 220)
      }
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
