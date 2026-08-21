import Foundation

enum CommodityCodePolicy {
  static func normalize(_ raw: String) -> String? {
    let candidate: String
    if raw.contains("://"), let url = URL(string: raw) {
      candidate = url.lastPathComponent
    } else {
      candidate = raw
    }
    let digits = candidate.filter(\.isNumber)
    guard (8...14).contains(digits.count) else { return nil }
    if digits.count == 12 { return "0" + digits }
    return digits
  }
}
