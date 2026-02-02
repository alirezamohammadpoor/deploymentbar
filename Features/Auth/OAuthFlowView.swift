import SwiftUI

struct OAuthFlowView: View {
  var body: some View {
    VStack(spacing: 12) {
      Text("Sign in with Vercel")
        .font(.headline)
      Button("Continue") {
        // TODO: open OAuth authorization URL.
      }
    }
    .padding(16)
  }
}
