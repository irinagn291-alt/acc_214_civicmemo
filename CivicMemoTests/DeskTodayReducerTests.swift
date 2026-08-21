import XCTest
@testable import CivicMemo

@MainActor
final class DeskTodayReducerTests: XCTestCase {
  func testApplyCommitUpdatesConsumedTotals() async {
    // Given
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
    let store = TestStore(initialState: DeskTodayFeature.State(snapshot: snapshot, day: day)) {
      DeskTodayFeature()
    } withDependencies: {
      $0.calendar = calendar
      $0.seatFileArchive = .memoryPreview
    }

    // When
    await store.send(.applyCommit(record)) {
      $0.snapshot.records = [record]
      $0.memoText = DayMemoComposer.text(snapshot: $0.snapshot, day: day, calendar: calendar)
    }
    await store.finish()

    // Then
    XCTAssertEqual(store.state.totals.energyKcal, article.perHundred.energyKcal, accuracy: 0.001)
    XCTAssertEqual(store.state.consumed.count, 1)
  }
}
