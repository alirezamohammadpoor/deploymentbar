import SwiftUI

struct OAuthFlowView: View {
  @ObservedObject var authSession: AuthSession

  var body: some View {
    VStack(spacing: 12) {
      Text("Sign in with Vercel")
        .font(.headline)

      statusView

      Button("Continue") {
        authSession.startSignIn()
      }
      .disabled(authSessionIsBusy)
    }
    .padding(16)
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
        .font(.caption)
        .foregroundColor(.secondary)
    case .signingIn:
      Text("Waiting for Vercel authorization…")
        .font(.caption)
        .foregroundColor(.secondary)
    case .signedIn:
      Text("Signed in")
        .font(.caption)
        .foregroundColor(.green)
    case .error(let message):
      Text(message)
        .font(.caption)
        .foregroundColor(.red)
        .multilineTextAlignment(.center)
    }
  }
}
