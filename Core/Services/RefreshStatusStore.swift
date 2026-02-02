import Foundation

@MainActor
final class RefreshStatusStore: ObservableObject {
  @Published var status: RefreshStatus = .idle

  func mutate(_ block: (inout RefreshStatus) -> Void) {
    block(&status)
  }
}
