import SwiftUI

struct PersonalTokenView: View {
  @State private var tokenInput: String = ""
  @State private var statusMessage: String?
  private let credentialStore = CredentialStore()
  @StateObject private var authSession = AuthSession.shared

  var body: some View {
    VStack(alignment: .leading, spacing: Theme.Layout.spacingSM) {
      SecureField("Paste Vercel Personal Access Token", text: $tokenInput)

      HStack {
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
        .buttonStyle(.plain)

        Button("Clear Token") {
          credentialStore.clearPersonalToken()
          authSession.signOut()
          statusMessage = "Token cleared."
        }
        .buttonStyle(.plain)
      }

      if let statusMessage {
        Text(statusMessage)
          .font(Theme.Typography.captionSmall)
          .foregroundColor(Theme.Colors.textSecondary)
      }

      Text("Personal tokens skip OAuth and unlock deployment access immediately.")
        .font(Theme.Typography.captionSmall)
        .foregroundColor(Theme.Colors.textSecondary)
    }
  }
}
