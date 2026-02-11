import Foundation

@MainActor
final class RefreshStatusStore: ObservableObject {
  static let shared = RefreshStatusStore()

  @Published var status: RefreshStatus = .idle

  func mutate(_ block: (inout RefreshStatus) -> Void) {
    block(&status)
  }
}
