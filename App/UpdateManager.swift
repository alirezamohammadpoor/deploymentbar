import AppKit
import Foundation

@MainActor
final class UpdateManager: ObservableObject {
  static let shared = UpdateManager()

  enum StatusLevel: Equatable {
    case info
    case success
    case error
  }

  struct LatestRelease: Decodable, Equatable {
    let tagName: String
    let htmlURL: URL

    enum CodingKeys: String, CodingKey {
      case tagName = "tag_name"
      case htmlURL = "html_url"
    }
  }

  @Published private(set) var statusText: String?
  @Published private(set) var statusLevel: StatusLevel = .info
  @Published private(set) var isChecking = false

  private let endpoint: URL
  private let bundleInfoProvider: () -> [String: Any]
  private let fetcher: (URLRequest) async throws -> (Data, URLResponse)
  private let urlOpener: (URL) -> Void
  private let decoder: JSONDecoder

  init(
    endpoint: URL = URL(string: "https://api.github.com/repos/alirezamohammadpoor/ModelMeter/releases/latest")!,
    bundleInfoProvider: @escaping () -> [String: Any] = { Bundle.main.infoDictionary ?? [:] },
    fetcher: @escaping (URLRequest) async throws -> (Data, URLResponse) = { request in
      try await URLSession.shared.data(for: request)
    },
    urlOpener: @escaping (URL) -> Void = { url in
      NSWorkspace.shared.open(url)
    },
    decoder: JSONDecoder = JSONDecoder()
  ) {
    self.endpoint = endpoint
    self.bundleInfoProvider = bundleInfoProvider
    self.fetcher = fetcher
    self.urlOpener = urlOpener
    self.decoder = decoder
  }

  func checkForUpdates() async {
    guard !isChecking else { return }
    isChecking = true
    statusLevel = .info
    statusText = "Checking for updates…"

    defer { isChecking = false }

    do {
      let release = try await fetchLatestRelease()
      let localVersion = Self.currentAppVersion(infoDictionary: bundleInfoProvider())
      if Self.isRemoteTagNewer(release.tagName, than: localVersion) {
        statusLevel = .success
        statusText = "New version \(Self.normalizedVersionString(release.tagName)) available. Opening release page…"
        DebugLog.write(
          "Update available: local=\(localVersion), remote=\(release.tagName)",
          level: .info,
          component: "updates"
        )
        urlOpener(release.htmlURL)
      } else {
        statusLevel = .info
        statusText = "You are up to date (\(localVersion))."
        DebugLog.write(
          "Already up to date: local=\(localVersion), remote=\(release.tagName)",
          level: .info,
          component: "updates"
        )
      }
    } catch {
      statusLevel = .error
      statusText = "Update check failed. Please try again."
      DebugLog.write(
        "Update check failed: \(error.localizedDescription)",
        level: .warn,
        component: "updates"
      )
    }
  }

  static func currentAppVersion(infoDictionary: [String: Any]) -> String {
    if let shortVersion = infoDictionary["CFBundleShortVersionString"] as? String {
      let trimmed = shortVersion.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return trimmed
      }
    }

    if let buildVersion = infoDictionary["CFBundleVersion"] as? String {
      let trimmed = buildVersion.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty {
        return trimmed
      }
    }

    return "0"
  }

  static func isRemoteTagNewer(_ remoteTag: String, than localVersion: String) -> Bool {
    let normalizedRemote = normalizedVersionString(remoteTag)
    let normalizedLocal = normalizedVersionString(localVersion)

    if let remoteComponents = numericComponents(for: normalizedRemote),
       let localComponents = numericComponents(for: normalizedLocal) {
      let count = max(remoteComponents.count, localComponents.count)
      for index in 0..<count {
        let remote = index < remoteComponents.count ? remoteComponents[index] : 0
        let local = index < localComponents.count ? localComponents[index] : 0
        if remote > local { return true }
        if remote < local { return false }
      }
      return false
    }

    return normalizedRemote.compare(
      normalizedLocal,
      options: [.numeric, .caseInsensitive]
    ) == .orderedDescending
  }

  static func normalizedVersionString(_ value: String) -> String {
    var output = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if output.lowercased().hasPrefix("v") {
      output.removeFirst()
    }
    return output
  }

  private static func numericComponents(for value: String) -> [Int]? {
    let coreValue = value.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true).first ?? ""
    let parts = coreValue.split(separator: ".", omittingEmptySubsequences: false)
    guard !parts.isEmpty else { return nil }

    var result: [Int] = []
    result.reserveCapacity(parts.count)
    for part in parts {
      guard part.allSatisfy(\.isNumber), let number = Int(part) else {
        return nil
      }
      result.append(number)
    }
    return result
  }

  private func fetchLatestRelease() async throws -> LatestRelease {
    var request = URLRequest(url: endpoint)
    request.timeoutInterval = 15
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("VercelBar", forHTTPHeaderField: "User-Agent")

    let (data, response) = try await fetcher(request)
    guard let http = response as? HTTPURLResponse else {
      throw UpdateError.invalidResponse
    }
    guard (200...299).contains(http.statusCode) else {
      throw UpdateError.httpStatus(http.statusCode)
    }

    do {
      return try decoder.decode(LatestRelease.self, from: data)
    } catch {
      throw UpdateError.decodingFailed
    }
  }
}

enum UpdateError: Error {
  case invalidResponse
  case httpStatus(Int)
  case decodingFailed
}
