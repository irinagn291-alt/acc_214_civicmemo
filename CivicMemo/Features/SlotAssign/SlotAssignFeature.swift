import ComposableArchitecture
import SwiftUI

@Reducer
struct SlotAssignFeature {
  @ObservableState
  struct State: Equatable {
    var article: CatalogArticle
    var grams: Double
    var today: DayStamp
    var slot: DeskSlot = .amDesk
    var kind: LedgerKind = .consumed
    var planDay: DayStamp
    var notice: String?

    init(article: CatalogArticle, grams: Double, today: DayStamp) {
      self.article = article
      self.grams = grams
      self.today = today
      self.planDay = today
    }
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case pickSlot(DeskSlot)
    case pickKind(LedgerKind)
    case confirm
    case delegate(Delegate)
    enum Delegate: Equatable {
      case committed(IntakeRecord)
    }
  }

  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .pickSlot(slot):
        state.slot = slot
        if slot == .breakSlot, state.kind == .scheduled {
          state.kind = .consumed
          state.notice = "Break stays on the consumed desk only."
        }
        return .none
      case let .pickKind(kind):
        if kind == .scheduled, state.slot == .breakSlot {
          state.notice = "Break cannot be planned. Pick AM Desk, Midday, or PM Desk."
          return .none
        }
        state.kind = kind
        state.notice = nil
        return .none
      case .confirm:
        if state.kind == .scheduled, !state.slot.isPlanEligible {
          state.notice = "Break cannot be planned."
          return .none
        }
        let day = state.kind == .consumed ? state.today : state.planDay
        let record = IntakeRecord(
          id: uuid(),
          article: state.article,
          grams: state.grams,
          slot: state.slot,
          day: day,
          kind: state.kind
        )
        return .send(.delegate(.committed(record)))
      case .delegate:
        return .none
      }
    }
  }
}

struct SlotAssignView: View {
  @Bindable var store: StoreOf<SlotAssignFeature>
  @Dependency(\.calendar) var calendar

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text(store.article.displayName)
            .font(CivicType.bold(20))
            .foregroundStyle(CivicPalette.navy)
          Text("\(Int(store.grams)) g")
            .font(CivicType.regular(14))
            .foregroundStyle(CivicPalette.slate)
          Text("Desk slot")
            .font(CivicType.semibold(13))
            .foregroundStyle(CivicPalette.navy)
          HStack(spacing: 8) {
            ForEach(DeskSlot.allCases, id: \.self) { slot in
              Button {
                store.send(.pickSlot(slot))
              } label: {
                VStack(spacing: 6) {
                  Image(slot.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                  CivicChip(title: slot.deskTitle, selected: store.slot == slot)
                }
              }
              .buttonStyle(.plain)
            }
          }
          Text("Ledger")
            .font(CivicType.semibold(13))
            .foregroundStyle(CivicPalette.navy)
          HStack {
            Button {
              store.send(.pickKind(.consumed))
            } label: {
              CivicChip(title: "Consumed", selected: store.kind == .consumed)
            }
            Button {
              store.send(.pickKind(.scheduled))
            } label: {
              CivicChip(title: "Plan", selected: store.kind == .scheduled)
            }
          }
          if store.kind == .scheduled {
            DatePicker(
              "Plan day",
              selection: Binding(
                get: { store.planDay.dateValue(calendar: calendar) },
                set: { store.planDay = DayStamp.from($0, calendar: calendar) }
              ),
              in: store.today.dateValue(calendar: calendar)...store.today.shifting(days: 13, calendar: calendar).dateValue(calendar: calendar),
              displayedComponents: .date
            )
            .font(CivicType.regular(14))
          }
          if let notice = store.notice {
            Text(notice)
              .font(CivicType.regular(13))
              .foregroundStyle(CivicPalette.slate)
          }
          CivicPrimaryButton(title: "Write memo line") {
            store.send(.confirm)
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("Assign")
    .navigationBarTitleDisplayMode(.inline)
  }
}
