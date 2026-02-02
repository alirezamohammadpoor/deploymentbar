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
