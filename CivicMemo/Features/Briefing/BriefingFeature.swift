import ComposableArchitecture
import SwiftUI

@Reducer
struct BriefingFeature {
  @ObservableState
  struct State: Equatable {
    var page = 0
  }

  enum Action: Equatable {
    case pageChanged(Int)
    case nextTapped
    case finishTapped
    case delegate(Delegate)
    enum Delegate: Equatable {
      case finished
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .pageChanged(page):
        state.page = page
        return .none
      case .nextTapped:
        state.page += 1
        return .none
      case .finishTapped:
        return .send(.delegate(.finished))
      case .delegate:
        return .none
      }
    }
  }
}

struct BriefingView: View {
  @Bindable var store: StoreOf<BriefingFeature>

  private let pages: [(image: String, title: String, note: String)] = [
    ("BriefingWelcome", "Civic desk", "A quiet office memo for energy and macros. Local only — no account."),
    ("BriefingScan", "Look up or scan", "Search the civic catalog or read a carton barcode into a memo line."),
    ("BriefingSlots", "Four desk slots", "AM Desk, Midday, and PM Desk can be planned. Break is consumed only."),
    ("BriefingSeats", "Household seats", "Two to four local desks share this phone. ShareLink sends a day's memo."),
  ]

  var body: some View {
    ZStack {
      CivicBlotter()
      GeometryReader { geo in
      VStack(spacing: 20) {
        TabView(selection: $store.page.sending(\.pageChanged)) {
          ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
            VStack(spacing: 16) {
              Image(page.image)
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width - 40, height: 200)
              Text(page.title)
                .font(CivicType.bold(24))
                .foregroundStyle(CivicPalette.navy)
                .multilineTextAlignment(.center)
                .frame(width: geo.size.width - 40)
              Text(page.note)
                .font(CivicType.regular(15))
                .foregroundStyle(CivicPalette.slate)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .frame(width: geo.size.width - 48)
              Spacer(minLength: 4)
            }
            .frame(width: geo.size.width, height: geo.size.height - 80)
            .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(width: geo.size.width)
        CivicPrimaryButton(title: store.page == pages.count - 1 ? "Open the desk" : "Next") {
          if store.page == pages.count - 1 {
            store.send(.finishTapped)
          } else {
            store.send(.nextTapped)
          }
        }
        .padding(.horizontal, 24)
        Spacer().frame(height: 12)
      }
      .padding(.top, 32)
      }
    }
  }
}

#Preview {
  BriefingView(store: Store(initialState: BriefingFeature.State()) { BriefingFeature() })
}
