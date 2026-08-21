import Foundation

struct MacroBundle: Codable, Hashable, Sendable {
  var energyKcal: Double
  var proteinGrams: Double
  var carbGrams: Double
  var fatGrams: Double

  static let zero = MacroBundle(energyKcal: 0, proteinGrams: 0, carbGrams: 0, fatGrams: 0)

  static func + (lhs: MacroBundle, rhs: MacroBundle) -> MacroBundle {
    MacroBundle(
      energyKcal: lhs.energyKcal + rhs.energyKcal,
      proteinGrams: lhs.proteinGrams + rhs.proteinGrams,
      carbGrams: lhs.carbGrams + rhs.carbGrams,
      fatGrams: lhs.fatGrams + rhs.fatGrams
    )
  }
}

enum PortionMeasure {
  static func scaled(perHundred: Double, grams: Double) -> Double {
    perHundred * grams / 100
  }

  static func bundle(perHundred: MacroBundle, grams: Double) -> MacroBundle {
    MacroBundle(
      energyKcal: scaled(perHundred: perHundred.energyKcal, grams: grams),
      proteinGrams: scaled(perHundred: perHundred.proteinGrams, grams: grams),
      carbGrams: scaled(perHundred: perHundred.carbGrams, grams: grams),
      fatGrams: scaled(perHundred: perHundred.fatGrams, grams: grams)
    )
  }
}
