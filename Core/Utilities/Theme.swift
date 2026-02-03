import AppKit
import SwiftUI

enum Theme {
  // MARK: - Colors

  enum Colors {
    static let backgroundPrimary = adaptive(light: .init(white: 1, alpha: 1),
                                            dark: .init(white: 0, alpha: 1))
    static let backgroundSecondary = adaptive(light: .init(white: 0.98, alpha: 1),
                                              dark: .init(white: 0.039, alpha: 1))
    static let border = adaptive(light: .init(white: 0.898, alpha: 1),
                                 dark: .init(white: 0.2, alpha: 1))
    static let textPrimary = adaptive(light: .init(white: 0, alpha: 1),
                                      dark: .init(white: 1, alpha: 1))
    static let textSecondary = adaptive(light: .init(srgbRed: 0.4, green: 0.4, blue: 0.4, alpha: 1),
                                        dark: .init(srgbRed: 0.533, green: 0.533, blue: 0.533, alpha: 1))
    static let textTertiary = adaptive(light: .init(srgbRed: 0.6, green: 0.6, blue: 0.6, alpha: 1),
                                       dark: .init(srgbRed: 0.4, green: 0.4, blue: 0.4, alpha: 1))

    private static func adaptive(light: NSColor, dark: NSColor) -> Color {
      Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
      }))
    }

    // Settings-specific hardcoded dark-mode palette
    enum Settings {
      static let background100 = Color(red: 0, green: 0, blue: 0)
      static let accents1 = Color(red: 0x11/255.0, green: 0x11/255.0, blue: 0x11/255.0)
      static let accents2 = Color(red: 0x1a/255.0, green: 0x1a/255.0, blue: 0x1a/255.0)
      static let accents4 = Color(red: 0x66/255.0, green: 0x66/255.0, blue: 0x66/255.0)
      static let accents5 = Color(red: 0x88/255.0, green: 0x88/255.0, blue: 0x88/255.0)
      static let foreground = Color.white
      static let border = Color(red: 0x33/255.0, green: 0x33/255.0, blue: 0x33/255.0)
      static let success = Color(red: 0x50/255.0, green: 0xe3/255.0, blue: 0xc2/255.0)
    }

    // Status colors (invariant across light/dark)
    static let statusReady = Color(red: 0.18, green: 0.80, blue: 0.44)
    static let statusBuilding = Color(red: 0.95, green: 0.62, blue: 0.07)
    static let statusError = Color(red: 0.93, green: 0.26, blue: 0.26)
    static let statusCanceled = Color(red: 0.53, green: 0.53, blue: 0.53)

    static func status(for state: DeploymentState) -> Color {
      switch state {
      case .ready: return statusReady
      case .building: return statusBuilding
      case .error: return statusError
      case .canceled: return statusCanceled
      }
    }
  }

  // MARK: - Typography

  enum Typography {
    static let projectName: Font = .system(size: 13, weight: .medium)
    static let branchName: Font = .system(size: 11, design: .monospaced)
    static let timestamp: Font = .system(size: 11)
    static let sectionHeader: Font = .system(size: 11, weight: .semibold)
    static let caption: Font = .system(size: 11)
    static let captionSmall: Font = .system(size: 10)

    static let sectionHeaderTracking: CGFloat = 0.5

    // Settings-specific typography
    enum Settings {
      static let sectionHeader: Font = .system(size: 11, weight: .medium)
      static let fieldLabel: Font = .system(size: 13)
      static let helperText: Font = .system(size: 11)
      static let inputText: Font = .system(size: 13, design: .monospaced)
      static let button: Font = .system(size: 13, weight: .medium)
    }
  }

  // MARK: - Layout

  enum Layout {
    // Popover
    static let popoverWidth: CGFloat = 320
    static let popoverMaxHeight: CGFloat = 400
    static let popoverCornerRadius: CGFloat = 10
    static let popoverBorderWidth: CGFloat = 1

    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24

    // Row
    static let rowHeight: CGFloat = 44
    static let statusDotSize: CGFloat = 8
    static let badgePaddingH: CGFloat = 6
    static let badgePaddingV: CGFloat = 2
    static let badgeCornerRadius: CGFloat = 4

    // Settings
    static let settingsWidth: CGFloat = 400
    static let settingsHPadding: CGFloat = 24
    static let settingsVPadding: CGFloat = 20
    static let settingsInputHeight: CGFloat = 36
    static let settingsInputRadius: CGFloat = 6
    static let settingsIconButtonSize: CGFloat = 28
  }

  // MARK: - Section Header Style

  struct SectionHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
      content
        .font(Typography.sectionHeader)
        .foregroundColor(Colors.textSecondary)
        .textCase(.uppercase)
        .tracking(Typography.sectionHeaderTracking)
    }
  }
}

extension View {
  func sectionHeaderStyle() -> some View {
    modifier(Theme.SectionHeaderStyle())
  }
}
