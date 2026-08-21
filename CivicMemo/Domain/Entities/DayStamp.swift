import Foundation

struct DayStamp: Codable, Hashable, Sendable, Comparable {
  var year: Int
  var month: Int
  var day: Int

  static func from(_ date: Date, calendar: Calendar) -> DayStamp {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    return DayStamp(year: parts.year ?? 0, month: parts.month ?? 0, day: parts.day ?? 0)
  }

  func dateValue(calendar: Calendar) -> Date {
    calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? .distantPast
  }

  func shifting(days: Int, calendar: Calendar) -> DayStamp {
    let moved = calendar.date(byAdding: .day, value: days, to: dateValue(calendar: calendar)) ?? .distantPast
    return DayStamp.from(moved, calendar: calendar)
  }

  func titled(calendar: Calendar) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "d MMM yyyy"
    return formatter.string(from: dateValue(calendar: calendar))
  }

  static func < (lhs: DayStamp, rhs: DayStamp) -> Bool {
    if lhs.year != rhs.year { return lhs.year < rhs.year }
    if lhs.month != rhs.month { return lhs.month < rhs.month }
    return lhs.day < rhs.day
  }
}
