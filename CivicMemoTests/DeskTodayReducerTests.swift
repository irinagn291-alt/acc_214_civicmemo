import XCTest
@testable import CivicMemo

@MainActor
final class DeskTodayReducerTests: XCTestCase {
  func testApplyCommitUpdatesConsumedTotals() {
    let calendar = Calendar(identifier: .gregorian)
    let day = DayStamp(year: 2026, month: 8, day: 19)
    let seat = HouseholdSeat(
      id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
      deskLabel: "Desk North",
      initials: "DN"
    )
    let snapshot = SeatSnapshot(seat: seat, quota: .civicDefault, records: [], wishes: [])
    let article = CivicDemoSeed.shelf[0]
    let record = IntakeRecord(
      id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
      article: article,
      grams: 100,
      slot: .amDesk,
      day: day,
      kind: .consumed
    )
    let board = DeskTodayFeature(
      snapshot: snapshot,
      day: day,
      archive: .memoryPreview,
      calendar: calendar
    )

    board.applyCommit(record)

    XCTAssertEqual(board.totals.energyKcal, article.perHundred.energyKcal, accuracy: 0.001)
    XCTAssertEqual(board.consumed.count, 1)
    XCTAssertEqual(
      board.memoText,
      DayMemoComposer.text(snapshot: board.snapshot, day: day, calendar: calendar)
    )
  }
}
