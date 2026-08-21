import SwiftUI

@MainActor
@Observable
final class WishBoardFeature {
  var wishes: [WishListing]
  var notice: String?
  var onUnpin: ((String) -> Void)?
  var onPicked: ((CatalogArticle) -> Void)?

  init(wishes: [WishListing]) {
    self.wishes = wishes
  }

  func pin(_ article: CatalogArticle) {
    if wishes.contains(where: { $0.id == article.id }) {
      notice = "That SKU is already on the wish board."
      return
    }
    wishes.append(WishListing(id: article.id, article: article))
    notice = nil
  }

  func unpin(_ sku: String) {
    wishes.removeAll { $0.id == sku }
    onUnpin?(sku)
  }

  func pick(_ article: CatalogArticle) {
    onPicked?(article)
  }
}

struct WishBoardView: View {
  @Bindable var board: WishBoardFeature

  var body: some View {
    ZStack {
      CivicBlotter()
      if board.wishes.isEmpty {
        CivicEmptyBoard(
          image: "EmptyWish",
          title: "Wish board empty",
          note: "Pin a commodity from its brief. Duplicate SKUs are refused."
        )
        .padding(24)
      } else {
        ScrollView {
          VStack(spacing: 12) {
            if let notice = board.notice {
              Text(notice)
                .font(CivicType.regular(13))
                .foregroundStyle(CivicPalette.slate)
            }
            ForEach(board.wishes) { wish in
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
                  Button("Open") { board.pick(wish.article) }
                    .font(CivicType.medium(13))
                    .foregroundStyle(CivicPalette.blue)
                  Button("Drop") { board.unpin(wish.id) }
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
