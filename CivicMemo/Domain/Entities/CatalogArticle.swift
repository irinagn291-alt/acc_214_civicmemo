import Foundation

struct CatalogArticle: Codable, Hashable, Identifiable, Sendable {
  var id: String
  var displayName: String
  var brandLine: String?
  var commodityCode: String?
  var perHundred: MacroBundle
  var defaultGrams: Double
  var shelfAsset: String?

  func portion(grams: Double) -> MacroBundle {
    PortionMeasure.bundle(perHundred: perHundred, grams: grams)
  }
}

struct CatalogFault: Error, Equatable, Sendable {
  var message: String
}
