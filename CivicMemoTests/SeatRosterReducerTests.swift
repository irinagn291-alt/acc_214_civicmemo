import XCTest
@testable import CivicMemo

@MainActor
final class SeatRosterReducerTests: XCTestCase {
  func testRefusesFifthSeatAndSecondDrop() async {
    // Given
    let seats = [
      HouseholdSeat(id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!, deskLabel: "Desk North", initials: "DN"),
      HouseholdSeat(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, deskLabel: "Desk South", initials: "DS"),
      HouseholdSeat(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, deskLabel: "Desk East", initials: "DE"),
      HouseholdSeat(id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, deskLabel: "Desk West", initials: "DW"),
    ]
    let roster = HouseholdRoster(
      seats: seats,
      activeSeatID: seats[0].id,
      briefingCompleted: true,
      demoPlanted: true
    )
    let store = TestStore(initialState: SeatRosterFeature.State(roster: roster)) {
      SeatRosterFeature()
    }

    // When
    await store.send(.addSeat) {
      $0.notice = "Four seats is the household ceiling."
    }

    // Then
    XCTAssertEqual(store.state.roster.seats.count, 4)

    let pair = HouseholdRoster(
      seats: Array(seats.prefix(2)),
      activeSeatID: seats[0].id,
      briefingCompleted: true,
      demoPlanted: true
    )
    let pairStore = TestStore(initialState: SeatRosterFeature.State(roster: pair)) {
      SeatRosterFeature()
    }

    // When
    await pairStore.send(.dropSeat(seats[1].id)) {
      $0.notice = "Two seats stay on the household desk."
    }

    // Then
    XCTAssertEqual(pairStore.state.roster.seats.count, 2)
  }
}
