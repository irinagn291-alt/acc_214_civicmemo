import ComposableArchitecture
import SwiftUI

@Reducer
struct SeatRosterFeature {
  @ObservableState
  struct State: Equatable {
    var roster: HouseholdRoster
    var notice: String?
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case activate(UUID)
    case addSeat
    case dropSeat(UUID)
    case rename(UUID, String)
    case delegate(Delegate)
    enum Delegate: Equatable {
      case switched(UUID)
      case rosterChanged(HouseholdRoster)
    }
  }

  @Dependency(\.uuid) var uuid

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .activate(id):
        guard state.roster.seats.contains(where: { $0.id == id }) else { return .none }
        state.roster.activeSeatID = id
        return .send(.delegate(.switched(id)))
      case .addSeat:
        guard state.roster.seats.count < 4 else {
          state.notice = "Four seats is the household ceiling."
          return .none
        }
        let labels = ["Desk North", "Desk South", "Desk East", "Desk West"]
        let initials = ["DN", "DS", "DE", "DW"]
        let index = state.roster.seats.count
        let seat = HouseholdSeat(id: uuid(), deskLabel: labels[index], initials: initials[index])
        state.roster.seats.append(seat)
        state.notice = nil
        return .send(.delegate(.rosterChanged(state.roster)))
      case let .dropSeat(id):
        guard state.roster.seats.count > 2 else {
          state.notice = "Two seats stay on the household desk."
          return .none
        }
        state.roster.seats.removeAll { $0.id == id }
        if state.roster.activeSeatID == id {
          state.roster.activeSeatID = state.roster.seats[0].id
          return .merge(
            .send(.delegate(.rosterChanged(state.roster))),
            .send(.delegate(.switched(state.roster.activeSeatID)))
          )
        }
        return .send(.delegate(.rosterChanged(state.roster)))
      case let .rename(id, label):
        if let index = state.roster.seats.firstIndex(where: { $0.id == id }) {
          state.roster.seats[index].deskLabel = label
          let trimmed = label.trimmingCharacters(in: .whitespaces)
          state.roster.seats[index].initials = String(trimmed.prefix(2)).uppercased()
        }
        return .send(.delegate(.rosterChanged(state.roster)))
      case .delegate:
        return .none
      }
    }
  }
}

struct SeatRosterView: View {
  @Bindable var store: StoreOf<SeatRosterFeature>

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text("2–4 local seats. Each desk has its own file.")
            .font(CivicType.regular(13))
            .foregroundStyle(CivicPalette.slate)
          if let notice = store.notice {
            Text(notice)
              .font(CivicType.regular(13))
              .foregroundStyle(CivicPalette.navy)
          }
          ForEach(store.roster.seats) { seat in
            CivicCard {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(seat.deskLabel)
                    .font(CivicType.semibold(15))
                  Text(seat.initials)
                    .font(CivicType.regular(12))
                    .foregroundStyle(CivicPalette.slate)
                }
                Spacer()
                if store.roster.activeSeatID == seat.id {
                  CivicChip(title: "Active", selected: true)
                } else {
                  Button("Sit") { store.send(.activate(seat.id)) }
                    .font(CivicType.medium(13))
                    .foregroundStyle(CivicPalette.blue)
                }
                if store.roster.seats.count > 2 {
                  Button("Drop") { store.send(.dropSeat(seat.id)) }
                    .font(CivicType.medium(13))
                    .foregroundStyle(CivicPalette.slate)
                }
              }
            }
          }
          CivicPrimaryButton(title: "Add seat") {
            store.send(.addSeat)
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("Seats")
    .navigationBarTitleDisplayMode(.inline)
  }
}
