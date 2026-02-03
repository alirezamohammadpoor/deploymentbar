import SwiftUI

struct OAuthFlowView: View {
  @ObservedObject var authSession: AuthSession

  var body: some View {
    VStack(spacing: Theme.Layout.spacingMD) {
      Image(systemName: "person.crop.circle")
        .font(.system(size: 32))
        .foregroundColor(Theme.Colors.textTertiary)

      Text("Sign in with Vercel")
        .font(Theme.Typography.projectName)

      statusView

      Button("Continue") {
        authSession.startSignIn()
      }
      .disabled(authSessionIsBusy)
    }
    .padding(Theme.Layout.spacingLG)
  }

  private var authSessionIsBusy: Bool {
    if case .signingIn = authSession.status {
      return true
    }
    return false
  }

  @ViewBuilder
  private var statusView: some View {
    switch authSession.status {
    case .signedOut:
      Text("Not signed in")
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
    case .signingIn:
      Text("Waiting for Vercel authorization…")
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
    case .signedIn:
      Text("Signed in")
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.statusReady)
    case .error(let message):
      Text(message)
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.statusError)
        .multilineTextAlignment(.center)
    }
  }
}
