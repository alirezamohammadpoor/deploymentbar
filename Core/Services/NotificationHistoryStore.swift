import Foundation

final class NotificationHistoryStore {
  private struct Entry: Codable {
    let state: String
    let timestamp: Date
  }

  private let defaults: UserDefaults
  private let key = "notifications.history"
  private let maxEntries = 300
  private var cache: [String: Entry]
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    self.encoder = encoder

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.decoder = decoder

    if let data = defaults.data(forKey: key),
       let decoded = try? decoder.decode([String: Entry].self, from: data) {
      self.cache = decoded
    } else {
      self.cache = [:]
    }
  }

  func shouldNotify(id: String, state: DeploymentState) -> Bool {
    if let entry = cache[id], entry.state == state.rawValue {
      return false
    }
    return true
  }

  func markNotified(id: String, state: DeploymentState) {
    cache[id] = Entry(state: state.rawValue, timestamp: Date())
    trimIfNeeded()
    persist()
  }

  private func trimIfNeeded() {
    guard cache.count > maxEntries else { return }
    let sorted = cache.sorted { $0.value.timestamp < $1.value.timestamp }
    let removeCount = cache.count - maxEntries
    for index in 0..<removeCount {
      cache.removeValue(forKey: sorted[index].key)
    }
  }

  private func persist() {
    if let data = try? encoder.encode(cache) {
      defaults.set(data, forKey: key)
    }
  }
}
