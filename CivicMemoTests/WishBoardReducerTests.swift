import XCTest
@testable import CivicMemo

@MainActor
final class WishBoardReducerTests: XCTestCase {
  func testPinRefusesDuplicateSKU() {
    let article = CivicDemoSeed.shelf[4]
    let existing = WishListing(id: article.id, article: article)
    let board = WishBoardFeature(wishes: [existing])

    board.pin(article)

    XCTAssertEqual(board.notice, "That SKU is already on the wish board.")
    XCTAssertEqual(board.wishes.count, 1)
  }

  func testPinAcceptsNewSKU() {
    let article = CivicDemoSeed.shelf[4]
    let board = WishBoardFeature(wishes: [])

    board.pin(article)

    XCTAssertEqual(board.wishes.first?.id, article.id)
  }
}
