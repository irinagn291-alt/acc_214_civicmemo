import SwiftUI

enum DeskRoute: Hashable {
  case catalogLookup
  case barcodeCapture
  case articleBrief
  case slotAssign
  case eatenRoster
  case wishBoard
  case quotaEditor
  case deskPlan
  case seatRoster
}

@MainActor
@Observable
final class DeskRootFeature {
  var briefing: BriefingFeature?
  var desk: DeskTodayFeature?
  var roster: HouseholdRoster?
  var path: [DeskRoute] = []

  var lookup: CatalogLookupFeature
  var capture: BarcodeCaptureFeature
  var brief: ArticleBriefFeature?
  var assign: SlotAssignFeature?
  var eaten: EatenRosterFeature?
  var wish: WishBoardFeature?
  var quota: QuotaEditorFeature?
  var plan: DeskPlanFeature?
  var seats: SeatRosterFeature?

  private let archive: SeatFileArchive
  private let catalog: CatalogGateway
  private let calendar: Calendar
  private let makeID: () -> UUID
  private let now: () -> Date

  init(
    archive: SeatFileArchive = .disk,
    catalog: CatalogGateway = .worldOffice,
    calendar: Calendar = .current,
    makeID: @escaping () -> UUID = { UUID() },
    now: @escaping () -> Date = Date.init
  ) {
    self.archive = archive
    self.catalog = catalog
    self.calendar = calendar
    self.makeID = makeID
    self.now = now
    lookup = CatalogLookupFeature(catalog: catalog)
    capture = BarcodeCaptureFeature(catalog: catalog)
    wireCatalog()
  }

  func appear() {
    Task { await boot() }
  }

  private func wireCatalog() {
    lookup.onPicked = { [weak self] article in
      self?.openBrief(article, grams: article.defaultGrams)
    }
    capture.onResolved = { [weak self] article in
      self?.openBrief(article, grams: article.defaultGrams)
    }
  }

  private func bindDesk(_ board: DeskTodayFeature) {
    board.onOpenLookup = { [weak self] in self?.openLookup() }
    board.onOpenCapture = { [weak self] in self?.openCapture() }
    board.onOpenEaten = { [weak self] in self?.openEaten() }
    board.onOpenWish = { [weak self] in self?.openWish() }
    board.onOpenQuota = { [weak self] in self?.openQuota() }
    board.onOpenPlan = { [weak self] in self?.openPlan() }
    board.onOpenSeats = { [weak self] in self?.openSeats() }
  }

  private func boot() async {
    do {
      let roster = try archive.loadRoster()
      if roster.briefingCompleted, let active = roster.activeSeat {
        var snap = try archive.loadSnapshot(active.id)
        #if targetEnvironment(simulator)
        let today = DayStamp.from(now(), calendar: calendar)
        if snap.ledger.rows(kind: .consumed, day: today).isEmpty {
          snap = CivicDemoSeed.planted(seat: active, today: today, calendar: calendar, makeID: makeID)
          try? archive.saveSnapshot(snap)
        }
        #endif
        hydrate(roster, snap)
      } else {
        showBriefing()
      }
    } catch {
      showBriefing()
    }
  }

  private func showBriefing() {
    let board = BriefingFeature()
    board.onFinished = { [weak self] in self?.openHousehold() }
    briefing = board
    desk = nil
  }

  private func hydrate(_ roster: HouseholdRoster, _ snap: SeatSnapshot) {
    self.roster = roster
    briefing = nil
    path.removeAll()
    let day = DayStamp.from(now(), calendar: calendar)
    let today = DeskTodayFeature(snapshot: snap, day: day, archive: archive, calendar: calendar)
    bindDesk(today)
    desk = today
  }

  private func openHousehold() {
    let north = HouseholdSeat(id: makeID(), deskLabel: "Desk North", initials: "DN")
    let south = HouseholdSeat(id: makeID(), deskLabel: "Desk South", initials: "DS")
    let roster = HouseholdRoster(
      seats: [north, south],
      activeSeatID: north.id,
      briefingCompleted: true,
      demoPlanted: true
    )
    let today = DayStamp.from(now(), calendar: calendar)
    let planted = CivicDemoSeed.planted(seat: north, today: today, calendar: calendar, makeID: makeID)
    let vacant = SeatSnapshot(seat: south, quota: .civicDefault, records: [], wishes: [])
    try? archive.saveRoster(roster)
    try? archive.saveSnapshot(planted)
    try? archive.saveSnapshot(vacant)
    hydrate(roster, planted)
  }

