import Foundation
import XCTest
@testable import VercelBar

@MainActor
final class UpdateManagerTests: XCTestCase {
  func testCurrentAppVersionPrefersShortVersionString() {
    let version = UpdateManager.currentAppVersion(infoDictionary: [
      "CFBundleShortVersionString": "1.2.3",
      "CFBundleVersion": "456"
    ])
    XCTAssertEqual(version, "1.2.3")
  }

  func testCurrentAppVersionFallsBackToBuildVersion() {
    let version = UpdateManager.currentAppVersion(infoDictionary: [
      "CFBundleVersion": "456"
    ])
    XCTAssertEqual(version, "456")
  }

  func testIsRemoteTagNewerHandlesVPrefixAndSemverComparison() {
    XCTAssertTrue(UpdateManager.isRemoteTagNewer("v1.2.0", than: "1.1.9"))
    XCTAssertFalse(UpdateManager.isRemoteTagNewer("v1.2.0", than: "1.2.0"))
    XCTAssertFalse(UpdateManager.isRemoteTagNewer("1.1.9", than: "v1.2.0"))
  }

  func testCheckForUpdatesOpensReleasePageWhenNewerReleaseExists() async {
    let expectedURL = URL(string: "https://github.com/alirezamohammadpoor/deploymentbar/releases/tag/v1.2.0")!
    let payload = """
    {
      "tag_name": "v1.2.0",
      "html_url": "\(expectedURL.absoluteString)"
    }
    """

    var openedURL: URL?
    let manager = UpdateManager(
      bundleInfoProvider: {
        ["CFBundleShortVersionString": "1.0.0", "CFBundleVersion": "1"]
      },
      fetcher: { _ in
        (Data(payload.utf8), HTTPURLResponse(
          url: URL(string: "https://api.github.com")!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!)
      },
      urlOpener: { url in
        openedURL = url
      }
    )

    await manager.checkForUpdates()

    XCTAssertEqual(openedURL, expectedURL)
    XCTAssertEqual(manager.statusLevel, .success)
    XCTAssertTrue(manager.statusText?.contains("New version 1.2.0 available") == true)
  }

  func testCheckForUpdatesReportsUpToDateWhenVersionsMatch() async {
    let payload = """
    {
      "tag_name": "v1.0.0",
      "html_url": "https://github.com/alirezamohammadpoor/deploymentbar/releases/tag/v1.0.0"
    }
    """

    var didOpenURL = false
    let manager = UpdateManager(
      bundleInfoProvider: {
        ["CFBundleShortVersionString": "1.0.0"]
      },
      fetcher: { _ in
        (Data(payload.utf8), HTTPURLResponse(
          url: URL(string: "https://api.github.com")!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!)
      },
      urlOpener: { _ in
        didOpenURL = true
      }
    )

    await manager.checkForUpdates()

    XCTAssertFalse(didOpenURL)
    XCTAssertEqual(manager.statusLevel, .info)
    XCTAssertEqual(manager.statusText, "You are up to date (1.0.0).")
  }

  func testCheckForUpdatesShowsNoReleasesMessageFor404() async {
    let manager = UpdateManager(
      bundleInfoProvider: { ["CFBundleShortVersionString": "1.0.0"] },
      fetcher: { _ in
        (Data("{}".utf8), HTTPURLResponse(
          url: URL(string: "https://api.github.com")!,
          statusCode: 404,
          httpVersion: nil,
          headerFields: nil
        )!)
      },
      urlOpener: { _ in XCTFail("Should not open URL when no release exists") }
    )

    await manager.checkForUpdates()

    XCTAssertEqual(manager.statusLevel, .error)
    XCTAssertEqual(manager.statusText, "No GitHub release found yet. Publish your first release, then try again.")
  }
}
