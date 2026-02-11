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

    let existingTokens = credentialStore.loadTokens()
    let personalToken = credentialStore.loadPersonalToken()

    guard existingTokens != nil || personalToken != nil else {
      projects = []
      isLoading = false
      error = nil
      return
    }

    isLoading = true
    error = nil

    Task { [weak self] in
      guard let self else { return }
      var tokens = existingTokens
      do {
        if let currentTokens = tokens,
           currentTokens.shouldRefreshSoon,
           let refreshToken = currentTokens.refreshToken,
           !refreshToken.isEmpty {
          let refreshed = try await apiClient.refreshToken(refreshToken)
          credentialStore.saveTokens(refreshed)
          tokens = refreshed
        }

        let teamId = tokens?.teamId
        let dtos = try await apiClient.fetchProjects(teamId: teamId)
        let projects = dtos.map(Project.from(dto:)).sorted { $0.name.lowercased() < $1.name.lowercased() }

        self.projects = projects
        self.isLoading = false
      } catch let error as APIError {
        if case .unauthorized = error {
          authSession.signOut()
        }

        self.error = error.userMessage
        self.isLoading = false
      } catch {
        self.error = "Network error"
        self.isLoading = false
      }
    }
  }

}
