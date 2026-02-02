import SwiftUI

struct DeploymentRowView: View {
  let title: String
  let subtitle: String

  var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(title)
        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      Spacer()
      Text("Status")
        .font(.caption2)
    }
  }
}
