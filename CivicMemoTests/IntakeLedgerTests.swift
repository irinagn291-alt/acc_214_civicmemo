import XCTest
@testable import CivicMemo

final class IntakeLedgerTests: XCTestCase {
  func testPortionScaleAndDailyTotals() {
    // Given
    let article = CivicDemoSeed.shelf[0]
    let day = DayStamp(year: 2026, month: 8, day: 19)
    let record = IntakeRecord(
      id: UUID(),
      article: article,
      grams: 50,
      slot: .amDesk,
      day: day,
      kind: .consumed
    )
    var ledger = IntakeLedger(records: [])

    // When
    ledger.append(record)
    let totals = ledger.totals(kind: .consumed, day: day)

    // Then
    XCTAssertEqual(totals.energyKcal, article.perHundred.energyKcal * 50 / 100, accuracy: 0.001)
    XCTAssertEqual(totals.proteinGrams, article.perHundred.proteinGrams * 50 / 100, accuracy: 0.001)
  }
}
