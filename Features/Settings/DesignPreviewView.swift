import SwiftUI

struct DesignPreviewView: View {
  @State private var buildPulse: Double = 1.0

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // Color Swatches
      colorSwatches

      Divider()

      // Font Samples
      fontSamples

      Divider()

      // Status Dots
      statusDots

      Divider()

      // Sample Deployment Row
      sampleRow

      Divider()

      // Button Samples
      buttonSamples
    }
  }

  // MARK: - Color Swatches

  private var colorSwatches: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Colors")
        .font(Geist.Typography.Settings.sectionHeader)
        .foregroundColor(Geist.Colors.textSecondary)
        .textCase(.uppercase)
        .tracking(0.5)

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 6) {
        colorSwatch("bg1", Geist.Colors.backgroundPrimary, "#000")
        colorSwatch("bg2", Geist.Colors.backgroundSecondary, "#0A0A0A")
        colorSwatch("g100", Geist.Colors.gray100, "#1A1A1A")
        colorSwatch("g200", Geist.Colors.gray200, "#1F1F1F")
        colorSwatch("g300", Geist.Colors.gray300, "#292929")
        colorSwatch("g400", Geist.Colors.gray400, "#333")
        colorSwatch("g500", Geist.Colors.gray500, "#3F3F3F")
        colorSwatch("g600", Geist.Colors.gray600, "#525252")
        colorSwatch("g700", Geist.Colors.gray700, "#666")
        colorSwatch("g900", Geist.Colors.gray900, "#A1A1A1")
        colorSwatch("g1000", Geist.Colors.gray1000, "#EDEDED")
        colorSwatch("ready", Geist.Colors.statusReady, "#00C853")
        colorSwatch("build", Geist.Colors.statusBuilding, "#F5A623")
        colorSwatch("error", Geist.Colors.statusError, "#EE0000")
        colorSwatch("accent", Geist.Colors.accent, "#0070F3")
      }
    }
  }

  private func colorSwatch(_ label: String, _ color: Color, _ hex: String) -> some View {
    VStack(spacing: 2) {
      RoundedRectangle(cornerRadius: 4)
        .fill(color)
        .frame(height: 28)
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Geist.Colors.gray500, lineWidth: 0.5)
        )
      Text(label)
        .font(.custom("Geist-Regular", size: 9))
        .foregroundColor(Geist.Colors.textTertiary)
      Text(hex)
        .font(.custom("GeistMono-Regular", size: 8))
        .foregroundColor(Geist.Colors.textTertiary)
    }
  }

  // MARK: - Font Samples

  private var fontSamples: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Typography")
        .font(Geist.Typography.Settings.sectionHeader)
        .foregroundColor(Geist.Colors.textSecondary)
        .textCase(.uppercase)
        .tracking(0.5)

      Group {
        Text("Geist Medium 13 — Project Name")
          .font(Geist.Typography.projectName)
        Text("Geist Regular 12 — Commit message")
          .font(Geist.Typography.commitMessage)
        Text("Geist Regular 11 — Caption / Timestamp")
          .font(Geist.Typography.caption)
        Text("Geist Regular 10 — Caption Small")
          .font(Geist.Typography.captionSmall)
        Text("GEIST SEMIBOLD 11 — SECTION HEADER")
          .font(Geist.Typography.sectionHeader)
          .tracking(Geist.Typography.sectionHeaderTracking)
        Text("GeistMono Regular 11 — feature/branch-name")
          .font(Geist.Typography.branchName)
        Text("GeistMono Regular 11 — 42s build duration")
          .font(Geist.Typography.buildDuration)
        Text("GeistMono Regular 13 — Input text")
          .font(Geist.Typography.Settings.inputText)
      }
      .foregroundColor(Geist.Colors.textPrimary)
    }
  }

  // MARK: - Status Dots

  private var statusDots: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Status Indicators")
        .font(Geist.Typography.Settings.sectionHeader)
        .foregroundColor(Geist.Colors.textSecondary)
        .textCase(.uppercase)
        .tracking(0.5)

      HStack(spacing: 16) {
        statusDot("Ready", Geist.Colors.statusReady, pulses: false)
        statusDot("Building", Geist.Colors.statusBuilding, pulses: true)
        statusDot("Error", Geist.Colors.statusError, pulses: false)
        statusDot("Queued", Geist.Colors.statusQueued, pulses: false)
        statusDot("Canceled", Geist.Colors.statusCanceled, pulses: false)
      }
    }
    .onAppear {
      if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
          buildPulse = 0.3
        }
      }
    }
  }

  private func statusDot(_ label: String, _ color: Color, pulses: Bool) -> some View {
    VStack(spacing: 4) {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)
        .opacity(pulses ? buildPulse : 1.0)
      Text(label)
        .font(Geist.Typography.captionSmall)
        .foregroundColor(Geist.Colors.textTertiary)
    }
  }

  // MARK: - Sample Deployment Row

  private var sampleRow: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Sample Row")
        .font(Geist.Typography.Settings.sectionHeader)
        .foregroundColor(Geist.Colors.textSecondary)
        .textCase(.uppercase)
        .tracking(0.5)

      VStack(alignment: .leading, spacing: 4) {
        // Line 1
        HStack(spacing: Geist.Layout.spacingSM) {
          Circle()
            .fill(Geist.Colors.statusReady)
            .frame(width: Geist.Layout.statusDotSize, height: Geist.Layout.statusDotSize)

          Text("my-project")
            .font(Geist.Typography.projectName)
            .foregroundColor(Geist.Colors.textPrimary)

          Spacer()

          Text("32s")
            .font(Geist.Typography.buildDuration)
            .foregroundColor(Geist.Colors.textTertiary)

          Text("·")
            .font(Geist.Typography.timestamp)
            .foregroundColor(Geist.Colors.textTertiary)

          Text("2m ago")
            .font(Geist.Typography.timestamp)
            .foregroundColor(Geist.Colors.textTertiary)
        }

        // Line 2
        HStack(spacing: Geist.Layout.spacingSM) {
          Color.clear
            .frame(width: Geist.Layout.statusDotSize)
          Text("fix: resolve login redirect issue")
            .font(Geist.Typography.commitMessage)
            .foregroundColor(Geist.Colors.textSecondary)
        }

        // Line 3
        HStack(spacing: Geist.Layout.spacingSM) {
          Color.clear
            .frame(width: Geist.Layout.statusDotSize)
          Text("main")
            .font(Geist.Typography.branchName)
            .foregroundColor(Geist.Colors.textSecondary)
            .padding(.horizontal, Geist.Layout.badgePaddingH)
            .padding(.vertical, Geist.Layout.badgePaddingV)
            .background(Geist.Colors.badgeBackground)
            .cornerRadius(Geist.Layout.badgeCornerRadius)

          Text("by vercel-user")
            .font(Geist.Typography.author)
            .foregroundColor(Geist.Colors.textTertiary)
        }
      }
      .padding(Geist.Layout.spacingSM)
      .background(Geist.Colors.backgroundSecondary)
      .cornerRadius(6)
    }
  }

  // MARK: - Button Samples

  private var buttonSamples: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Buttons")
        .font(Geist.Typography.Settings.sectionHeader)
        .foregroundColor(Geist.Colors.textSecondary)
        .textCase(.uppercase)
        .tracking(0.5)

      HStack(spacing: 8) {
        previewButton("Copy URL", icon: "doc.on.doc")
        previewButton("Open in Browser", icon: "globe")
        previewButton("Open in Vercel", icon: "safari")
      }
    }
  }

  private func previewButton(_ label: String, icon: String) -> some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
        .font(.system(size: 11))
      Text(label)
        .font(Geist.Typography.caption)
    }
    .foregroundColor(Geist.Colors.buttonText)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 6)
        .stroke(Geist.Colors.border, lineWidth: 1)
    )
  }
}
