import Foundation

struct Project: Identifiable, Equatable {
  let id: String
  let name: String
}

struct ProjectDTO: Codable, Equatable {
  let id: String
  let name: String
}

extension Project {
  static func from(dto: ProjectDTO) -> Project {
    Project(id: dto.id, name: dto.name)
  }
}
