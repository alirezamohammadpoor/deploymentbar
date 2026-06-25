import SwiftUI

struct PersonalTokenView: View {
  @State private var tokenInput: String = ""
  @ObservedObject private var authSession = AuthSession.shared

  var body: some View {
    VStack(alignment: .leading, spacing: Geist.Layout.spacingSM) {
      authStatusRow

      HStack(spacing: 4) {
        Text("Need a token?")
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(Geist.Colors.textSecondary)
        Button {
          BrowserLauncher().open(url: VercelEndpoints.accountTokensPage)
        } label: {
          HStack(spacing: 3) {
            Text("Create one on Vercel")
            Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .semibold))
          }
          .font(Geist.Typography.Settings.helperText)
          .foregroundColor(Geist.Colors.accent)
        }
        .buttonStyle(PlainPressableButtonStyle())
      }

      SecureField("Paste Vercel Personal Access Token", text: $tokenInput)
        .textFieldStyle(.plain)
        .vercelTextField()

      HStack(spacing: Geist.Layout.spacingSM) {
        Button(authSession.isConnecting ? "Verifying…" : "Save Token") {
          authSession.connect(token: tokenInput)
        }
        .buttonStyle(VercelPrimaryButtonStyle())
        .disabled(authSession.isConnecting || tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        Button("Clear Token") {
          authSession.signOut()
        }
        .buttonStyle(VercelDestructiveButtonStyle())
      }

      statusLine
    }
    .onChange(of: authSession.status) { _, newValue in
      if case .signedIn = newValue { tokenInput = "" }
    }
  }

  @ViewBuilder
  private var statusLine: some View {
    if let message = authSession.connectError {
      Text(message)
        .font(Geist.Typography.Settings.helperText)
        .foregroundColor(Geist.Colors.statusError)
        .fixedSize(horizontal: false, vertical: true)
    } else if authSession.isConnecting {
      Text("Verifying token…")
        .font(Geist.Typography.Settings.helperText)
        .foregroundColor(Geist.Colors.textSecondary)
    }
  }

  private var authStatusRow: some View {
    HStack(spacing: Geist.Layout.spacingXS) {
      Circle()
        .fill(authSession.status == .signedIn ? Geist.Colors.statusReady : Geist.Colors.statusQueued)
        .frame(width: 8, height: 8)

      Text(statusText)
        .font(Geist.Typography.Settings.helperText)
        .foregroundColor(Geist.Colors.textSecondary)
    }
  }

  private var statusText: String {
    if authSession.status == .signedIn {
      return authSession.connectedAs.map { "Connected as \($0)" } ?? "Connected"
    }
    return "Not connected"
  }
}
