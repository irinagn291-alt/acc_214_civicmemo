import Foundation

enum CivicDemoSeed {
  static let shelf: [CatalogArticle] = [
    CatalogArticle(
      id: "civic.oat-cup",
      displayName: "Civic Oat Cup",
      brandLine: "Desk Pantry",
      commodityCode: "4012345678901",
      perHundred: MacroBundle(energyKcal: 173, proteinGrams: 5.8, carbGrams: 29.4, fatGrams: 3.2),
      defaultGrams: 180,
      shelfAsset: "ShelfOat"
    ),
    CatalogArticle(
      id: "civic.lentil-tin",
      displayName: "Desk Lentil Tin",
      brandLine: "Civic Stores",
      commodityCode: "4012345678902",
      perHundred: MacroBundle(energyKcal: 116, proteinGrams: 9.0, carbGrams: 20.1, fatGrams: 0.6),
      defaultGrams: 200,
      shelfAsset: "ShelfLentil"
    ),
    CatalogArticle(
      id: "civic.rye-slice",
      displayName: "Memo Rye Slice",
      brandLine: "Charter Bakery",
      commodityCode: "4012345678903",
      perHundred: MacroBundle(energyKcal: 259, proteinGrams: 8.5, carbGrams: 48.3, fatGrams: 3.3),
      defaultGrams: 70,
      shelfAsset: "ShelfRye"
    ),
    CatalogArticle(
      id: "civic.yogurt",
      displayName: "Council Yogurt",
      brandLine: "Civic Dairy",
      commodityCode: "4012345678904",
      perHundred: MacroBundle(energyKcal: 73, proteinGrams: 4.1, carbGrams: 7.8, fatGrams: 2.9),
      defaultGrams: 150,
      shelfAsset: "ShelfYogurt"
    ),
    CatalogArticle(
      id: "civic.apple",
      displayName: "Ledger Apple",
      brandLine: "Orchard Desk",
      commodityCode: "4012345678905",
      perHundred: MacroBundle(energyKcal: 52, proteinGrams: 0.3, carbGrams: 14.0, fatGrams: 0.2),
      defaultGrams: 160,
      shelfAsset: "ShelfApple"
    ),
    CatalogArticle(
      id: "civic.broth",
      displayName: "Briefing Broth",
      brandLine: "Civic Kitchen",
      commodityCode: "4012345678906",
      perHundred: MacroBundle(energyKcal: 28, proteinGrams: 1.8, carbGrams: 2.4, fatGrams: 1.1),
      defaultGrams: 250,
      shelfAsset: "ShelfBroth"
    ),
    CatalogArticle(
      id: "civic.almonds",
      displayName: "Minute Almonds",
      brandLine: "Break Tin",
      commodityCode: "4012345678907",
      perHundred: MacroBundle(energyKcal: 579, proteinGrams: 21.2, carbGrams: 21.6, fatGrams: 49.9),
      defaultGrams: 30,
      shelfAsset: "ShelfAlmonds"
    ),
    CatalogArticle(
      id: "civic.tuna",
      displayName: "Charter Tuna",
      brandLine: "Harbor Desk",
      commodityCode: "4012345678908",
      perHundred: MacroBundle(energyKcal: 132, proteinGrams: 28.0, carbGrams: 0.0, fatGrams: 1.3),
      defaultGrams: 110,
      shelfAsset: "ShelfTuna"
    ),
  ]

  static func planted(
    seat: HouseholdSeat,
    today: DayStamp,
    calendar: Calendar,
    makeID: () -> UUID
  ) -> SeatSnapshot {
    let tomorrow = today.shifting(days: 1, calendar: calendar)
    let oat = shelf[0]
    let yogurt = shelf[3]
    let rye = shelf[2]
    let apple = shelf[4]
    let broth = shelf[5]
    let almonds = shelf[6]
    return SeatSnapshot(
      seat: seat,
      quota: .civicDefault,
      records: [
        IntakeRecord(id: makeID(), article: oat, grams: 180, slot: .amDesk, day: today, kind: .consumed),
        IntakeRecord(id: makeID(), article: yogurt, grams: 150, slot: .midday, day: today, kind: .consumed),
        IntakeRecord(id: makeID(), article: almonds, grams: 30, slot: .breakSlot, day: today, kind: .consumed),
        IntakeRecord(id: makeID(), article: rye, grams: 70, slot: .amDesk, day: tomorrow, kind: .scheduled),
        IntakeRecord(id: makeID(), article: broth, grams: 250, slot: .pmDesk, day: tomorrow, kind: .scheduled),
      ],
      wishes: [WishListing(id: apple.id, article: apple)]
    )
  }
}
