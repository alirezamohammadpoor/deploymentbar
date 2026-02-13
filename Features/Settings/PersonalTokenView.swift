import SwiftUI

struct PersonalTokenView: View {
  @State private var tokenInput: String = ""
  @State private var statusMessage: String?
  private let credentialStore = CredentialStore()
  @StateObject private var authSession = AuthSession.shared

  var body: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
      authStatusRow

      SecureField("Paste Vercel Personal Access Token", text: $tokenInput)
        .textFieldStyle(.plain)
        .vercelTextField()

      HStack(spacing: Geist.Layout.spacingSM) {
        Button("Save Token") {
          let trimmed = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
          guard !trimmed.isEmpty else {
            statusMessage = "Token cannot be empty."
            return
          }
          authSession.usePersonalToken(trimmed)
          tokenInput = ""
          statusMessage = "Token saved."
        }
        .buttonStyle(VercelPrimaryButtonStyle())
        .disabled(tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        Button("Clear Token") {
          credentialStore.clearPersonalToken()
          authSession.signOut()
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
  }

  private var authStatusRow: some View {
    HStack(spacing: Geist.Layout.spacingXS) {
      Circle()
        .fill(authSession.status == .signedIn ? Geist.Colors.statusReady : Geist.Colors.statusQueued)
        .frame(width: 8, height: 8)

      Text(authSession.status == .signedIn ? "Authenticated" : "Not authenticated")
        .font(Geist.Typography.Settings.helperText)
        .foregroundColor(Geist.Colors.textSecondary)
    }
  }
}
