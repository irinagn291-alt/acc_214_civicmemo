import SwiftUI

enum CivicPalette {
  static let navy = Color(red: 0.106, green: 0.227, blue: 0.420)
  static let blue = Color(red: 0.184, green: 0.435, blue: 0.929)
  static let ice = Color(red: 0.957, green: 0.969, blue: 0.984)
  static let fog = Color(red: 0.902, green: 0.922, blue: 0.949)
  static let slate = Color(red: 0.357, green: 0.404, blue: 0.459)
  static let ink = Color(red: 0.102, green: 0.137, blue: 0.188)
}

enum CivicType {
  static func regular(_ size: CGFloat) -> Font { .custom("Montserrat-Regular", size: size) }
  static func medium(_ size: CGFloat) -> Font { .custom("Montserrat-Medium", size: size) }
  static func semibold(_ size: CGFloat) -> Font { .custom("Montserrat-SemiBold", size: size) }
  static func bold(_ size: CGFloat) -> Font { .custom("Montserrat-Bold", size: size) }
}
