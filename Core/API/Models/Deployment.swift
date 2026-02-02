import Foundation

struct Deployment: Identifiable, Equatable {
  let id: String
  let projectName: String
  let branch: String?
  let state: DeploymentState
  let url: String?
  let createdAt: Date
  let readyAt: Date?
}

enum DeploymentState: String, Codable {
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
  let gitSource: GitSource?

  struct GitSource: Codable, Equatable {
    let ref: String?
  }
}

struct DeploymentDetailDTO: Codable, Equatable {
  let uid: String
  let name: String
  let url: String?
  let status: String?
  let readyState: String?
  let createdAt: Int64
  let ready: Int64?
  let projectId: String?
  let gitSource: GitSource?

  struct GitSource: Codable, Equatable {
    let ref: String?
  }
}

extension Deployment {
  static func from(dto: DeploymentDTO) -> Deployment {
    let createdAt = Date(timeIntervalSince1970: TimeInterval(dto.createdAt) / 1000)
    let readyAt = dto.ready.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }
    return Deployment(
      id: dto.uid,
      projectName: dto.name,
      branch: dto.gitSource?.ref,
      state: DeploymentState.from(readyState: dto.readyState, state: dto.state),
      url: dto.url,
      createdAt: createdAt,
      readyAt: readyAt
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
    return .building
  }
}