  private func openLookup() {
    lookup = CatalogLookupFeature(catalog: catalog)
    wireCatalog()
    path.append(.catalogLookup)
  }

  private func openCapture() {
    capture = BarcodeCaptureFeature(catalog: catalog)
    wireCatalog()
    path.append(.barcodeCapture)
  }

  private func openBrief(_ article: CatalogArticle, grams: Double) {
    let board = ArticleBriefFeature(article: article, grams: grams)
    board.onContinue = { [weak self] article, grams in
      self?.openAssign(article, grams: grams)
    }
    board.onPinWish = { [weak self] article in
      self?.desk?.applyWish(article)
    }
    brief = board
    path.append(.articleBrief)
  }

  private func openAssign(_ article: CatalogArticle, grams: Double) {
    let today = desk?.day ?? DayStamp.from(now(), calendar: calendar)
    let board = SlotAssignFeature(article: article, grams: grams, today: today, makeID: makeID)
    board.onCommitted = { [weak self] record in
      self?.commit(record)
    }
    assign = board
    path.append(.slotAssign)
  }

  private func commit(_ record: IntakeRecord) {
    var planned = desk?.snapshot.records ?? []
    planned.append(record)
    path.removeAll()
    if record.kind == .scheduled, let desk {
      openPlan(selected: record.day, records: planned)
    }
    desk?.applyCommit(record)
  }

  private func openEaten() {
    let board = EatenRosterFeature(records: desk?.consumed ?? [])
    board.onDelete = { [weak self] id in self?.desk?.deleteRecord(id) }
    eaten = board
    path.append(.eatenRoster)
  }

  private func openWish() {
    let board = WishBoardFeature(wishes: desk?.snapshot.wishes ?? [])
    board.onUnpin = { [weak self] sku in self?.desk?.unpinWish(sku) }
    board.onPicked = { [weak self] article in
      self?.openBrief(article, grams: article.defaultGrams)
    }
    wish = board
    path.append(.wishBoard)
  }

  private func openQuota() {
    let board = QuotaEditorFeature(quota: desk?.snapshot.quota ?? .civicDefault)
    board.onSaved = { [weak self] quota in
      self?.path.removeAll()
      self?.desk?.replaceQuota(quota)
    }
    quota = board
    path.append(.quotaEditor)
  }

  private func openPlan(selected: DayStamp? = nil, records: [IntakeRecord]? = nil) {
    let day = desk?.day ?? DayStamp.from(now(), calendar: calendar)
    let board = DeskPlanFeature(
      today: day,
      selected: selected ?? day,
      records: records ?? desk?.snapshot.records ?? []
    )
    board.onDelete = { [weak self] id in self?.desk?.deleteRecord(id) }
    plan = board
    path.append(.deskPlan)
  }

  private func openSeats() {
    guard let roster else { return }
    let board = SeatRosterFeature(roster: roster, makeID: makeID)
    board.onSwitched = { [weak self] seatID in
      self?.switchSeat(seatID)
    }
    board.onRosterChanged = { [weak self] roster in
      self?.rosterChanged(roster)
    }
    seats = board
    path.append(.seatRoster)
  }

  private func switchSeat(_ seatID: UUID) {
    var roster = roster
    roster?.activeSeatID = seatID
    self.roster = roster
    guard let roster else { return }
    try? archive.saveRoster(roster)
    guard let snap = try? archive.loadSnapshot(seatID) else { return }
    hydrate(roster, snap)
  }

  private func rosterChanged(_ roster: HouseholdRoster) {
    self.roster = roster
    try? archive.saveRoster(roster)
    for seat in roster.seats {
      if (try? archive.loadSnapshot(seat.id)) == nil {
        try? archive.saveSnapshot(
          SeatSnapshot(seat: seat, quota: .civicDefault, records: [], wishes: [])
        )
      }
    }
  }
}
