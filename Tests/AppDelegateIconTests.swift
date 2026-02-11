import AppKit
import XCTest
@testable import VercelBar

@MainActor
final class AppDelegateIconTests: XCTestCase {
  func testApplyApplicationIconDoesNotCallWorkspaceSetIcon() throws {
    let appDelegate = AppDelegate()
    let applicationSpy = ApplicationIconTargetSpy()
    let workspaceSpy = WorkspaceIconSettingSpy()
    let icon = NSImage(size: NSSize(width: 16, height: 16))

    let bundleURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: bundleURL) }

    appDelegate.applyApplicationIcon(
      icon,
      bundlePath: bundleURL.path,
      application: applicationSpy,
      workspace: workspaceSpy
    )

    XCTAssertNotNil(applicationSpy.applicationIconImage)
    XCTAssertEqual(workspaceSpy.setIconCallCount, 0)

    let iconFileName = "Icon" + String(UnicodeScalar(13)!)
    let iconMetadataPath = bundleURL.appendingPathComponent(iconFileName).path
    XCTAssertFalse(FileManager.default.fileExists(atPath: iconMetadataPath))
  }
}

@MainActor
private final class ApplicationIconTargetSpy: ApplicationIconTarget {
  var applicationIconImage: NSImage!
}

@MainActor
private final class WorkspaceIconSettingSpy: WorkspaceIconSetting {
  private(set) var setIconCallCount = 0

  @discardableResult
  func setIcon(_ image: NSImage?, forFile fullPath: String, options: NSWorkspace.IconCreationOptions) -> Bool {
    setIconCallCount += 1
    return true
  }
}
