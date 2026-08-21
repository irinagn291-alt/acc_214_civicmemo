import Foundation

struct HouseholdSeat: Codable, Hashable, Identifiable, Sendable {
  var id: UUID
  var deskLabel: String
  var initials: String
}

struct WishListing: Codable, Hashable, Identifiable, Sendable {
  var id: String
  var article: CatalogArticle
}

struct SeatSnapshot: Codable, Hashable, Sendable {
  var seat: HouseholdSeat
  var quota: NutritionQuota
  var records: [IntakeRecord]
  var wishes: [WishListing]

  var ledger: IntakeLedger { IntakeLedger(records: records) }

  mutating func append(_ record: IntakeRecord) {
    records.append(record)
  }

  mutating func removeRecord(_ id: UUID) {
    records.removeAll { $0.id == id }
  }

  mutating func pinWish(_ article: CatalogArticle) -> Bool {
    guard !wishes.contains(where: { $0.id == article.id }) else { return false }
    wishes.append(WishListing(id: article.id, article: article))
    return true
  }

  mutating func unpinWish(_ sku: String) {
    wishes.removeAll { $0.id == sku }
  }

  func consumedBundle(on day: DayStamp) -> MacroBundle {
    IntakeLedger(records: records).totals(kind: .consumed, day: day)
  }
}

struct HouseholdRoster: Codable, Hashable, Sendable {
  var seats: [HouseholdSeat]
  var activeSeatID: UUID
  var briefingCompleted: Bool
  var demoPlanted: Bool

  var activeSeat: HouseholdSeat? {
    seats.first { $0.id == activeSeatID }
  }
}
