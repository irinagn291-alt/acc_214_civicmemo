import Foundation

enum DayMemoComposer {
  static func text(snapshot: SeatSnapshot, day: DayStamp, calendar: Calendar) -> String {
    let consumed = snapshot.records.filter { $0.kind == .consumed && $0.day == day }
    let totals = snapshot.consumedBundle(on: day)
    var lines: [String] = [
      "CIVIC MEMO",
      "Desk: \(snapshot.seat.deskLabel)",
      "Date: \(day.titled(calendar: calendar))",
      "Quota: \(Int(snapshot.quota.energyKcal)) kcal · \(Int(snapshot.quota.proteinGrams)) P · \(Int(snapshot.quota.carbGrams)) C · \(Int(snapshot.quota.fatGrams)) F",
      "Consumed: \(Int(totals.energyKcal.rounded())) kcal · \(Int(totals.proteinGrams.rounded())) P · \(Int(totals.carbGrams.rounded())) C · \(Int(totals.fatGrams.rounded())) F",
      "",
    ]
    for slot in DeskSlot.allCases {
      let rows = consumed.filter { $0.slot == slot }
      guard !rows.isEmpty else { continue }
      lines.append(slot.deskTitle.uppercased())
      for row in rows {
        let bundle = row.portionBundle
        lines.append("  · \(row.article.displayName) · \(Int(row.grams)) g · \(Int(bundle.energyKcal.rounded())) kcal")
      }
      lines.append("")
    }
    if consumed.isEmpty {
      lines.append("No consumed rows on this desk day.")
    }
    return lines.joined(separator: "\n")
  }
}
