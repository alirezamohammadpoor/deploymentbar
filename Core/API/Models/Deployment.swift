import Foundation

struct Deployment: Identifiable, Equatable {
  let id: String
  let projectId: String?
  let projectName: String
  let branch: String?
  let target: String?
  let state: DeploymentState
  let url: String?
  let createdAt: Date
  let readyAt: Date?

  // GitHub metadata
  let commitMessage: String?
  let commitAuthor: String?
  let commitSha: String?
  let githubOrg: String?
  let githubRepo: String?
  let prId: Int?

  // Computed properties
  var buildDuration: TimeInterval? {
    guard state == .ready, let ready = readyAt else { return nil }
    return ready.timeIntervalSince(createdAt)
  }

  var formattedBuildDuration: String {
    guard let duration = buildDuration else { return "—" }
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return minutes > 0 ? "\(minutes)m \(seconds)s" : "\(seconds)s"
  }

  var prURL: URL? {
    guard let org = githubOrg, let repo = githubRepo, let pr = prId else { return nil }
    return URL(string: "https://github.com/\(org)/\(repo)/pull/\(pr)")
  }

  var shortCommitSha: String? {
    guard let sha = commitSha else { return nil }
    return String(sha.prefix(7))
  }
}

enum DeploymentState: String, Codable {
  case queued
  case building
  case ready
  case error
  case canceled
}

struct DeploymentDTO: Codable, Equatable {
  let uid: String
  let name: String
  let url: String?
  let state: String?
  let readyState: String?
  let createdAt: Int64
  let ready: Int64?
  let projectId: String?
  let target: String?
  let meta: [String: String]?
  let gitSource: GitSource?

  struct GitSource: Codable, Equatable {
    let ref: String?
  }

  var branchRef: String? {
    if let ref = meta?["githubCommitRef"], !ref.isEmpty { return ref }
    if let ref = meta?["gitlabCommitRef"], !ref.isEmpty { return ref }
    if let ref = meta?["bitbucketCommitRef"], !ref.isEmpty { return ref }
    return gitSource?.ref
  }
}

extension Deployment {
  static func from(dto: DeploymentDTO) -> Deployment {
    let createdAt = Date(timeIntervalSince1970: TimeInterval(dto.createdAt) / 1000)
    let readyAt = dto.ready.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }

    // Extract GitHub metadata from meta dictionary
    let meta = dto.meta
    let commitMessage = meta?["githubCommitMessage"]
    let commitAuthor = meta?["githubCommitAuthorName"]
    let commitSha = meta?["githubCommitSha"]
    let githubOrg = meta?["githubCommitOrg"]
    let githubRepo = meta?["githubCommitRepo"]
    let prId = meta?["githubPrId"].flatMap { Int($0) }

    return Deployment(
      id: dto.uid,
      projectId: dto.projectId,
      projectName: dto.name,
      branch: dto.branchRef,
      target: dto.target,
      state: DeploymentState.from(readyState: dto.readyState, state: dto.state),
      url: dto.url,
      createdAt: createdAt,
      readyAt: readyAt,
      commitMessage: commitMessage,
      commitAuthor: commitAuthor,
      commitSha: commitSha,
      githubOrg: githubOrg,
      githubRepo: githubRepo,
      prId: prId
    )
  }
}

extension DeploymentState {
  static func from(readyState: String?, state: String?) -> DeploymentState {
    let value = (readyState ?? state ?? "").lowercased()

    if value.contains("ready") || value.contains("success") {
      return .ready
    }
    if value.contains("error") || value.contains("failed") {
      return .error
    }
    if value.contains("canceled") || value.contains("cancelled") {
      return .canceled
    }
    if value.contains("queued") || value.contains("pending") || value.contains("initializing") {
      return .queued
    }
    return .building
  }
}
