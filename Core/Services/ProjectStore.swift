import Foundation

@MainActor
final class ProjectStore: ObservableObject {
  static let shared = ProjectStore()

  @Published private(set) var projects: [Project] = []
  @Published private(set) var isLoading: Bool = false
  @Published private(set) var error: String?

  private let credentialStore = CredentialStore()
  private let authSession = AuthSession.shared
  private var apiClient: VercelAPIClientImpl?

  func configure(apiClient: VercelAPIClientImpl) {
    self.apiClient = apiClient
  }

  func refresh() {
    guard let apiClient else {
      error = "Missing API client"
      return
    }

    isLoading = true
    error = nil

    Task.detached { [weak self] in
      guard let self else { return }
      let tokens = self.credentialStore.loadTokens()
      let personalToken = self.credentialStore.loadPersonalToken()

      guard tokens != nil || personalToken != nil else {
        await MainActor.run {
          self.isLoading = false
        }
        return
      }

      do {
        if let tokens, tokens.shouldRefreshSoon, let refreshToken = tokens.refreshToken, !refreshToken.isEmpty {
          let refreshed = try await apiClient.refreshToken(refreshToken)
          self.credentialStore.saveTokens(refreshed)
        }

        let teamId = tokens?.teamId
        let dtos = try await apiClient.fetchProjects(teamId: teamId)
        let projects = dtos.map(Project.from(dto:)).sorted { $0.name.lowercased() < $1.name.lowercased() }

        await MainActor.run {
          self.projects = projects
          self.isLoading = false
        }
      } catch let error as APIError {
        if case .unauthorized = error {
          await MainActor.run {
            self.authSession.signOut()
          }
        }
        await MainActor.run {
          self.error = error.userMessage
          self.isLoading = false
        }
      } catch {
        await MainActor.run {
          self.error = "Network error"
          self.isLoading = false
        }
      }
    }
  }

}
