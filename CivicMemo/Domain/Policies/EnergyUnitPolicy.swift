import Foundation

enum EnergyUnitPolicy {
  static func kilocalories(kcal100: Double?, kj100: Double?) -> Double {
    if let kcal100, kcal100 > 0 { return kcal100 }
    if let kj100, kj100 > 0 { return kj100 / 4.184 }
    return 0
  }
}
