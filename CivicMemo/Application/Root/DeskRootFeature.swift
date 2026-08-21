import ComposableArchitecture
import SwiftUI

// Architecture: The Composable Architecture is the composition root because CivicMemo
// is a graph of desk features (lookup, capture, brief, assign, seats) that must share
// one household snapshot, push/pop a single NavigationStack, and stay testable without
// a view layer. Reducers own mutations; SeatFileArchive is a TCA dependency so each
// household seat writes its own JSON file. SwiftUI renders; UIKit enters only through
// UIViewRepresentable for the Vision barcode canvas and the portion UISlider.

@Reducer
enum DeskPath {
  case catalogLookup(CatalogLookupFeature)
  case barcodeCapture(BarcodeCaptureFeature)
  case articleBrief(ArticleBriefFeature)
  case slotAssign(SlotAssignFeature)
  case eatenRoster(EatenRosterFeature)
  case wishBoard(WishBoardFeature)
  case quotaEditor(QuotaEditorFeature)
  case deskPlan(DeskPlanFeature)
  case seatRoster(SeatRosterFeature)
}

@Reducer
struct DeskRootFeature {
  @ObservableState
  struct State: Equatable {
    var briefing: BriefingFeature.State?
    var desk: DeskTodayFeature.State?
    var roster: HouseholdRoster?
    var path = StackState<DeskPath.State>()

    static func == (lhs: State, rhs: State) -> Bool {
      lhs.briefing == rhs.briefing
        && lhs.desk == rhs.desk
        && lhs.roster == rhs.roster
        && lhs.path.ids == rhs.path.ids
    }
  }

  enum Action {
    case appear
    case showBriefing
    case hydrate(HouseholdRoster, SeatSnapshot)
    case briefing(BriefingFeature.Action)
    case desk(DeskTodayFeature.Action)
    case path(StackActionOf<DeskPath>)
  }

