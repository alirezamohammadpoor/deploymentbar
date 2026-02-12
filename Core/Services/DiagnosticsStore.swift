import AppKit
import Foundation

@MainActor
final class DiagnosticsStore: ObservableObject {
  static let shared = DiagnosticsStore()

  private let authSession: AuthSession
  private let refreshStatusStore: RefreshStatusStore
  private let settingsStore: SettingsStore
  private let updateManager: UpdateManager
  private let bundle: Bundle
  private let fileManager: FileManager
  private let logPathProvider: () -> String
  private let nowProvider: () -> Date

  init(
    authSession: AuthSession? = nil,
    refreshStatusStore: RefreshStatusStore? = nil,
    settingsStore: SettingsStore? = nil,
    updateManager: UpdateManager? = nil,
    bundle: Bundle = .main,
    fileManager: FileManager = .default,
    logPathProvider: @escaping () -> String = { DebugLog.logPath },
    nowProvider: @escaping () -> Date = Date.init
  ) {
    self.authSession = authSession ?? .shared
    self.refreshStatusStore = refreshStatusStore ?? .shared
    self.settingsStore = settingsStore ?? .shared
    self.updateManager = updateManager ?? .shared
    self.bundle = bundle
    self.fileManager = fileManager
    self.logPathProvider = logPathProvider
    self.nowProvider = nowProvider
  }

  var logFileURL: URL {
    URL(fileURLWithPath: logPathProvider())
  }

  func recentLogLines(limit: Int) -> [String] {
    let safeLimit = max(1, limit)
    guard let text = try? String(contentsOfFile: logPathProvider(), encoding: .utf8) else {
      return []
    }

    let lines = text.split(separator: "\n").map(String.init)
    if lines.count <= safeLimit {
      return lines
    }
    return Array(lines.suffix(safeLimit))
  }

  func buildSnapshot() -> String {
    let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
    let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
    let refresh = refreshStatusStore.status
    let selectedProjects = settingsStore.selectedProjectIds.sorted()

    return """
    VercelBar Diagnostics
    Generated: \(ISO8601DateFormatter().string(from: nowProvider()))
    Version: \(version) (\(build))
    Log Path: \(logPathProvider())

    Auth
    - Status: \(authStatusDescription(authSession.status))
    - Last Auth Error Code: \(authSession.lastAuthErrorCode.map(String.init(describing:)) ?? "none")
    - Pending Auth Started: \(formatDate(authSession.pendingAuthStartedAt))

    Refresh
    - Last Refresh: \(formatDate(refresh.lastRefresh))
    - Next Refresh: \(formatDate(refresh.nextRefresh))
    - Is Stale: \(refresh.isStale)
    - Error: \(refresh.error ?? "none")

    Settings
    - Polling Interval: \(Int(settingsStore.pollingInterval))s
    - Notify Ready: \(settingsStore.notifyOnReady)
    - Notify Failed: \(settingsStore.notifyOnFailed)
    - Browser Bundle ID: \(settingsStore.browserBundleId.isEmpty ? "default" : settingsStore.browserBundleId)
    - Launch At Login: \(settingsStore.launchAtLogin)
    - Selected Projects: \(selectedProjects.isEmpty ? "all" : selectedProjects.joined(separator: ", "))
    - Default Log Lines: \(settingsStore.defaultLogLines)

    Updates
    - Is Checking: \(updateManager.isChecking)
    - Last Status: \(updateManager.statusText ?? "none")
    """
  }

  func clearLogs() {
    DebugLog.clear()
  }

  private func authStatusDescription(_ status: AuthSession.Status) -> String {
    switch status {
    case .signedIn:
      return "signedIn"
    case .signedOut:
      return "signedOut"
    case .signingIn:
      return "signingIn"
    case .error(let message):
      return "error (\(message))"
    }
  }

  private func formatDate(_ date: Date?) -> String {
    guard let date else { return "none" }
    return ISO8601DateFormatter().string(from: date)
  }
}
