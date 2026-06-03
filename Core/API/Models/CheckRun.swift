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

struct FailingCheckInfo: Equatable {
  let name: String
  let detailsUrl: String?

  static func from(checks: [GitHubCheckRunDTO]) -> [FailingCheckInfo] {
    let failureConclusions: Set<String> = ["failure", "timed_out", "cancelled"]
    return checks.compactMap { check in
      guard let conclusion = check.conclusion, failureConclusions.contains(conclusion) else {
        return nil
      }
      return FailingCheckInfo(name: check.name, detailsUrl: check.detailsUrl)
    }
  }
}

// MARK: - Per-step pipeline (which CI step a deployment is on)

enum CIStepStatus: Equatable {
  case queued
  case running
  case passed
  case failed
  case skipped
}

struct CIStep: Identifiable, Equatable {
  let id: String
  let name: String
  let status: CIStepStatus

  static func status(for check: GitHubCheckRunDTO) -> CIStepStatus {
    switch check.status {
    case "queued":
      return .queued
    case "in_progress":
      return .running
    default: // "completed"
      switch check.conclusion {
      case "success":
        return .passed
      case "failure", "timed_out", "cancelled":
        return .failed
      case "skipped", "neutral":
        return .skipped
      default:
        return .queued
      }
    }
  }

  static func from(check: GitHubCheckRunDTO) -> CIStep {
    CIStep(id: "check-\(check.id)", name: check.name, status: status(for: check))
  }

  /// The deployment's checks in API order with a synthetic "Deploy" step appended.
  /// Returns [] when there are no checks (the row's status dot already conveys the
  /// deploy state). The collapsed row consumes this to surface the running step.
  static func pipeline(checks: [GitHubCheckRunDTO], deployState: DeploymentState) -> [CIStep] {
    guard !checks.isEmpty else { return [] }
    return checks.map(CIStep.from(check:)) + [deployStep(for: deployState)]
  }

  static func deployStep(for state: DeploymentState) -> CIStep {
    let status: CIStepStatus
    switch state {
    case .building: status = .running
    case .ready: status = .passed
    case .error: status = .failed
    case .queued: status = .queued
    case .canceled: status = .skipped
    }
    return CIStep(id: "deploy", name: "Deploy", status: status)
  }
}
