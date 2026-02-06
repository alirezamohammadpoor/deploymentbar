import AppKit
import SwiftUI

// MARK: - Color Hex Extension

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let scanner = Scanner(string: hex)
    var rgbValue: UInt64 = 0
    scanner.scanHexInt64(&rgbValue)

    let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
    let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
    let b = Double(rgbValue & 0x0000FF) / 255.0

    self.init(red: r, green: g, blue: b)
  }
}

// MARK: - Geist Design System

enum Geist {

  // MARK: - Colors (dark-only, no adaptive)

  enum Colors {
    static let backgroundPrimary = Color(hex: "#000000")
    static let backgroundSecondary = Color(hex: "#0A0A0A")

    // Gray scale
    static let gray100 = Color(hex: "#1A1A1A")
    static let gray200 = Color(hex: "#1F1F1F")
    static let gray300 = Color(hex: "#292929")
    static let gray400 = Color(hex: "#333333")
    static let gray500 = Color(hex: "#3F3F3F")
    static let gray600 = Color(hex: "#525252")
    static let gray700 = Color(hex: "#666666")
    static let gray800 = Color(hex: "#7A7A7A")
    static let gray900 = Color(hex: "#A1A1A1")
    static let gray1000 = Color(hex: "#EDEDED")

    // Semantic aliases
    static let rowExpanded = gray100
    static let rowHover = gray200
    static let border = gray500
    static let textTertiary = gray700
    static let textSecondary = gray900
    static let textPrimary = gray1000
    static let buttonText = gray1000
    static let badgeBackground = gray100

    // Status colors
    static let statusReady = Color(hex: "#00C853")
    static let statusBuilding = Color(hex: "#F5A623")
    static let statusError = Color(hex: "#EE0000")
    static let statusQueued = Color(hex: "#666666")
    static let statusCanceled = Color(hex: "#666666")

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

    // NSColor versions for status bar icon tinting
    enum StatusBarIcon {
      static let ready = NSColor(srgbRed: 0, green: 0xC8/255.0, blue: 0x53/255.0, alpha: 1)
      static let building = NSColor(srgbRed: 0xF5/255.0, green: 0xA6/255.0, blue: 0x23/255.0, alpha: 1)
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

  // MARK: - Typography

  enum Typography {
    static let projectName: Font = .custom("Geist-Medium", size: 13)
    static let commitMessage: Font = .custom("Geist-Regular", size: 12)
    static let caption: Font = .custom("Geist-Regular", size: 11)
    static let timestamp: Font = .custom("Geist-Regular", size: 11)
    static let author: Font = .custom("Geist-Regular", size: 11)
    static let captionSmall: Font = .custom("Geist-Regular", size: 10)
    static let sectionHeader: Font = .custom("Geist-SemiBold", size: 11)
    static let branchName: Font = .custom("GeistMono-Regular", size: 11)
    static let buildDuration: Font = .custom("GeistMono-Regular", size: 11)

    static let sectionHeaderTracking: CGFloat = 0.5

    enum Settings {
      static let sectionHeader: Font = .custom("Geist-Medium", size: 11)
      static let fieldLabel: Font = .custom("Geist-Medium", size: 13)
      static let helperText: Font = .custom("Geist-Regular", size: 11)
      static let inputText: Font = .custom("GeistMono-Regular", size: 13)
      static let button: Font = .custom("Geist-Medium", size: 13)
    }
  }

  // MARK: - Layout

  enum Layout {
    // Popover
    static let popoverWidth: CGFloat = 380
    static let popoverMaxHeight: CGFloat = 480
    static let popoverCornerRadius: CGFloat = 10
    static let popoverBorderWidth: CGFloat = 1

    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24

    // Row
    static let rowHeight: CGFloat = 64
    static let rowExpandedHeight: CGFloat = 140
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
