import Foundation

final class RefreshEngine {
  private let store: DeploymentStore
  private let credentialStore: CredentialStore
  private let apiClient: VercelAPIClientImpl
  private let authSession: AuthSession
  private let statusStore: RefreshStatusStore
  private let baseInterval: TimeInterval
  private let maxBackoff: TimeInterval = 300

  private var task: Task<Void, Never>?
  private var backoffStep: Int = 0

  init(
    store: DeploymentStore,
    credentialStore: CredentialStore,
    apiClient: VercelAPIClientImpl,
    authSession: AuthSession,
    statusStore: RefreshStatusStore,
    interval: TimeInterval = 30.0
  ) {
    self.store = store
    self.credentialStore = credentialStore
    self.apiClient = apiClient
    self.authSession = authSession
    self.statusStore = statusStore
    self.baseInterval = interval
  }

  func start() {
    guard task == nil else { return }
    task = Task { [weak self] in
      await self?.runLoop()
    }
  }

  func stop() {
    task?.cancel()
    task = nil
    backoffStep = 0
    Task { [weak self] in
      await self?.updateStatus(isStale: false, error: nil)
    }
  }

  func triggerImmediateRefresh() {
    Task { [weak self] in
      await self?.fetchOnce(resetBackoff: true)
    }
  }

  private func runLoop() async {
    await fetchOnce(resetBackoff: false)
    while !Task.isCancelled {
      let delay = currentDelay
      await updateNextRefresh(after: delay)
      try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      await fetchOnce(resetBackoff: false)
    }
  }

  private var currentDelay: TimeInterval {
    let multiplier = pow(2.0, Double(backoffStep))
    return min(baseInterval * multiplier, maxBackoff)
  }

  private func fetchOnce(resetBackoff: Bool) async {
    if resetBackoff {
      backoffStep = 0
    }

    guard let tokens = credentialStore.loadTokens() else {
      await MainActor.run { authSession.signOut() }
      await updateStatus(isStale: true, error: "Missing credentials")
      return
    }

    do {
      if tokens.shouldRefreshSoon {
        let refreshed = try await apiClient.refreshToken(tokens.refreshToken)
        credentialStore.saveTokens(refreshed)
      }

      let dtos = try await apiClient.fetchDeployments(limit: 10, projectIds: nil)
      let deployments = dtos.map(Deployment.from(dto:))

      await MainActor.run {
        store.apply(deployments: deployments)
      }

      backoffStep = 0
      await updateStatus(isStale: false, error: nil, markRefresh: true)
    } catch let error as APIError {
      if case .unauthorized = error {
        await MainActor.run { authSession.signOut() }
      }
      backoffStep = min(backoffStep + 1, 4)
      await updateStatus(isStale: true, error: errorMessage(for: error))
    } catch {
      backoffStep = min(backoffStep + 1, 4)
      await updateStatus(isStale: true, error: "Network error")
    }
  }

  private func updateNextRefresh(after delay: TimeInterval) async {
    let nextDate = Date().addingTimeInterval(delay)
    await MainActor.run {
      statusStore.mutate { status in
        status.nextRefresh = nextDate
      }
    }
  }

  private func updateStatus(isStale: Bool, error: String?, markRefresh: Bool = false) async {
    let now = Date()
    await MainActor.run {
      statusStore.mutate { status in
        if markRefresh {
          status.lastRefresh = now
        }
        status.isStale = isStale
        status.error = error
      }
    }
  }

  private func errorMessage(for error: APIError) -> String {
    switch error {
    case .unauthorized:
      return "Unauthorized"
    case .rateLimited(let resetAt):
      if let resetAt {
        return "Rate limited until \(DateFormatter.shortTime.string(from: resetAt))"
      }
      return "Rate limited"
    case .serverError:
      return "Server error"
    case .decodingFailed:
      return "Decode error"
    case .networkFailure:
      return "Network error"
    case .invalidResponse:
      return "Invalid response"
    }
  }
}

private extension DateFormatter {
  static var shortTime: DateFormatter {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.dateStyle = .none
    return formatter
  }
}
