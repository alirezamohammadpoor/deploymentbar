import Foundation

struct KeychainWrapper {
  static func get(_ account: String) throws -> Data? {
    // TODO: implement SecItemCopyMatching.
    nil
  }

  static func set(_ data: Data, account: String) throws {
    // TODO: implement SecItemAdd / SecItemUpdate.
  }

  static func delete(_ account: String) throws {
    // TODO: implement SecItemDelete.
  }
}
