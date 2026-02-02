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
      guard let tokens = self.credentialStore.loadTokens() else {
        await MainActor.run {
          self.isLoading = false
        }
        return
      }

      do {
        if tokens.shouldRefreshSoon {
          let refreshed = try await apiClient.refreshToken(tokens.refreshToken)
          self.credentialStore.saveTokens(refreshed)
        }

        let dtos = try await apiClient.fetchProjects()
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
          self.error = Self.errorMessage(for: error)
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

  static func errorMessage(for error: APIError) -> String {
    switch error {
    case .unauthorized:
      return "Unauthorized"
    case .rateLimited:
      return "Rate limited"
    case .serverError:
      return "Server error"
    case .decodingFailed:
      return "Decode error"
    case .networkFailure:
      return "Network error"
    case .invalidResponse:
      return "Invalid response"
    case .oauthError(let message):
      return message
    }
  }
}
