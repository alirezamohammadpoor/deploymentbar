import Foundation

enum DebugLog {
  private static let path = "/tmp/vercelbar.log"

  static func write(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    guard let data = line.data(using: .utf8) else { return }

    if let handle = FileHandle(forWritingAtPath: path) {
      handle.seekToEndOfFile()
      handle.write(data)
      try? handle.close()
      return
    }

    FileManager.default.createFile(atPath: path, contents: data)
  }
}
