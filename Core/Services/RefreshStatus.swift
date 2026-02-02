import Foundation

struct RefreshStatus: Equatable {
  var lastRefresh: Date?
  var nextRefresh: Date?
  var isStale: Bool
  var error: String?

  static let idle = RefreshStatus(lastRefresh: nil, nextRefresh: nil, isStale: false, error: nil)
}
