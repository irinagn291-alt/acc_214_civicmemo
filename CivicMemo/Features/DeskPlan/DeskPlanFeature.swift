import ComposableArchitecture
import SwiftUI

@Reducer
struct DeskPlanFeature {
  @ObservableState
  struct State: Equatable {
    var today: DayStamp
    var selected: DayStamp
    var records: [IntakeRecord]
    var horizon = 14

  }

  enum Action: Equatable {
    case select(DayStamp)
    case delete(UUID)
    case delegate(Delegate)
    enum Delegate: Equatable {
      case delete(UUID)
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .select(day):
        state.selected = day
        return .none
      case let .delete(id):
        state.records.removeAll { $0.id == id }
        return .send(.delegate(.delete(id)))
      case .delegate:
        return .none
      }
    }
  }
}

struct DeskPlanView: View {
  let store: StoreOf<DeskPlanFeature>
  @Dependency(\.calendar) var calendar

  var body: some View {
    ZStack {
      CivicBlotter()
      VStack(alignment: .leading, spacing: 12) {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(planDays, id: \.self) { day in
              Button {
                store.send(.select(day))
              } label: {
                VStack(spacing: 4) {
                  Text(short(day))
                    .font(CivicType.medium(12))
                  Text("\(Int(energy(day).rounded()))")
                    .font(CivicType.semibold(12))
                }
                .foregroundStyle(store.selected == day ? .white : CivicPalette.navy)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(store.selected == day ? CivicPalette.navy : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
              .buttonStyle(.plain)
            }
          }
        }
        let rows = plannedRows(on: store.selected)
        if rows.isEmpty {
          CivicEmptyBoard(
            image: "EmptyDesk",
            title: "No planned lines",
            note: "Assign a commodity as Plan — Break is consumed only."
          )
        } else {
          ScrollView {
            VStack(spacing: 10) {
              ForEach(rows) { row in
                CivicCard {
                  HStack {
                    Image(row.slot.artName)
                      .resizable()
                      .scaledToFit()
                      .frame(width: 40, height: 40)
                    VStack(alignment: .leading) {
                      Text(row.article.displayName)
                        .font(CivicType.semibold(14))
                      Text("\(row.slot.deskTitle) · \(Int(row.grams)) g")
                        .font(CivicType.regular(12))
                        .foregroundStyle(CivicPalette.slate)
                    }
                    Spacer()
                    Button("Drop") { store.send(.delete(row.id)) }
                      .font(CivicType.medium(12))
                      .foregroundStyle(CivicPalette.slate)
                  }
                }
              }
            }
          }
        }
        Spacer()
      }
      .padding(16)
    }
    .navigationTitle("14-day plan")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var planDays: [DayStamp] {
    (0..<store.horizon).map { store.today.shifting(days: $0, calendar: calendar) }
  }

  private func plannedRows(on day: DayStamp) -> [IntakeRecord] {
    store.records.filter { $0.kind == .scheduled && $0.day == day }
  }

  private func short(_ day: DayStamp) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.dateFormat = "d MMM"
    return formatter.string(from: day.dateValue(calendar: calendar))
  }

  private func energy(_ day: DayStamp) -> Double {
    plannedRows(on: day).map(\.portionBundle.energyKcal).reduce(0, +)
  }
}
