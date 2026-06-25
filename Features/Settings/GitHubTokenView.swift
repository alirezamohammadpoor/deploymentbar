import SwiftUI

struct GitHubTokenView: View {
  @State private var tokenInput: String = ""
  @State private var hasToken: Bool = false
  @State private var login: String?
  @State private var validating = false
  @State private var errorMessage: String?
  private let credentialStore = CredentialStore.shared

  var body: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
      statusRow

      HStack(spacing: 4) {
        Text("Need a token?")
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(Geist.Colors.textSecondary)
        Button {
          BrowserLauncher().open(url: GitHubEndpoints.newTokenPage)
        } label: {
          HStack(spacing: 3) {
            Text("Create one on GitHub")
            Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .semibold))
          }
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(Geist.Colors.accent)
        }
        .buttonStyle(PlainPressableButtonStyle())
      }

      Text("The repo scope is pre-selected — it lets Deploymentbar read CI checks on your repos.")
        .font(Geist.Typography.Settings.helperText)
        .foregroundColor(Geist.Colors.textTertiary)
        .fixedSize(horizontal: false, vertical: true)

      SecureField("Paste GitHub Personal Access Token", text: $tokenInput)
        .textFieldStyle(.plain)
        .vercelTextField()

      HStack(spacing: Geist.Layout.spacingSM) {
        Button(validating ? "Verifying…" : "Save Token") { connect() }
          .buttonStyle(VercelPrimaryButtonStyle())
          .disabled(validating || tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        Button("Clear Token") {
          credentialStore.clearGitHubToken()
          hasToken = false
          login = nil
          errorMessage = nil
        }
        .buttonStyle(VercelDestructiveButtonStyle())
      }

      if let errorMessage {
        Text(errorMessage)
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(Geist.Colors.statusError)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .onAppear {
      hasToken = credentialStore.loadGitHubToken() != nil
    }
  }

  private func connect() {
    let token = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !token.isEmpty else { return }
    validating = true
    errorMessage = nil
    Task {
      if let fetched = await GitHubValidator.fetchLogin(token: token) {
        credentialStore.saveGitHubToken(token)
        login = fetched
        hasToken = true
        tokenInput = ""
      } else {
        errorMessage = "That token didn't work — check it has the repo scope and isn't expired."
      }
      validating = false
    }
  }

  private var statusRow: some View {
    HStack(spacing: Geist.Layout.spacingXS) {
      Circle()
        .fill(hasToken ? Geist.Colors.statusReady : Geist.Colors.statusQueued)
        .frame(width: 8, height: 8)

      Text(statusText)
        .font(Geist.Typography.Settings.helperText)
        .foregroundColor(Geist.Colors.textSecondary)
    }
  }

  private var statusText: String {
    if let login { return "Connected as @\(login)" }
    return hasToken ? "Token saved" : "No token"
  }
}

/// Validates a GitHub token by fetching the authenticated user.
enum GitHubValidator {
  static func fetchLogin(token: String) async -> String? {
    guard let url = URL(string: "https://api.github.com/user") else { return nil }
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    guard let (data, response) = try? await URLSession.shared.data(for: request),
          let http = response as? HTTPURLResponse,
          (200...299).contains(http.statusCode),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let login = json["login"] as? String else {
      return nil
    }
    return login
  }
}
