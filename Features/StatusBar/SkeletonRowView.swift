import SwiftUI

struct SkeletonRowView: View {
  @State private var shimmerOffset: CGFloat = -200

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Line 1: Status dot, project name, time
      HStack(spacing: Theme.Layout.spacingSM) {
        Circle()
          .fill(skeletonColor)
          .frame(width: Theme.Layout.statusDotSize, height: Theme.Layout.statusDotSize)

        skeletonRect(width: 120, height: 14)

        Spacer()

        skeletonRect(width: 40, height: 12)
      }

      // Line 2: Commit message
      HStack(spacing: Theme.Layout.spacingSM) {
        Color.clear
          .frame(width: Theme.Layout.statusDotSize)

        skeletonRect(width: 200, height: 12)
      }

      // Line 3: Branch, author
      HStack(spacing: Theme.Layout.spacingSM) {
        Color.clear
          .frame(width: Theme.Layout.statusDotSize)

        skeletonRect(width: 60, height: 16)
        skeletonRect(width: 80, height: 12)

        Spacer()
      }
    }
    .frame(height: Theme.Layout.rowHeight)
    .padding(.horizontal, Theme.Layout.spacingSM)
    .padding(.vertical, Theme.Layout.spacingXS)
    .onAppear {
      startShimmer()
    }
  }

  private var skeletonColor: Color {
    Theme.Colors.backgroundSecondary
  }

  private func skeletonRect(width: CGFloat, height: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 4)
      .fill(skeletonColor)
      .frame(width: width, height: height)
      .overlay(shimmerOverlay)
      .clipped()
  }

  private var shimmerOverlay: some View {
    GeometryReader { geometry in
      LinearGradient(
        colors: [
          Color.clear,
          Color.white.opacity(0.1),
          Color.clear
        ],
        startPoint: .leading,
        endPoint: .trailing
      )
      .frame(width: 100)
      .offset(x: shimmerOffset)
    }
  }

  private func startShimmer() {
    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }

    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
      shimmerOffset = 400
    }
  }
}

struct SkeletonLoadingView: View {
  var body: some View {
    VStack(spacing: 0) {
      ForEach(0..<5, id: \.self) { _ in
        SkeletonRowView()
      }
    }
  }
}
