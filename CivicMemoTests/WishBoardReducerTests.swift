import XCTest
@testable import CivicMemo

@MainActor
final class WishBoardReducerTests: XCTestCase {
  func testPinRefusesDuplicateSKU() async {
    // Given
    let article = CivicDemoSeed.shelf[4]
    let existing = WishListing(id: article.id, article: article)
    let store = TestStore(initialState: WishBoardFeature.State(wishes: [existing])) {
      WishBoardFeature()
    }

    // When
    await store.send(.pin(article)) {
      $0.notice = "That SKU is already on the wish board."
    }

    // Then
    XCTAssertEqual(store.state.wishes.count, 1)
  }

  func testPinAcceptsNewSKU() async {
    // Given
    let article = CivicDemoSeed.shelf[4]
    let store = TestStore(initialState: WishBoardFeature.State(wishes: [])) {
      WishBoardFeature()
    }

    // When
    await store.send(.pin(article)) {
      $0.wishes = [WishListing(id: article.id, article: article)]
    }

    // Then
    XCTAssertEqual(store.state.wishes.first?.id, article.id)
  }
}
