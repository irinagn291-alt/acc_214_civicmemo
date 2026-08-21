import Foundation

struct SeatFileArchive: Sendable {
  var loadRoster: @Sendable () throws -> HouseholdRoster
  var saveRoster: @Sendable (HouseholdRoster) throws -> Void
  var loadSnapshot: @Sendable (_ seatID: UUID) throws -> SeatSnapshot
  var saveSnapshot: @Sendable (SeatSnapshot) throws -> Void
}

extension SeatFileArchive {
  static let disk = SeatFileArchive(
    loadRoster: { try SeatDiskIO.loadRoster() },
    saveRoster: { try SeatDiskIO.saveRoster($0) },
    loadSnapshot: { try SeatDiskIO.loadSnapshot($0) },
    saveSnapshot: { try SeatDiskIO.saveSnapshot($0) }
  )

  static var memoryPreview: SeatFileArchive {
    let box = SeatMemoryBox()
    return SeatFileArchive(
      loadRoster: { try box.loadRoster() },
      saveRoster: { try box.saveRoster($0) },
      loadSnapshot: { try box.loadSnapshot($0) },
      saveSnapshot: { try box.saveSnapshot($0) }
    )
  }
}

private struct FileBox: @unchecked Sendable {
  let manager: FileManager
  static let shared = FileBox(manager: .default)
}

private enum SeatDiskIO {
  static func folder() throws -> URL {
    let url = URL.documentsDirectory.appending(path: "CivicMemoSeats", directoryHint: .isDirectory)
    try FileBox.shared.manager.createDirectory(at: url, withIntermediateDirectories: true)
    return url
  }

  static func rosterURL() throws -> URL {
    try folder().appending(path: "roster.json")
  }

  static func snapshotURL(_ id: UUID) throws -> URL {
    try folder().appending(path: "\(id.uuidString).json")
  }

  static func loadRoster() throws -> HouseholdRoster {
    let data = try Data(contentsOf: rosterURL())
    return try JSONDecoder().decode(HouseholdRoster.self, from: data)
  }

  static func saveRoster(_ roster: HouseholdRoster) throws {
    try write(roster, to: rosterURL())
  }

  static func loadSnapshot(_ id: UUID) throws -> SeatSnapshot {
    let data = try Data(contentsOf: snapshotURL(id))
    return try JSONDecoder().decode(SeatSnapshot.self, from: data)
  }

  static func saveSnapshot(_ snapshot: SeatSnapshot) throws {
    try write(snapshot, to: snapshotURL(snapshot.seat.id))
  }

  static func write<T: Encodable>(_ value: T, to url: URL) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(value)
    try data.write(to: url, options: .atomic)
  }
}

final class SeatMemoryBox: @unchecked Sendable {
  private let lock = NSLock()
  private var roster: HouseholdRoster?
  private var snapshots: [UUID: SeatSnapshot] = [:]

  func loadRoster() throws -> HouseholdRoster {
    lock.lock(); defer { lock.unlock() }
    guard let roster else { throw CatalogFault(message: "No roster on this desk.") }
    return roster
  }

  func saveRoster(_ value: HouseholdRoster) throws {
    lock.lock(); defer { lock.unlock() }
    roster = value
  }

  func loadSnapshot(_ id: UUID) throws -> SeatSnapshot {
    lock.lock(); defer { lock.unlock() }
    guard let snapshot = snapshots[id] else { throw CatalogFault(message: "No seat file.") }
    return snapshot
  }

  func saveSnapshot(_ value: SeatSnapshot) throws {
    lock.lock(); defer { lock.unlock() }
    snapshots[value.seat.id] = value
  }
}
