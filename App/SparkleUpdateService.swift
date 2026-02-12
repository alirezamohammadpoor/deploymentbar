import Combine
import Foundation

#if canImport(Sparkle)
import Sparkle
#endif

enum SparkleUpdateState: Equatable {
  case idle
  case checking
  case upToDate
  case updateInitiated(version: String?)
  case failed(message: String)
}

enum SparkleUpdateEvent {
  case didFindUpdate(version: String?)
  case didNotFindUpdate
  case didFail(message: String)
}

protocol SparkleUpdateDriving: AnyObject {
  var onEvent: ((SparkleUpdateEvent) -> Void)? { get set }
  func start()
  func checkForUpdates()
}

@MainActor
protocol SparkleUpdateServicing: AnyObject {
  var status: SparkleUpdateState { get }
  var statusPublisher: AnyPublisher<SparkleUpdateState, Never> { get }
  func start()
  func checkForUpdates()
}

@MainActor
final class SparkleUpdateService: ObservableObject, SparkleUpdateServicing {
  static let shared = SparkleUpdateService()

  @Published private(set) var status: SparkleUpdateState = .idle
  var statusPublisher: AnyPublisher<SparkleUpdateState, Never> { $status.eraseToAnyPublisher() }

  private let driver: SparkleUpdateDriving
  private var started = false

  init(driver: SparkleUpdateDriving = SparkleUpdateService.makeDefaultDriver()) {
    self.driver = driver
    self.driver.onEvent = { [weak self] event in
      if Thread.isMainThread {
        self?.handle(event: event)
      } else {
        DispatchQueue.main.async {
          self?.handle(event: event)
        }
      }
    }
  }

  func start() {
    guard !started else { return }
    started = true
    DebugLog.write("Sparkle updater start requested", level: .info, component: "updates")
    driver.start()
    if let feedURL = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String {
      DebugLog.write("Sparkle feed URL: \(feedURL)", level: .info, component: "updates")
    }
  }

  func checkForUpdates() {
    if !started {
      start()
    }
    status = .checking
    DebugLog.write("Sparkle check for updates started", level: .info, component: "updates")
    driver.checkForUpdates()
  }

  private func handle(event: SparkleUpdateEvent) {
    switch event {
    case .didFindUpdate(let version):
      status = .updateInitiated(version: version)
      DebugLog.write(
        "Sparkle update found: \(version ?? "unknown")",
        level: .info,
        component: "updates"
      )
    case .didNotFindUpdate:
      status = .upToDate
      DebugLog.write("Sparkle reports app is up to date", level: .info, component: "updates")
    case .didFail(let message):
      status = .failed(message: message)
      DebugLog.write("Sparkle update failed: \(message)", level: .warn, component: "updates")
    }
  }

  nonisolated private static func makeDefaultDriver() -> SparkleUpdateDriving {
#if canImport(Sparkle)
    return SparkleDriver()
#else
    return NoopSparkleDriver()
#endif
  }
}

private final class NoopSparkleDriver: SparkleUpdateDriving {
  var onEvent: ((SparkleUpdateEvent) -> Void)?

  func start() {}

  func checkForUpdates() {
    onEvent?(.didFail(message: "Sparkle framework is unavailable in this build."))
  }
}

#if canImport(Sparkle)
private final class SparkleDriver: NSObject, SparkleUpdateDriving {
  var onEvent: ((SparkleUpdateEvent) -> Void)?

  private lazy var updaterController = SPUStandardUpdaterController(
    startingUpdater: false,
    updaterDelegate: self,
    userDriverDelegate: nil
  )

  func start() {
    updaterController.startUpdater()
  }

  func checkForUpdates() {
    updaterController.checkForUpdates(nil)
  }
}

extension SparkleDriver: SPUUpdaterDelegate {
  func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
    let version = item.displayVersionString.isEmpty ? item.versionString : item.displayVersionString
    onEvent?(.didFindUpdate(version: version))
  }

  func updaterDidNotFindUpdate(_ updater: SPUUpdater, error: any Error) {
    onEvent?(.didNotFindUpdate)
  }

  func updater(_ updater: SPUUpdater, didAbortWithError error: any Error) {
    onEvent?(.didFail(message: error.localizedDescription))
  }
}
#endif
