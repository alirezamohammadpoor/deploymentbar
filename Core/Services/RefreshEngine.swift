import Foundation

final class RefreshEngine {
  private let store: DeploymentStore
  private let credentialStore: CredentialStore
  private let apiClient: VercelAPIClientImpl
  private let authSession: AuthSession
  private let baseInterval: TimeInterval
  private let maxBackoff: TimeInterval = 300

  private var task: Task<Void, Never>?
  private var backoffStep: Int = 0

  init(
    store: DeploymentStore,
    credentialStore: CredentialStore,
    apiClient: VercelAPIClientImpl,
    authSession: AuthSession,
    interval: TimeInterval = 30.0
  ) {
    self.store = store
    self.credentialStore = credentialStore
    self.apiClient = apiClient
    self.authSession = authSession
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
    } catch let error as APIError {
      if case .unauthorized = error {
        await MainActor.run { authSession.signOut() }
      }
      backoffStep = min(backoffStep + 1, 4)
    } catch {
      backoffStep = min(backoffStep + 1, 4)
    }
  }
}
