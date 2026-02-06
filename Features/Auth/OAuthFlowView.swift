import SwiftUI

struct OAuthFlowView: View {
  @ObservedObject var authSession: AuthSession

  var body: some View {
    VStack(spacing: Geist.Layout.spacingMD) {
      Image(systemName: "person.crop.circle")
        .font(.system(size: 32))
        .foregroundColor(Geist.Colors.textTertiary)

      Text("Sign in with Vercel")
        .font(Geist.Typography.projectName)

      statusView

      Button("Continue") {
        authSession.startSignIn()
      }
      .disabled(authSessionIsBusy)
    }
    .padding(Geist.Layout.spacingLG)
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
        .font(Geist.Typography.caption)
        .foregroundColor(Geist.Colors.textSecondary)
    case .signingIn:
      Text("Waiting for Vercel authorization…")
        .font(Geist.Typography.caption)
        .foregroundColor(Geist.Colors.textSecondary)
    case .signedIn:
      Text("Signed in")
        .font(Geist.Typography.caption)
        .foregroundColor(Geist.Colors.statusReady)
    case .error(let message):
      Text(message)
        .font(Geist.Typography.caption)
        .foregroundColor(Geist.Colors.statusError)
        .multilineTextAlignment(.center)
    }
  }
}
