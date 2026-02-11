import Foundation

enum DebugLog {
  enum Level: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
  }

  private static let defaultPath = "/tmp/vercelbar.log"
  private static let rotatedDefaultPath = "/tmp/vercelbar.log.1"
  private static let queue = DispatchQueue(label: "com.vercelbar.debuglog", qos: .utility)
  private static let maxBytes = 1_000_000
  private static var testPathOverride: String?

  static var logPath: String {
    testPathOverride ?? defaultPath
  }

  static var rotatedLogPath: String {
    if let testPathOverride {
      return "\(testPathOverride).1"
    }
    return rotatedDefaultPath
  }

  static func write(_ message: String) {
    write(message, level: .debug, component: "app")
  }

  static func write(_ message: String, level: Level, component: String) {
    queue.async {
      let timestamp = ISO8601DateFormatter().string(from: Date())
      let line = "[\(timestamp)] [\(level.rawValue)] [\(component)] \(message)\n"
      guard let data = line.data(using: .utf8) else { return }

      rotateIfNeeded(forAppending: data.count)
      if let handle = FileHandle(forWritingAtPath: logPath) {
        handle.seekToEndOfFile()
        handle.write(data)
        try? handle.close()
      } else {
        FileManager.default.createFile(atPath: logPath, contents: data)
      }
    }
  }

  static func clear() {
    queue.sync {
      try? FileManager.default.removeItem(atPath: logPath)
      try? FileManager.default.removeItem(atPath: rotatedLogPath)
    }
  }

  static func flush() {
    queue.sync { }
  }

  static func setLogPathForTesting(_ path: String?) {
    queue.sync {
      testPathOverride = path
    }
  }

  private static func rotateIfNeeded(forAppending bytesToAppend: Int) {
    guard let attributes = try? FileManager.default.attributesOfItem(atPath: logPath),
          let currentSize = attributes[.size] as? NSNumber else {
      return
    }

    if currentSize.intValue + bytesToAppend < maxBytes {
      return
    }

    try? FileManager.default.removeItem(atPath: rotatedLogPath)
    if FileManager.default.fileExists(atPath: logPath) {
      try? FileManager.default.moveItem(atPath: logPath, toPath: rotatedLogPath)
    }
  }
}
