import Foundation
import ServiceManagement

final class LaunchAtLoginManager {
  func isEnabled() -> Bool {
    SMAppService.mainApp.status == .enabled
  }

  @discardableResult
  func setEnabled(_ enabled: Bool) -> Bool {
    do {
      if enabled {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
      return true
    } catch {
      return false
    }
  }
}
