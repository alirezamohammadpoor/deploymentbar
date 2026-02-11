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

      VStack(spacing: Geist.Layout.spacingSM) {
        Button("Continue") {
          authSession.startSignIn()
        }
        .disabled(authSessionIsBusy)

        if case .error = authSession.status {
          HStack(spacing: Geist.Layout.spacingMD) {
            Button("Retry Sign-In") {
              authSession.retryAuthorization()
            }
            .buttonStyle(.plain)
            .foregroundColor(Geist.Colors.textSecondary)

            Button("Reset Auth Session") {
              authSession.resetPendingAuthorization()
            }
            .buttonStyle(.plain)
            .foregroundColor(Geist.Colors.textSecondary)
          }
          .font(Geist.Typography.caption)
        }
      }
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
      VStack(spacing: Geist.Layout.spacingXS) {
        Text(message)
          .font(Geist.Typography.caption)
          .foregroundColor(Geist.Colors.statusError)
          .multilineTextAlignment(.center)
        if let hint = recoveryHint {
          Text(hint)
            .font(Geist.Typography.caption)
            .foregroundColor(Geist.Colors.textSecondary)
            .multilineTextAlignment(.center)
        }
      }
    }
  }

  private var recoveryHint: String? {
    switch authSession.lastAuthErrorCode {
    case .missingOAuthConfig:
      return "Add OAuth values in Info.plist / Secrets.xcconfig."
    case .authorizationURLBuildFailed:
      return "Could not build the authorization URL. Retry sign-in."
    case .stateMismatchMissingCode, .stateMismatchMissingState, .stateMismatchValueMismatch:
      return "The callback parameters were invalid. Reset the auth session and retry."
    case .sessionNotInitialized:
      return "Session state was lost. Reset auth and start again."
    case .oauthTokenExchangeFailed:
      return "Vercel token exchange failed. Retry sign-in."
    case .networkFailure:
      return "Check your internet connection and retry."
    case .none:
      return nil
    }
  }
}
