import Foundation

enum DeskSlot: String, Codable, CaseIterable, Sendable, Hashable {
  case amDesk
  case midday
  case pmDesk
  case breakSlot

  var deskTitle: String {
    switch self {
    case .amDesk: "AM Desk"
    case .midday: "Midday"
    case .pmDesk: "PM Desk"
    case .breakSlot: "Break"
    }
  }

  var isPlanEligible: Bool { self != .breakSlot }

  var artName: String {
    switch self {
    case .amDesk: "SlotAmDesk"
    case .midday: "SlotMidday"
    case .pmDesk: "SlotPmDesk"
    case .breakSlot: "SlotBreak"
    }
  }

  static var planable: [DeskSlot] { allCases.filter(\.isPlanEligible) }
}
