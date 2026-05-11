import Foundation

final class RefreshEngine {
  private let store: DeploymentStore
  private let credentialStore: CredentialStore
  private let apiClient: VercelAPIClientImpl
  private let authSession: AuthSession
  private let statusStore: RefreshStatusStore
  private let settingsStore: SettingsStore
  private let maxBackoff: TimeInterval = 300
  private static let activePollingInterval: TimeInterval = 5

  private var task: Task<Void, Never>?
  private var backoffStep: Int = 0
  private var baseInterval: TimeInterval
  private var hasActiveBuilds = false

  init(
    store: DeploymentStore,
    credentialStore: CredentialStore,
    apiClient: VercelAPIClientImpl,
    authSession: AuthSession,
    statusStore: RefreshStatusStore,
    settingsStore: SettingsStore,
    interval: TimeInterval = 30.0
  ) {
    self.store = store
    self.credentialStore = credentialStore
    self.apiClient = apiClient
    self.authSession = authSession
    self.statusStore = statusStore
    self.settingsStore = settingsStore
    self.baseInterval = interval
  }

  func start() {
    guard task == nil else {
      DebugLog.write("RefreshEngine.start(): already running")
      return
    }
    DebugLog.write("RefreshEngine.start(): launching runLoop")
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

  func updateInterval(_ interval: TimeInterval) {
    baseInterval = interval
  }

  private func runLoop() async {
    await fetchOnce(resetBackoff: false)
    while !Task.isCancelled {
      let delay = currentDelay
      await updateNextRefresh(after: delay)
      try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
      guard !Task.isCancelled else { break }
      await fetchOnce(resetBackoff: false)
    }
  }

  private var currentDelay: TimeInterval {
    let base = hasActiveBuilds ? min(baseInterval, Self.activePollingInterval) : baseInterval
    let multiplier = pow(2.0, Double(backoffStep))
    return min(base * multiplier, maxBackoff)
  }

  private func fetchOnce(resetBackoff: Bool) async {
    if resetBackoff {
      backoffStep = 0
    }
    await MainActor.run { statusStore.status.isRefreshing = true }

    let personalToken = credentialStore.loadPersonalToken()
    let tokens = credentialStore.loadTokens()

    if tokens == nil && personalToken == nil {
      DebugLog.write("RefreshEngine: no credentials, signing out")
      await MainActor.run { authSession.signOut() }
      await updateStatus(isStale: true, error: "Missing credentials")
      return
    }

    if let tokens, tokens.isExpired, !tokens.canRefresh {
      DebugLog.write("RefreshEngine: session expired, signing out")
      await MainActor.run { authSession.signOut() }
      await updateStatus(isStale: true, error: "Session expired. Sign in again.")
      return
    }

    let selectedIds = await MainActor.run { settingsStore.selectedProjectIds }

    do {
      if let tokens, tokens.shouldRefreshSoon, let refreshToken = tokens.refreshToken, !refreshToken.isEmpty {
        var refreshed = try await apiClient.refreshToken(refreshToken)
        // Preserve teamId if the refresh response didn't include one
        if refreshed.teamId == nil, let existingTeamId = tokens.teamId {
          refreshed = refreshed.withTeamId(existingTeamId)
        }
        credentialStore.saveTokens(refreshed)
      }

      let teamId = tokens?.teamId
      let dtos = try await apiClient.fetchDeployments(limit: 10, projectIds: nil, teamId: teamId)
      #if DEBUG
      if dtos.isEmpty {
        DebugLog.write("RefreshEngine: 0 results — probing user and team context")
        do {
          let userInfo = try await apiClient.fetchCurrentUser()
          DebugLog.write("RefreshEngine: user=\(userInfo)")
        } catch {
          DebugLog.write("RefreshEngine: user fetch failed: \(error)")
        }
      }
      #endif
      let deployments = dtos.map(Deployment.from(dto:))
      let filtered = selectedIds.isEmpty
        ? deployments
        : deployments.filter { deployment in
            guard let projectId = deployment.projectId else { return false }
            return selectedIds.contains(projectId)
          }

      hasActiveBuilds = filtered.contains { $0.state == .building || $0.state == .queued }
      await MainActor.run {
        store.apply(deployments: filtered)
      }

      // Poll GitHub check runs for eligible deployments
      let githubToken = credentialStore.loadGitHubToken()
      if let githubToken {
        let deploymentsNeedingChecks = await MainActor.run {
          store.deploymentIdsNeedingCheckPoll.compactMap { id in
            store.deployments.first(where: { $0.id == id })
          }
        }
        await withTaskGroup(of: (String, AggregateCheckStatus, [FailingCheckInfo])?.self) { group in
          for deployment in deploymentsNeedingChecks {
            guard let org = deployment.githubOrg,
                  let repo = deployment.githubRepo,
                  let sha = deployment.commitSha else { continue }
            let deploymentId = deployment.id
            group.addTask { [self] in
              do {
                let checks = try await self.fetchGitHubCheckRuns(owner: org, repo: repo, sha: sha, token: githubToken)
                let status = AggregateCheckStatus.from(checks: checks)
                let failing = FailingCheckInfo.from(checks: checks)
                return (deploymentId, status, failing)
              } catch {
                DebugLog.write("RefreshEngine: GitHub check fetch failed for \(deploymentId): \(error)")
                return nil
              }
            }
          }
          for await result in group {
            guard let (deploymentId, status, failing) = result else { continue }
            await MainActor.run {
              store.applyCheckStatus(status, failingChecks: failing, for: deploymentId)
            }
          }
        }
      }

      backoffStep = 0
      await updateStatus(isStale: false, error: nil, markRefresh: true)
    } catch let error as APIError {
      DebugLog.write("RefreshEngine API error: \(error.userMessage)")
      if case .unauthorized = error {
        await MainActor.run { authSession.signOut() }
      }
      backoffStep = min(backoffStep + 1, 4)
      await updateStatus(isStale: true, error: error.userMessage)
    } catch {
      DebugLog.write("RefreshEngine error: \(error)")
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

  private func fetchGitHubCheckRuns(owner: String, repo: String, sha: String, token: String) async throws -> [GitHubCheckRunDTO] {
    guard var components = URLComponents(string: "https://api.github.com/repos/\(owner)/\(repo)/commits/\(sha)/check-runs") else {
      return []
    }
    components.queryItems = [URLQueryItem(name: "per_page", value: "100")]
    guard let url = components.url else { return [] }

    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else { return [] }
    DebugLog.write("GitHub /repos/\(owner)/\(repo)/commits/\(sha.prefix(7))/check-runs → \(http.statusCode) (\(data.count) bytes)")

    guard (200...299).contains(http.statusCode) else { return [] }

    let decoded = try JSONDecoder().decode(GitHubCheckRunsResponse.self, from: data)
    return decoded.checkRuns
  }

  private func updateStatus(isStale: Bool, error: String?, markRefresh: Bool = false) async {
    let now = Date()
    await MainActor.run {
      statusStore.mutate { status in
        if markRefresh {
          status.lastRefresh = now
        }
        status.isStale = isStale
        status.isRefreshing = false
        status.error = error
      }
    }
  }

}
