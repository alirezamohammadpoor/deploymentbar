import Foundation
import Security

struct KeychainWrapper {
  static let service = "VercelBar"

  static func get(_ account: String) throws -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else { throw KeychainError(status) }
    return item as? Data
  }

  static func set(_ data: Data, account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    let attributes: [String: Any] = [kSecValueData as String: data]
    let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if status == errSecItemNotFound {
      let addQuery = query.merging(attributes) { $1 }
      let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
      guard addStatus == errSecSuccess else { throw KeychainError(addStatus) }
      return
    }
    guard status == errSecSuccess else { throw KeychainError(status) }
  }

  static func delete(_ account: String) throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError(status) }
  }
}

struct KeychainError: Error, CustomStringConvertible {
  let status: OSStatus

  init(_ status: OSStatus) {
    self.status = status
  }

  var description: String {
    if let message = SecCopyErrorMessageString(status, nil) as String? {
      return message
    }
    return "Keychain error: \(status)"
  }
}
