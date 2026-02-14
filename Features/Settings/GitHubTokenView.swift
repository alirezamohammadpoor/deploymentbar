import SwiftUI

struct GitHubTokenView: View {
  @State private var tokenInput: String = ""
  @State private var statusMessage: String?
  @State private var hasToken: Bool = false
  private let credentialStore = CredentialStore()

  var body: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
      HStack(spacing: Geist.Layout.spacingXS) {
        Circle()
          .fill(hasToken ? Geist.Colors.statusReady : Geist.Colors.statusQueued)
          .frame(width: 8, height: 8)

        Text(hasToken ? "Token saved" : "No token")
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(Geist.Colors.textSecondary)
      }

      SecureField("Paste GitHub Personal Access Token", text: $tokenInput)
        .textFieldStyle(.plain)
        .vercelTextField()

      HStack(spacing: Geist.Layout.spacingSM) {
        Button("Save Token") {
          let trimmed = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
          guard !trimmed.isEmpty else {
            statusMessage = "Token cannot be empty."
            return
          }
          credentialStore.saveGitHubToken(trimmed)
          tokenInput = ""
          hasToken = true
          statusMessage = "Token saved."
        }
        .buttonStyle(VercelPrimaryButtonStyle())
        .disabled(tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        Button("Clear Token") {
          credentialStore.clearGitHubToken()
          hasToken = false
          statusMessage = "Token cleared."
        }
        .buttonStyle(VercelDestructiveButtonStyle())
      }

      if let statusMessage {
        Text(statusMessage)
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(statusMessage == "Token saved." ? Geist.Colors.statusReady : Geist.Colors.gray800)
      }
    }
    .onAppear {
      hasToken = credentialStore.loadGitHubToken() != nil
    }
  }
}
