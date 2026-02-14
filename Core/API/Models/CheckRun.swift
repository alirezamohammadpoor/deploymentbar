import Foundation

struct GitHubCheckRunDTO: Codable, Equatable {
  let id: Int
  let name: String
  let status: String
  let conclusion: String?
  let detailsUrl: String?

  enum CodingKeys: String, CodingKey {
    case id, name, status, conclusion
    case detailsUrl = "details_url"
  }
}

struct GitHubCheckRunsResponse: Codable {
  let totalCount: Int
  let checkRuns: [GitHubCheckRunDTO]

  enum CodingKeys: String, CodingKey {
    case totalCount = "total_count"
    case checkRuns = "check_runs"
  }
}

enum AggregateCheckStatus: Equatable {
  case running
  case passed
  case failed
  case none

  static func from(checks: [GitHubCheckRunDTO]) -> AggregateCheckStatus {
    guard !checks.isEmpty else { return .none }
    if checks.contains(where: { $0.status == "queued" || $0.status == "in_progress" }) {
      return .running
    }
    if checks.contains(where: {
      $0.conclusion == "failure" || $0.conclusion == "timed_out" || $0.conclusion == "cancelled"
    }) {
      return .failed
    }
    return .passed
  }
}
