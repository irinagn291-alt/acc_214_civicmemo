import Foundation

struct CatalogGateway: Sendable {
  var search: @Sendable (_ term: String) async throws -> [CatalogArticle]
  var lookup: @Sendable (_ code: String) async throws -> CatalogArticle
}

extension CatalogGateway {
  static let shelfOnly = CatalogGateway(
    search: { term in
      let needle = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      guard !needle.isEmpty else { return CivicDemoSeed.shelf }
      return CivicDemoSeed.shelf.filter {
        $0.displayName.lowercased().contains(needle) || ($0.brandLine?.lowercased().contains(needle) ?? false)
      }
    },
    lookup: { code in
      let normalized = CommodityCodePolicy.normalize(code) ?? code
      if let hit = CivicDemoSeed.shelf.first(where: { $0.commodityCode == normalized }) {
        return hit
      }
      throw CatalogFault(message: "No shelf article for that code.")
    }
  )

  static let worldOffice = CatalogGateway(
    search: { term in
      try await CivicCatalogTransport.search(term: term)
    },
    lookup: { code in
      try await CivicCatalogTransport.lookup(code: code)
    }
  )
}

private enum CivicCatalogTransport {
  static let agent = "CivicMemo/1.0 (iOS; com.civicmemo.desk; civicmemo@desk.local)"

  static func search(term: String) async throws -> [CatalogArticle] {
    var parts = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")
    parts?.queryItems = [
      URLQueryItem(name: "search_terms", value: term),
      URLQueryItem(name: "search_simple", value: "1"),
      URLQueryItem(name: "action", value: "process"),
      URLQueryItem(name: "json", value: "1"),
      URLQueryItem(name: "page_size", value: "24"),
    ]
    guard let url = parts?.url else { throw CatalogFault(message: "Lookup address was invalid.") }
    let payload: SearchEnvelope = try await fetch(url)
    return payload.products.compactMap(mapProduct)
  }

  static func lookup(code: String) async throws -> CatalogArticle {
    guard let normalized = CommodityCodePolicy.normalize(code) else {
      throw CatalogFault(message: "Need 8–14 digits for a commodity code.")
    }
    guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(normalized).json") else {
      throw CatalogFault(message: "Lookup address was invalid.")
    }
    let payload: ProductEnvelope = try await fetch(url)
    guard payload.status == 1, let product = payload.product, let article = mapProduct(product) else {
      throw CatalogFault(message: "That code is not in the civic catalog.")
    }
    return article
  }

  static func fetch<T: Decodable>(_ url: URL) async throws -> T {
    var request = URLRequest(url: url)
    request.setValue(agent, forHTTPHeaderField: "User-Agent")
    request.timeoutInterval = 20
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
      throw CatalogFault(message: "Catalog desk did not answer.")
    }
    do {
      return try JSONDecoder().decode(T.self, from: data)
    } catch {
      throw CatalogFault(message: "Catalog memo could not be read.")
    }
  }

  static func mapProduct(_ product: RemoteProduct) -> CatalogArticle? {
    let name = (product.productName?.trimmingCharacters(in: .whitespacesAndNewlines)).flatMap { $0.isEmpty ? nil : $0 }
      ?? "Unnamed commodity"
    let nutriments = product.nutriments
    let kcal = EnergyUnitPolicy.kilocalories(
      kcal100: nutriments?.energyKcal,
      kj100: nutriments?.energyKj
    )
    let code = product.code.flatMap(CommodityCodePolicy.normalize) ?? product.code
    let sku = code ?? name.lowercased()
    return CatalogArticle(
      id: sku,
      displayName: name,
      brandLine: product.brands,
      commodityCode: code,
      perHundred: MacroBundle(
        energyKcal: kcal,
        proteinGrams: nutriments?.proteins ?? 0,
        carbGrams: nutriments?.carbs ?? 0,
        fatGrams: nutriments?.fat ?? 0
      ),
      defaultGrams: 100,
      shelfAsset: nil
    )
  }
}

private struct SearchEnvelope: Decodable {
  var products: [RemoteProduct]
}

private struct ProductEnvelope: Decodable {
  var status: Int?
  var product: RemoteProduct?
}

private struct RemoteProduct: Decodable {
  var code: String?
  var productName: String?
  var brands: String?
  var nutriments: RemoteNutriments?

  enum CodingKeys: String, CodingKey {
    case code
    case productName = "product_name"
    case brands
    case nutriments
  }
}

private struct RemoteNutriments: Decodable {
  var energyKcal: Double?
  var energyKj: Double?
  var proteins: Double?
  var carbs: Double?
  var fat: Double?

  init(from decoder: Decoder) throws {
    let bag = try decoder.singleValueContainer().decode([String: FlexibleScalar].self)
    energyKcal = bag["energy-kcal_100g"]?.doubleValue ?? bag["energy-kcal"]?.doubleValue
    energyKj = bag["energy_100g"]?.doubleValue
    proteins = bag["proteins_100g"]?.doubleValue
    carbs = bag["carbohydrates_100g"]?.doubleValue
    fat = bag["fat_100g"]?.doubleValue
  }
}

private enum FlexibleScalar: Decodable {
  case number(Double)
  case text(String)

  var doubleValue: Double? {
    switch self {
    case .number(let value): value
    case .text(let text): Double(text)
    }
  }

  init(from decoder: Decoder) throws {
    let box = try decoder.singleValueContainer()
    if let value = try? box.decode(Double.self) {
      self = .number(value)
    } else if let value = try? box.decode(Int.self) {
      self = .number(Double(value))
    } else if let value = try? box.decode(String.self) {
      self = .text(value)
    } else {
      self = .number(0)
    }
  }
}
