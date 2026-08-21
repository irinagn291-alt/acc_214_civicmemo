import XCTest
@testable import CivicMemo

final class CommodityCodePolicyTests: XCTestCase {
  func testExtractsDigitsAndPadsUPC12() {
    // Given
    let raw = "https://world.openfoodfacts.org/product/012345678901"

    // When
    let code = CommodityCodePolicy.normalize(raw)

    // Then
    XCTAssertEqual(code, "0012345678901")
  }

  func testKeepsEAN13() {
    // Given
    let raw = "EAN 4012345678901 extra"

    // When
    let code = CommodityCodePolicy.normalize(raw)

    // Then
    XCTAssertEqual(code, "4012345678901")
  }

  func testRejectsShortPayload() {
    // Given
    let raw = "1234567"

    // When
    let code = CommodityCodePolicy.normalize(raw)

    // Then
    XCTAssertNil(code)
  }
}