  @Dependency(\.seatFileArchive) var seatFileArchive
  @Dependency(\.date.now) var now
  @Dependency(\.calendar) var calendar
  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    Reduce(core)
      .ifLet(\.briefing, action: \.briefing) {
        BriefingFeature()
      }
      .ifLet(\.desk, action: \.desk) {
        DeskTodayFeature()
      }
      .forEach(\.path, action: \.path)
  }

  private func core(_ state: inout State, _ action: Action) -> Effect<Action> {
    switch action {
    case .appear:
      return .run { [seatFileArchive, uuid, now, calendar] send in
        do {
          let roster = try seatFileArchive.loadRoster()
          if roster.briefingCompleted, let active = roster.activeSeat {
            var snap = try seatFileArchive.loadSnapshot(active.id)
            #if targetEnvironment(simulator)
            let today = DayStamp.from(now, calendar: calendar)
            if snap.ledger.rows(kind: .consumed, day: today).isEmpty {
              snap = CivicDemoSeed.planted(seat: active, today: today, calendar: calendar, makeID: { uuid() })
              try? seatFileArchive.saveSnapshot(snap)
            }
            #endif
            await send(.hydrate(roster, snap))
          } else {
            await send(.showBriefing)
          }
        } catch {
          await send(.showBriefing)
        }
      }

    case .showBriefing:
      state.briefing = BriefingFeature.State()
      state.desk = nil
      return .none

    case let .hydrate(roster, snap):
      state.roster = roster
      state.briefing = nil
      state.path.removeAll()
      let day = DayStamp.from(now, calendar: calendar)
      state.desk = DeskTodayFeature.State(
        snapshot: snap,
        day: day,
        memoText: DayMemoComposer.text(snapshot: snap, day: day, calendar: calendar)
      )
      return .none

    case .briefing(.delegate(.finished)):
      return openHousehold()

    case .briefing:
      return .none

    case .desk(.openLookup):
      state.path.append(.catalogLookup(CatalogLookupFeature.State()))
      return .none
    case .desk(.openCapture):
      state.path.append(.barcodeCapture(BarcodeCaptureFeature.State()))
      return .none
    case .desk(.openEaten):
      state.path.append(.eatenRoster(EatenRosterFeature.State(records: state.desk?.consumed ?? [])))
      return .none
    case .desk(.openWish):
      state.path.append(.wishBoard(WishBoardFeature.State(wishes: state.desk?.snapshot.wishes ?? [])))
      return .none
    case .desk(.openQuota):
      state.path.append(.quotaEditor(QuotaEditorFeature.State(quota: state.desk?.snapshot.quota ?? .civicDefault)))
      return .none
    case .desk(.openPlan):
      let day = state.desk?.day ?? DayStamp.from(now, calendar: calendar)
      state.path.append(.deskPlan(DeskPlanFeature.State(
        today: day,
        selected: day,
        records: state.desk?.snapshot.records ?? []
      )))
      return .none
    case .desk(.openSeats):
      if let roster = state.roster {
        state.path.append(.seatRoster(SeatRosterFeature.State(roster: roster)))
      }
      return .none
    case .desk:
      return .none

    case let .path(.element(id: _, action: .catalogLookup(.delegate(.picked(article))))):
      state.path.append(.articleBrief(ArticleBriefFeature.State(article: article, grams: article.defaultGrams)))
      return .none

    case let .path(.element(id: _, action: .barcodeCapture(.delegate(.resolved(article))))):
      state.path.append(.articleBrief(ArticleBriefFeature.State(article: article, grams: article.defaultGrams)))
      return .none

    case let .path(.element(id: _, action: .articleBrief(.delegate(.continueAssign(article, grams))))):
      let today = state.desk?.day ?? DayStamp.from(now, calendar: calendar)
      state.path.append(.slotAssign(SlotAssignFeature.State(article: article, grams: grams, today: today)))
      return .none

    case let .path(.element(id: _, action: .articleBrief(.delegate(.pinWish(article))))):
      return .send(.desk(.applyWish(article)))

    case let .path(.element(id: _, action: .slotAssign(.delegate(.committed(record))))):
      var planned = state.desk?.snapshot.records ?? []
      planned.append(record)
      state.path.removeAll()
      if record.kind == .scheduled, let desk = state.desk {
        state.path.append(.deskPlan(DeskPlanFeature.State(
          today: desk.day,
          selected: record.day,
          records: planned
        )))
      }
      return .send(.desk(.applyCommit(record)))

    case let .path(.element(id: _, action: .eatenRoster(.delegate(.delete(recordID))))):
      return .send(.desk(.deleteRecord(recordID)))

    case let .path(.element(id: _, action: .wishBoard(.delegate(.unpin(sku))))):
      return .send(.desk(.unpinWish(sku)))

    case let .path(.element(id: _, action: .wishBoard(.delegate(.picked(article))))):
      state.path.append(.articleBrief(ArticleBriefFeature.State(article: article, grams: article.defaultGrams)))
      return .none

    case let .path(.element(id: _, action: .quotaEditor(.delegate(.saved(quota))))):
      state.path.removeAll()
      return .send(.desk(.replaceQuota(quota)))

    case let .path(.element(id: _, action: .deskPlan(.delegate(.delete(id))))):
      return .send(.desk(.deleteRecord(id)))

    case let .path(.element(id: _, action: .seatRoster(.delegate(.switched(seatID))))):
      var roster = state.roster
      roster?.activeSeatID = seatID
      state.roster = roster
      let frozen = roster
      return .run { [seatFileArchive] send in
        guard let frozen else { return }
        try? seatFileArchive.saveRoster(frozen)
        guard let snap = try? seatFileArchive.loadSnapshot(seatID) else { return }
        await send(.hydrate(frozen, snap))
      }

    case let .path(.element(id: _, action: .seatRoster(.delegate(.rosterChanged(roster))))):
      state.roster = roster
      return .run { [seatFileArchive] _ in
        try? seatFileArchive.saveRoster(roster)
        for seat in roster.seats {
          if (try? seatFileArchive.loadSnapshot(seat.id)) == nil {
            try? seatFileArchive.saveSnapshot(
              SeatSnapshot(seat: seat, quota: .civicDefault, records: [], wishes: [])
            )
          }
        }
      }

    case .path:
      return .none
    }
  }

  private func openHousehold() -> Effect<Action> {
    .run { [seatFileArchive, uuid, now, calendar] send in
      let north = HouseholdSeat(id: uuid(), deskLabel: "Desk North", initials: "DN")
      let south = HouseholdSeat(id: uuid(), deskLabel: "Desk South", initials: "DS")
      let roster = HouseholdRoster(
        seats: [north, south],
        activeSeatID: north.id,
        briefingCompleted: true,
        demoPlanted: true
      )
      let today = DayStamp.from(now, calendar: calendar)
      let planted = CivicDemoSeed.planted(seat: north, today: today, calendar: calendar, makeID: { uuid() })
      let vacant = SeatSnapshot(seat: south, quota: .civicDefault, records: [], wishes: [])
      try? seatFileArchive.saveRoster(roster)
      try? seatFileArchive.saveSnapshot(planted)
      try? seatFileArchive.saveSnapshot(vacant)
      await send(.hydrate(roster, planted))
    }
  }
}
