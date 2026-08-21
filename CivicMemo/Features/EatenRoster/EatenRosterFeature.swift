import ComposableArchitecture
import SwiftUI

@Reducer
struct EatenRosterFeature {
  @ObservableState
  struct State: Equatable {
    var records: [IntakeRecord]
  }

  enum Action: Equatable {
    case delete(UUID)
    case delegate(Delegate)
    enum Delegate: Equatable {
      case delete(UUID)
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .delete(id):
        state.records.removeAll { $0.id == id }
        return .send(.delegate(.delete(id)))
      case .delegate:
        return .none
      }
    }
  }
}

struct EatenRosterView: View {
  let store: StoreOf<EatenRosterFeature>

  var body: some View {
    ZStack {
      CivicBlotter()
      if store.records.isEmpty {
        CivicEmptyBoard(
          image: "EmptyEaten",
          title: "Nothing consumed",
          note: "Assigned consumed lines for this day will sit here."
        )
        .padding(24)
      } else {
        List {
          ForEach(DeskSlot.allCases, id: \.self) { slot in
            let rows = store.records.filter { $0.slot == slot }
            if !rows.isEmpty {
              Section(slot.deskTitle) {
                ForEach(rows) { row in
                  HStack {
                    Image(slot.artName)
                      .resizable()
                      .scaledToFit()
                      .frame(width: 36, height: 36)
                    VStack(alignment: .leading) {
                      Text(row.article.displayName)
                        .font(CivicType.semibold(14))
                      Text("\(Int(row.grams)) g · \(Int(row.portionBundle.energyKcal.rounded())) kcal")
                        .font(CivicType.regular(12))
                        .foregroundStyle(CivicPalette.slate)
                    }
                  }
                  .swipeActions {
                    Button(role: .destructive) {
                      store.send(.delete(row.id))
                    } label: {
                      Text("Drop")
                    }
                  }
                }
              }
            }
          }
        }
        .scrollContentBackground(.hidden)
      }
    }
    .navigationTitle("Eaten")
    .navigationBarTitleDisplayMode(.inline)
  }
}
