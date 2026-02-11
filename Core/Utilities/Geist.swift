import AppKit
import SwiftUI

extension Color {
  init(hex: String) {
    self.init(nsColor: NSColor(hex: hex))
  }

  static func adaptive(light: String, dark: String) -> Color {
    Color(nsColor: NSColor(name: nil) { appearance in
      let best = appearance.bestMatch(from: [.darkAqua, .aqua])
      return NSColor(hex: best == .darkAqua ? dark : light)
    })
  }
}

private extension NSColor {
  convenience init(hex: String) {
    let normalized = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    var rgbValue: UInt64 = 0
    Scanner(string: normalized).scanHexInt64(&rgbValue)

    let red = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
    let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
    let blue = CGFloat(rgbValue & 0x0000FF) / 255.0

    self.init(srgbRed: red, green: green, blue: blue, alpha: 1.0)
  }
}

enum Geist {
  enum Colors {
    // Surfaces
    static let backgroundPrimary = Color.adaptive(light: "#FFFFFF", dark: "#000000")
    static let backgroundSecondary = Color.adaptive(light: "#FAFAFA", dark: "#0A0A0A")

    // Grays
    static let gray100 = Color.adaptive(light: "#F5F5F5", dark: "#1A1A1A")
    static let gray200 = Color.adaptive(light: "#F2F2F2", dark: "#1F1F1F")
    static let gray300 = Color.adaptive(light: "#EEEEEE", dark: "#292929")
    static let gray400 = Color.adaptive(light: "#EAEAEA", dark: "#333333")
    static let gray500 = Color.adaptive(light: "#E5E5E5", dark: "#3F3F3F")
    static let gray600 = Color.adaptive(light: "#D4D4D4", dark: "#525252")
    static let gray700 = Color.adaptive(light: "#999999", dark: "#666666")
    static let gray800 = Color.adaptive(light: "#666666", dark: "#7A7A7A")
    static let gray900 = Color.adaptive(light: "#666666", dark: "#A1A1A1")
    static let gray1000 = Color.adaptive(light: "#171717", dark: "#EDEDED")

    // Semantic aliases
    static let rowExpanded = gray100
    static let rowHover = gray200
    static let borderSubtle = gray400
    static let border = gray500
    static let textPrimary = gray1000
    static let textSecondary = gray900
    static let textTertiary = gray800
    static let buttonText = textPrimary
    static let badgeBackground = gray100

    // Status colors
    static let statusReady = Color(hex: "#00C853")
    static let statusBuilding = Color(hex: "#0070F3")
    static let statusError = Color(hex: "#EE0000")
    static let statusQueued = Color(hex: "#666666")
    static let statusCanceled = Color(hex: "#666666")
    static let statusWarning = Color(hex: "#F5A623")

    // Accent
    static let accent = Color(hex: "#0070F3")

    static func status(for state: DeploymentState) -> Color {
      switch state {
      case .ready: return statusReady
      case .building: return statusBuilding
      case .error: return statusError
      case .queued: return statusQueued
      case .canceled: return statusCanceled
      }
    }

    enum StatusBarIcon {
      static let ready = NSColor(srgbRed: 0, green: 0xC8/255.0, blue: 0x53/255.0, alpha: 1)
      static let building = NSColor(srgbRed: 0x00/255.0, green: 0x70/255.0, blue: 0xF3/255.0, alpha: 1)
      static let queued = NSColor(srgbRed: 0x66/255.0, green: 0x66/255.0, blue: 0x66/255.0, alpha: 1)
      static let error = NSColor(srgbRed: 0xEE/255.0, green: 0, blue: 0, alpha: 1)

      static func color(for state: DeploymentState?) -> NSColor? {
        switch state {
        case .ready: return ready
        case .building: return building
        case .queued: return queued
        case .error: return error
        case .canceled, nil: return nil
        }
      }
    }
  }

  enum Typography {
    static let projectName: Font = .system(size: 13, weight: .semibold, design: .default)
    static let commitMessage: Font = .system(size: 12, weight: .regular, design: .default)
    static let caption: Font = .system(size: 11, weight: .regular, design: .default)
    static let timestamp: Font = .system(size: 11, weight: .regular, design: .default)
    static let author: Font = .system(size: 11, weight: .regular, design: .default)
    static let captionSmall: Font = .system(size: 11, weight: .regular, design: .default)
    static let sectionHeader: Font = .system(size: 11, weight: .medium, design: .default)
    static let branchName: Font = .system(size: 11, weight: .medium, design: .monospaced)
    static let buildDuration: Font = .system(size: 11, weight: .regular, design: .monospaced)

    static let sectionHeaderTracking: CGFloat = 0.5

    enum Settings {
      static let sectionHeader: Font = .system(size: 11, weight: .medium, design: .default)
      static let fieldLabel: Font = .system(size: 11, weight: .regular, design: .default)
      static let helperText: Font = .system(size: 11, weight: .regular, design: .default)
      static let inputText: Font = .system(size: 12, weight: .regular, design: .monospaced)
      static let button: Font = .system(size: 13, weight: .semibold, design: .default)
    }
  }

  enum Layout {
    static let popoverWidth: CGFloat = 420
    static let popoverMaxHeight: CGFloat = 420
    static let popoverCornerRadius: CGFloat = 12
    static let popoverBorderWidth: CGFloat = 1

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24

    static let rowHeight: CGFloat = 84
    static let rowExpandedHeight: CGFloat = 168
    static let statusDotSize: CGFloat = 8
    static let rowPaddingH: CGFloat = 12
    static let rowPaddingV: CGFloat = 8
    static let rowSeparatorInset: CGFloat = 12
    static let badgePaddingH: CGFloat = 4
    static let badgePaddingV: CGFloat = 2
    static let badgeCornerRadius: CGFloat = 9999

    static let headerHeight: CGFloat = 34
    static let headerDropdownRadius: CGFloat = 6

    static let iconSizeSM: CGFloat = 10
    static let iconSizeMD: CGFloat = 14

    static let settingsWidth: CGFloat = 400
    static let settingsHPadding: CGFloat = 24
    static let settingsVPadding: CGFloat = 20
    static let settingsInputHeight: CGFloat = 36
    static let settingsInputRadius: CGFloat = 6
    static let settingsCardRadius: CGFloat = 8
    static let settingsCardPadding: CGFloat = 12
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
