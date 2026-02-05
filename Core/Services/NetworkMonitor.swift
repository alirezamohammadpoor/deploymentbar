import Foundation
import Network
import Combine

@MainActor
final class NetworkMonitor: ObservableObject {
  static let shared = NetworkMonitor()

  @Published private(set) var isConnected: Bool = true
  @Published private(set) var connectionType: NWInterface.InterfaceType?

  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "com.vercelbar.network-monitor")

  private init() {
    startMonitoring()
  }

  private func startMonitoring() {
    monitor.pathUpdateHandler = { [weak self] path in
      Task { @MainActor in
        self?.isConnected = path.status == .satisfied
        self?.connectionType = path.availableInterfaces.first?.type
      }
    }
    monitor.start(queue: queue)
  }

  deinit {
    monitor.cancel()
  }
}
