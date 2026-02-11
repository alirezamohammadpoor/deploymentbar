import SwiftUI

struct PersonalTokenView: View {
  @State private var tokenInput: String = ""
  @State private var statusMessage: String?
  private let credentialStore = CredentialStore()
  @StateObject private var authSession = AuthSession.shared

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      SecureField("Paste Vercel Personal Access Token", text: $tokenInput)
        .textFieldStyle(.plain)
        .vercelTextField()

      HStack(spacing: 8) {
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
        .buttonStyle(VercelSecondaryButtonStyle())

        Button("Clear Token") {
          credentialStore.clearPersonalToken()
          authSession.signOut()
          statusMessage = "Token cleared."
        }
        .buttonStyle(VercelSecondaryButtonStyle())
      }

      if let statusMessage {
        Text(statusMessage)
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(statusMessage == "Token saved." ? Geist.Colors.statusReady : Geist.Colors.gray800)
      }
    }
  }
}
