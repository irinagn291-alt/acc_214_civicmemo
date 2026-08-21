import XCTest
@testable import CivicMemo

final class EnergyUnitPolicyTests: XCTestCase {
  func testPrefersKilocalories() {
    // Given
    let kcal = 210.0
    let kj = 880.0

    // When
    let value = EnergyUnitPolicy.kilocalories(kcal100: kcal, kj100: kj)

    // Then
    XCTAssertEqual(value, 210.0)
  }

  func testFallsBackFromKilojoules() {
    // Given
    let kj = 418.4

    // When
    let value = EnergyUnitPolicy.kilocalories(kcal100: nil, kj100: kj)

    // Then
    XCTAssertEqual(value, 100.0, accuracy: 0.01)
  }
}
