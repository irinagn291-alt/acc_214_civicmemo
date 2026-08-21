import XCTest
@testable import CivicMemo

@MainActor
final class SlotAssignReducerTests: XCTestCase {
  func testBreakCannotBeScheduled() async {
    // Given
    let article = CivicDemoSeed.shelf[0]
    let today = DayStamp(year: 2026, month: 8, day: 19)
    let store = TestStore(
      initialState: SlotAssignFeature.State(article: article, grams: 80, today: today)
    ) {
      SlotAssignFeature()
    }
    store.exhaustivity = .on

    // When
    await store.send(.pickSlot(.breakSlot)) {
      $0.slot = .breakSlot
    }
    await store.send(.pickKind(.scheduled)) {
      $0.notice = "Break cannot be planned. Pick AM Desk, Midday, or PM Desk."
    }

    // Then
    XCTAssertEqual(store.state.kind, .consumed)
    XCTAssertEqual(store.state.slot, .breakSlot)
  }

  func testConfirmWritesConsumedBreak() async {
    // Given
    let article = CivicDemoSeed.shelf[6]
    let today = DayStamp(year: 2026, month: 8, day: 19)
    let fixed = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
    let store = TestStore(
      initialState: SlotAssignFeature.State(article: article, grams: 30, today: today)
    ) {
      SlotAssignFeature()
    } withDependencies: {
      $0.uuid = .constant(fixed)
    }

    await store.send(.pickSlot(.breakSlot)) {
      $0.slot = .breakSlot
    }

    // When
    await store.send(.confirm)
    await store.receive({
      guard case .delegate(.committed(let record)) = $0 else { return false }
      return record.id == fixed && record.slot == .breakSlot && record.kind == .consumed
    })

    // Then
    XCTAssertEqual(store.state.slot, .breakSlot)
    XCTAssertEqual(store.state.kind, .consumed)
  }
}
