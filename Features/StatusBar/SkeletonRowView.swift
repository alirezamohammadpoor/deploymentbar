import SwiftUI

struct SkeletonRowView: View {
  @State private var shimmerOffset: CGFloat = -200

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      // Line 1: Status dot, project name, time
      HStack(spacing: Geist.Layout.spacingSM) {
        Circle()
          .fill(skeletonColor)
          .frame(width: Geist.Layout.statusDotSize, height: Geist.Layout.statusDotSize)

        skeletonRect(width: 120, height: 13)

        Spacer()

        skeletonRect(width: 40, height: 12)
      }

      // Line 2: Commit message
      HStack(spacing: Geist.Layout.spacingSM) {
        Color.clear
          .frame(width: Geist.Layout.statusDotSize)

        skeletonRect(width: 196, height: 12)
      }

      // Line 3: Branch, author
      HStack(spacing: Geist.Layout.spacingSM) {
        Color.clear
          .frame(width: Geist.Layout.statusDotSize)

        skeletonRect(width: 60, height: 16)
        skeletonRect(width: 80, height: 12)

        Spacer()
      }
    }
    .frame(height: Geist.Layout.rowHeight)
    .padding(.horizontal, Geist.Layout.rowPaddingH)
    .padding(.vertical, Geist.Layout.rowPaddingV)
    .onAppear {
      startShimmer()
    }
  }

  private var skeletonColor: Color {
    Geist.Colors.backgroundSecondary
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
          Geist.Colors.gray400.opacity(0.3),
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
