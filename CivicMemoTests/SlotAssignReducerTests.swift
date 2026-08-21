import XCTest
@testable import CivicMemo

@MainActor
final class SlotAssignReducerTests: XCTestCase {
  func testBreakCannotBeScheduled() {
    let article = CivicDemoSeed.shelf[0]
    let today = DayStamp(year: 2026, month: 8, day: 19)
    let board = SlotAssignFeature(article: article, grams: 80, today: today)

    board.pickSlot(.breakSlot)
    board.pickKind(.scheduled)

    XCTAssertEqual(board.notice, "Break cannot be planned. Pick AM Desk, Midday, or PM Desk.")
    XCTAssertEqual(board.kind, .consumed)
    XCTAssertEqual(board.slot, .breakSlot)
  }

  func testConfirmWritesConsumedBreak() {
    let article = CivicDemoSeed.shelf[6]
    let today = DayStamp(year: 2026, month: 8, day: 19)
    let fixed = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
    let board = SlotAssignFeature(article: article, grams: 30, today: today, makeID: { fixed })

    board.pickSlot(.breakSlot)
    let record = board.confirm()

    XCTAssertEqual(record?.id, fixed)
    XCTAssertEqual(record?.slot, .breakSlot)
    XCTAssertEqual(record?.kind, .consumed)
    XCTAssertEqual(board.slot, .breakSlot)
    XCTAssertEqual(board.kind, .consumed)
  }
}
