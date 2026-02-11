import Foundation
import Security

final class KeychainWrapper: KeychainDataStoring {
  private let service: String

  init(service: String) {
    self.service = service
  }

  func data(for account: String) -> Data? {
    var query = baseQuery(for: account)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    switch status {
    case errSecSuccess:
      return result as? Data
    case errSecItemNotFound:
      return nil
    default:
      DebugLog.write("KeychainWrapper.data failed for \(account): \(status)")
      return nil
    }
  }

  @discardableResult
  func setData(_ data: Data, for account: String) -> Bool {
    let query = baseQuery(for: account)
    let updateAttributes: [String: Any] = [
      kSecValueData as String: data
    ]

    let updateStatus = SecItemUpdate(query as CFDictionary, updateAttributes as CFDictionary)
    if updateStatus == errSecSuccess {
      return true
    }
    if updateStatus != errSecItemNotFound {
      DebugLog.write("KeychainWrapper.setData update failed for \(account): \(updateStatus)")
      return false
    }

    var addQuery = query
    addQuery[kSecValueData as String] = data
    addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

    let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
    if addStatus == errSecSuccess {
      return true
    }

    DebugLog.write("KeychainWrapper.setData add failed for \(account): \(addStatus)")
    return false
  }

  func removeData(for account: String) {
    let query = baseQuery(for: account)
    let status = SecItemDelete(query as CFDictionary)
    if status != errSecSuccess && status != errSecItemNotFound {
      DebugLog.write("KeychainWrapper.removeData failed for \(account): \(status)")
    }
  }

  private func baseQuery(for account: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]
  }
}
