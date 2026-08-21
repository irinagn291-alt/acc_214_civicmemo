import ComposableArchitecture
import SwiftUI

@Reducer
struct WishBoardFeature {
  @ObservableState
  struct State: Equatable {
    var wishes: [WishListing]
    var notice: String?
  }

  enum Action: Equatable {
    case pin(CatalogArticle)
    case unpin(String)
    case pick(CatalogArticle)
    case delegate(Delegate)
    enum Delegate: Equatable {
      case unpin(String)
      case picked(CatalogArticle)
    }
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case let .pin(article):
        if state.wishes.contains(where: { $0.id == article.id }) {
          state.notice = "That SKU is already on the wish board."
          return .none
        }
        state.wishes.append(WishListing(id: article.id, article: article))
        state.notice = nil
        return .none
      case let .unpin(sku):
        state.wishes.removeAll { $0.id == sku }
        return .send(.delegate(.unpin(sku)))
      case let .pick(article):
        return .send(.delegate(.picked(article)))
      case .delegate:
        return .none
      }
    }
  }
}

struct WishBoardView: View {
  let store: StoreOf<WishBoardFeature>

  var body: some View {
    ZStack {
      CivicBlotter()
      if store.wishes.isEmpty {
        CivicEmptyBoard(
          image: "EmptyWish",
          title: "Wish board empty",
          note: "Pin a commodity from its brief. Duplicate SKUs are refused."
        )
        .padding(24)
      } else {
        ScrollView {
          VStack(spacing: 12) {
            if let notice = store.notice {
              Text(notice)
                .font(CivicType.regular(13))
                .foregroundStyle(CivicPalette.slate)
            }
            ForEach(store.wishes) { wish in
              CivicCard {
                HStack {
                  if let asset = wish.article.shelfAsset {
                    Image(asset)
                      .resizable()
                      .scaledToFit()
                      .frame(width: 44, height: 44)
                  }
                  VStack(alignment: .leading) {
                    Text(wish.article.displayName)
                      .font(CivicType.semibold(14))
                    Text(wish.id)
                      .font(CivicType.regular(11))
                      .foregroundStyle(CivicPalette.slate)
                  }
                  Spacer()
                  Button("Open") { store.send(.pick(wish.article)) }
                    .font(CivicType.medium(13))
                    .foregroundStyle(CivicPalette.blue)
                  Button("Drop") { store.send(.unpin(wish.id)) }
                    .font(CivicType.medium(13))
                    .foregroundStyle(CivicPalette.slate)
                }
              }
            }
          }
          .padding(16)
        }
      }
    }
    .navigationTitle("Wish")
    .navigationBarTitleDisplayMode(.inline)
  }
}
