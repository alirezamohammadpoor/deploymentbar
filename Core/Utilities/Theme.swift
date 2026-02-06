import AppKit
import SwiftUI

/// Legacy Theme — all tokens now forward to Geist.
/// Kept as typealias shell so any straggling references still compile.
enum Theme {
  typealias Colors = Geist.Colors
  typealias Typography = Geist.Typography
  typealias Layout = Geist.Layout
  typealias SectionHeaderStyle = Geist.SectionHeaderStyle
}

extension View {
  func sectionHeaderStyle() -> some View {
    modifier(Geist.SectionHeaderStyle())
  }
}
