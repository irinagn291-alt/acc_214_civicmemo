import Foundation

enum LedgerKind: String, Codable, Sendable, Hashable {
  case consumed
  case scheduled
}

struct IntakeRecord: Codable, Hashable, Identifiable, Sendable {
  var id: UUID
  var article: CatalogArticle
  var grams: Double
  var slot: DeskSlot
  var day: DayStamp
  var kind: LedgerKind

  var portionBundle: MacroBundle {
    article.portion(grams: grams)
  }
}

struct IntakeLedger: Codable, Hashable, Sendable {
  var records: [IntakeRecord]

  func rows(kind: LedgerKind, day: DayStamp) -> [IntakeRecord] {
    records.filter { $0.kind == kind && $0.day == day }
  }

  func totals(kind: LedgerKind, day: DayStamp) -> MacroBundle {
    rows(kind: kind, day: day).map(\.portionBundle).reduce(.zero, +)
  }

  mutating func append(_ record: IntakeRecord) {
    records.append(record)
  }

  mutating func remove(id: UUID) {
    records.removeAll { $0.id == id }
  }
}
