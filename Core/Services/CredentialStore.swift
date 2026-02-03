import Foundation

protocol CredentialStoring {
  func loadTokens() -> TokenPair?
  func saveTokens(_ tokens: TokenPair)
  func clearTokens()
  func loadPersonalToken() -> String?
  func savePersonalToken(_ token: String)
  func clearPersonalToken()
}

final class CredentialStore: CredentialStoring {
  private let directory: URL
  private let tokensFile = "oauth-tokens.json"
  private let patFile = "personal-token"
  private let encoder: JSONEncoder
  private let decoder: JSONDecoder

  init() {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    self.directory = appSupport.appendingPathComponent("VercelBar", isDirectory: true)

    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    self.encoder = encoder

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    self.decoder = decoder

    try? FileManager.default.createDirectory(
      at: directory,
      withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o700]
    )
  }

  func loadTokens() -> TokenPair? {
    let url = directory.appendingPathComponent(tokensFile)
    guard let data = try? Data(contentsOf: url) else { return nil }
    return try? decoder.decode(TokenPair.self, from: data)
  }

  func saveTokens(_ tokens: TokenPair) {
    do {
      let data = try encoder.encode(tokens)
      let url = directory.appendingPathComponent(tokensFile)
      try data.write(to: url, options: [.atomic])
      try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    } catch {
      DebugLog.write("CredentialStore.saveTokens failed: \(error)")
    }
  }

  func clearTokens() {
    let url = directory.appendingPathComponent(tokensFile)
    try? FileManager.default.removeItem(at: url)
  }

  func loadPersonalToken() -> String? {
    let url = directory.appendingPathComponent(patFile)
    guard let data = try? Data(contentsOf: url) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  func savePersonalToken(_ token: String) {
    do {
      guard let data = token.data(using: .utf8) else { return }
      let url = directory.appendingPathComponent(patFile)
      try data.write(to: url, options: [.atomic])
      try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    } catch {
      DebugLog.write("CredentialStore.savePersonalToken failed: \(error)")
    }
  }

  func clearPersonalToken() {
    let url = directory.appendingPathComponent(patFile)
    try? FileManager.default.removeItem(at: url)
  }
}
