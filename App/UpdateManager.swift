import Combine
import Foundation

@MainActor
final class UpdateManager: ObservableObject {
  static let shared = UpdateManager()

  enum Status: Equatable {
    case idle
    case checking
    case upToDate
    case updateInitiated
    case failed
  }

  enum StatusLevel: Equatable {
    case info
    case success
    case error
  }

  @Published private(set) var status: Status = .idle
  @Published private(set) var statusText: String?
  @Published private(set) var statusLevel: StatusLevel = .info
  @Published private(set) var isChecking = false

  private let service: SparkleUpdateServicing
  private var cancellables: Set<AnyCancellable> = []

  init() {
    self.service = SparkleUpdateService.shared
    bindService()
  }

  init(service: SparkleUpdateServicing) {
    self.service = service
    bindService()
  }

  private func bindService() {
    service.statusPublisher
      .sink { [weak self] state in
        self?.apply(state: state)
      }
      .store(in: &cancellables)

    apply(state: service.status)
  }

  func start() {
    service.start()
  }

  func checkForUpdates() async {
    service.checkForUpdates()
  }

  private func apply(state: SparkleUpdateState) {
    switch state {
    case .idle:
      status = .idle
      statusText = nil
      statusLevel = .info
      isChecking = false
    case .checking:
      status = .checking
      statusText = "Checking for updates..."
      statusLevel = .info
      isChecking = true
    case .upToDate:
      status = .upToDate
      statusText = "You are up to date."
      statusLevel = .info
      isChecking = false
    case .updateInitiated(let version):
      status = .updateInitiated
      if let version, !version.isEmpty {
        statusText = "Update found (\(version)). Follow Sparkle prompts to install."
      } else {
        statusText = "Update found. Follow Sparkle prompts to install."
      }
      statusLevel = .success
      isChecking = false
    case .failed(let message):
      let normalizedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      if normalizedMessage.contains("up to date") || normalizedMessage.contains("latest version") {
        status = .upToDate
        statusText = "You are up to date."
        statusLevel = .info
        isChecking = false
      } else {
        status = .failed
        statusText = "Update check failed: \(message)"
        statusLevel = .error
        isChecking = false
      }
    }
  }
}
