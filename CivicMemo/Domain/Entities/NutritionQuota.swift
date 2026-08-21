import Foundation

struct NutritionQuota: Codable, Hashable, Sendable {
  var energyKcal: Double
  var proteinGrams: Double
  var carbGrams: Double
  var fatGrams: Double

  static let civicDefault = NutritionQuota(
    energyKcal: 2150,
    proteinGrams: 95,
    carbGrams: 240,
    fatGrams: 70
  )
}
