import Foundation

struct UpdaterConfiguration: Equatable {
  let feedURL: URL
  let publicEDKey: String?

  static func load(bundle: Bundle = .main) -> UpdaterConfiguration? {
    from(infoDictionary: bundle.infoDictionary ?? [:])
  }

  static func from(infoDictionary: [String: Any]) -> UpdaterConfiguration? {
    guard let rawFeedURL = infoDictionary["SUFeedURL"] as? String else {
      return nil
    }

    let feedString = rawFeedURL.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !feedString.isEmpty,
          let feedURL = URL(string: feedString),
          let scheme = feedURL.scheme?.lowercased(),
          scheme == "https" || scheme == "http" else {
      return nil
    }

    let publicEDKey: String?
    if let rawKey = infoDictionary["SUPublicEDKey"] as? String {
      let trimmedKey = rawKey.trimmingCharacters(in: .whitespacesAndNewlines)
      publicEDKey = trimmedKey.isEmpty ? nil : trimmedKey
    } else {
      publicEDKey = nil
    }

    return UpdaterConfiguration(feedURL: feedURL, publicEDKey: publicEDKey)
  }
}
