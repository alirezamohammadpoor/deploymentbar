import Foundation

struct RefreshStatus: Equatable {
  var lastRefresh: Date?
  var nextRefresh: Date?
  var isStale: Bool
  var isRefreshing: Bool
  var error: String?

  static let idle = RefreshStatus(lastRefresh: nil, nextRefresh: nil, isStale: false, isRefreshing: false, error: nil)
}
