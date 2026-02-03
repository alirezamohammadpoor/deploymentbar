import Foundation

extension JSONDecoder {
  static var vercelDecoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys
    return decoder
  }
}
