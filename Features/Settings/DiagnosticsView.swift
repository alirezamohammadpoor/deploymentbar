import AppKit
import SwiftUI

@MainActor
struct DiagnosticsView: View {
  @StateObject private var diagnosticsStore = DiagnosticsStore.shared
  @State private var statusMessage: String?

  var body: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingMD) {
      HStack(spacing: Geist.Layout.spacingSM) {
        Button("Copy Diagnostics Snapshot") {
          copyDiagnosticsSnapshot()
        }
        .buttonStyle(VercelSecondaryButtonStyle())

        Button("Open Log File") {
          openLogFile()
        }
        .buttonStyle(VercelSecondaryButtonStyle())

        Button("Clear Logs") {
          clearLogs()
        }
        .buttonStyle(VercelSecondaryButtonStyle())
      }

      if let statusMessage {
        Text(statusMessage)
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(Geist.Colors.textSecondary)
      }

      VStack(alignment: .leading, spacing: Geist.Layout.spacingXS) {
        Text("Recent logs")
          .font(Geist.Typography.Settings.fieldLabel)
          .foregroundColor(Geist.Colors.textPrimary)

        if recentLogs.isEmpty {
          Text("No log lines yet.")
            .font(Geist.Typography.caption)
            .foregroundColor(Geist.Colors.textSecondary)
        } else {
          ScrollView {
            VStack(alignment: .leading, spacing: Geist.Layout.spacingXS) {
              ForEach(Array(recentLogs.enumerated()), id: \.offset) { _, line in
                Text(line)
                  .font(.system(size: 11, weight: .regular, design: .monospaced))
                  .foregroundColor(Geist.Colors.textSecondary)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
          }
          .frame(maxHeight: 140)
          .padding(.horizontal, Geist.Layout.spacingSM)
          .padding(.vertical, Geist.Layout.spacingSM)
          .background(Geist.Colors.backgroundSecondary)
          .clipShape(RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius))
          .overlay(
            RoundedRectangle(cornerRadius: Geist.Layout.settingsInputRadius)
              .stroke(Geist.Colors.borderSubtle, lineWidth: 1)
          )
        }
      }
    }
  }

  private var recentLogs: [String] {
    diagnosticsStore.recentLogLines(limit: 8)
  }

  private func copyDiagnosticsSnapshot() {
    let snapshot = diagnosticsStore.buildSnapshot()
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(snapshot, forType: .string)
    statusMessage = "Diagnostics copied to clipboard."
  }

  private func openLogFile() {
    let url = diagnosticsStore.logFileURL
    if FileManager.default.fileExists(atPath: url.path) {
      NSWorkspace.shared.activateFileViewerSelecting([url])
      statusMessage = "Opened log file in Finder."
    } else {
      statusMessage = "Log file does not exist yet."
    }
  }

  private func clearLogs() {
    diagnosticsStore.clearLogs()
    statusMessage = "Logs cleared."
  }
}
