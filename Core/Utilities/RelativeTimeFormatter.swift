import Foundation

struct RelativeTimeFormatter {
  private static let formatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter
  }()

  static func string(from date: Date, now: Date = Date()) -> String {
    formatter.localizedString(for: date, relativeTo: now)
  }
}
