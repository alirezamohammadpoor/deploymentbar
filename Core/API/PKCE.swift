import CryptoKit
import Foundation

enum PKCE {
  static func generateCodeVerifier() -> String {
    let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
    return Data(bytes).base64URLEncodedString()
  }

  static func codeChallenge(for verifier: String) -> String {
    let data = Data(verifier.utf8)
    let hashed = SHA256.hash(data: data)
    return Data(hashed).base64URLEncodedString()
  }
}

private extension Data {
  func base64URLEncodedString() -> String {
    return base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
