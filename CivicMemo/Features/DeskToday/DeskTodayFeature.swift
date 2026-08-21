import ComposableArchitecture
import SwiftUI

@Reducer
struct DeskTodayFeature {
  @ObservableState
  struct State: Equatable {
    var snapshot: SeatSnapshot
    var day: DayStamp
    var memoText: String = ""

    var consumed: [IntakeRecord] {
      snapshot.records.filter { $0.kind == .consumed && $0.day == day }
    }

    var totals: MacroBundle {
      snapshot.consumedBundle(on: day)
    }
  }

  enum Action: Equatable {
    case appear
    case openLookup
    case openCapture
    case openEaten
    case openWish
    case openQuota
    case openPlan
    case openSeats
    case applyCommit(IntakeRecord)
    case deleteRecord(UUID)
    case applyWish(CatalogArticle)
    case unpinWish(String)
    case replaceQuota(NutritionQuota)
    case replaceSnapshot(SeatSnapshot)
  }

  @Dependency(\.seatFileArchive) var seatFileArchive
  @Dependency(\.calendar) var calendar

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .appear:
        state.memoText = DayMemoComposer.text(snapshot: state.snapshot, day: state.day, calendar: calendar)
        return .none
      case .openLookup, .openCapture, .openEaten, .openWish, .openQuota, .openPlan, .openSeats:
        return .none
      case let .applyCommit(record):
        state.snapshot.append(record)
        return write(&state)
      case let .deleteRecord(id):
        state.snapshot.removeRecord(id)
        return write(&state)
      case let .applyWish(article):
        _ = state.snapshot.pinWish(article)
        return write(&state)
      case let .unpinWish(sku):
        state.snapshot.unpinWish(sku)
        return write(&state)
      case let .replaceQuota(quota):
        state.snapshot.quota = quota
        return write(&state)
      case let .replaceSnapshot(snapshot):
        state.snapshot = snapshot
        state.memoText = DayMemoComposer.text(snapshot: snapshot, day: state.day, calendar: calendar)
        return .none
      }
    }
  }

  private func write(_ state: inout State) -> Effect<Action> {
    state.memoText = DayMemoComposer.text(snapshot: state.snapshot, day: state.day, calendar: calendar)
    let snapshot = state.snapshot
    return .run { _ in
      try? seatFileArchive.saveSnapshot(snapshot)
    }
  }
}

struct DeskTodayView: View {
  let store: StoreOf<DeskTodayFeature>

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          header
          meters
          slotStrip
          actions
          if store.consumed.isEmpty {
            CivicEmptyBoard(
              image: "EmptyDesk",
              title: "Desk is clear",
              note: "Look up a commodity or scan a carton to write the first line."
            )
          } else {
            ForEach(store.consumed) { row in
              recordCard(row)
            }
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("Today")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          store.send(.openSeats)
        } label: {
          Text(store.snapshot.seat.initials)
            .font(CivicType.semibold(12))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(CivicPalette.navy)
            .clipShape(Circle())
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        ShareLink(item: store.memoText) {
          Text("Share")
            .font(CivicType.medium(14))
            .foregroundStyle(CivicPalette.blue)
        }
      }
    }
    .onAppear { store.send(.appear) }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 12) {
      Image("Splash")
        .resizable()
        .scaledToFill()
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
      VStack(alignment: .leading, spacing: 4) {
        Text(store.snapshot.seat.deskLabel)
          .font(CivicType.bold(20))
          .foregroundStyle(CivicPalette.navy)
        Text("Household memo · local seats")
          .font(CivicType.regular(13))
          .foregroundStyle(CivicPalette.slate)
      }
      Spacer()
    }
  }

  private var meters: some View {
    CivicCard {
      VStack(spacing: 12) {
        QuotaMeter(title: "Energy", value: store.totals.energyKcal, cap: store.snapshot.quota.energyKcal, unit: "kcal")
        QuotaMeter(title: "Protein", value: store.totals.proteinGrams, cap: store.snapshot.quota.proteinGrams, unit: "g")
        QuotaMeter(title: "Carbs", value: store.totals.carbGrams, cap: store.snapshot.quota.carbGrams, unit: "g")
        QuotaMeter(title: "Fat", value: store.totals.fatGrams, cap: store.snapshot.quota.fatGrams, unit: "g")
      }
    }
  }

  private var slotStrip: some View {
    HStack(spacing: 8) {
      ForEach(DeskSlot.allCases, id: \.self) { slot in
        VStack(spacing: 6) {
          Image(slot.artName)
            .resizable()
            .scaledToFit()
            .frame(height: 52)
          Text(slot.deskTitle)
            .font(CivicType.medium(10))
            .foregroundStyle(CivicPalette.navy)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
      }
    }
  }

  private var actions: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        CivicPrimaryButton(title: "Lookup") { store.send(.openLookup) }
        Button {
          store.send(.openCapture)
        } label: {
          Text("Scan")
            .font(CivicType.semibold(16))
            .foregroundStyle(CivicPalette.navy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(CivicPalette.navy, lineWidth: 1))
        }
        .buttonStyle(.plain)
      }
      HStack(spacing: 10) {
        navChip("Eaten") { store.send(.openEaten) }
        navChip("Wish") { store.send(.openWish) }
        navChip("Goals") { store.send(.openQuota) }
        navChip("Plan") { store.send(.openPlan) }
      }
    }
  }

  private func navChip(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(CivicType.medium(13))
        .foregroundStyle(CivicPalette.navy)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(CivicPalette.fog)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
  }

  private func recordCard(_ row: IntakeRecord) -> some View {
    CivicCard {
      HStack(alignment: .top, spacing: 12) {
        Image(row.slot.artName)
          .resizable()
          .scaledToFit()
          .frame(width: 44, height: 44)
        VStack(alignment: .leading, spacing: 4) {
          Text(row.article.displayName)
            .font(CivicType.semibold(15))
            .foregroundStyle(CivicPalette.ink)
          Text("\(row.slot.deskTitle) · \(Int(row.grams)) g · \(Int(row.portionBundle.energyKcal.rounded())) kcal")
            .font(CivicType.regular(12))
            .foregroundStyle(CivicPalette.slate)
        }
        Spacer()
        Button {
          store.send(.deleteRecord(row.id))
        } label: {
          Text("Drop")
            .font(CivicType.medium(12))
            .foregroundStyle(CivicPalette.navy)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(CivicPalette.fog)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
      }
    }
  }
}
