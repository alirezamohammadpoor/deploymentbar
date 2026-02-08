import Foundation

struct LogLine: Identifiable, Equatable {
  let id: UUID
  let lineNumber: Int
  let text: String
  let isError: Bool
  let timestamp: Date?

  init(lineNumber: Int, text: String, isError: Bool, timestamp: Date? = nil) {
    self.id = UUID()
    self.lineNumber = lineNumber
    self.text = text
    self.isError = isError
    self.timestamp = timestamp
  }
}

struct DeploymentEventDTO: Codable {
  let type: String
  let created: Int64?
  let payload: Payload?

  struct Payload: Codable {
    let text: String?
  }
}

extension LogLine {
  static func from(dto: DeploymentEventDTO, lineNumber: Int) -> LogLine? {
    guard let payload = dto.payload, let text = payload.text else {
      return nil
    }

    let isError = dto.type == "stderr" || dto.type == "error"
    let timestamp = dto.created.map { Date(timeIntervalSince1970: TimeInterval($0) / 1000) }

    return LogLine(
      lineNumber: lineNumber,
      text: text,
      isError: isError,
      timestamp: timestamp
    )
  }
}
