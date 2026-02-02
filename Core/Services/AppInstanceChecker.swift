import AppKit
import Foundation

struct AppInstanceChecker {
  struct RunningApp: Equatable {
    let bundleIdentifier: String?
    let processIdentifier: pid_t
  }

  static func runningApps(for bundleId: String) -> [RunningApp] {
    NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
      .map { RunningApp(bundleIdentifier: $0.bundleIdentifier, processIdentifier: $0.processIdentifier) }
  }

  static func isDuplicate(bundleId: String, currentPID: pid_t, runningApps: [RunningApp]) -> Bool {
    runningApps.contains { $0.bundleIdentifier == bundleId && $0.processIdentifier != currentPID }
  }
}
