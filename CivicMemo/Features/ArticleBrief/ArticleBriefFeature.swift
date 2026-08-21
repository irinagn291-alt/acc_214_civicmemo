import SwiftUI

@MainActor
@Observable
final class ArticleBriefFeature {
  var article: CatalogArticle
  var grams: Double
  var didPin = false
  var onContinue: ((CatalogArticle, Double) -> Void)?
  var onPinWish: ((CatalogArticle) -> Void)?

  init(article: CatalogArticle, grams: Double) {
    self.article = article
    self.grams = grams
  }

  var portion: MacroBundle {
    article.portion(grams: grams)
  }

  func continueTapped() {
    onContinue?(article, grams)
  }

  func pinWish() {
    didPin = true
    onPinWish?(article)
  }
}

struct ArticleBriefView: View {
  @Bindable var board: ArticleBriefFeature

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          if let asset = board.article.shelfAsset {
            Image(asset)
              .resizable()
              .scaledToFit()
              .frame(height: 140)
              .frame(maxWidth: .infinity)
          }
          Text(board.article.displayName)
            .font(CivicType.bold(22))
            .foregroundStyle(CivicPalette.navy)
          if let brand = board.article.brandLine {
            Text(brand)
              .font(CivicType.regular(14))
              .foregroundStyle(CivicPalette.slate)
          }
          CivicCard {
            VStack(alignment: .leading, spacing: 8) {
              Text("Per 100 g")
                .font(CivicType.semibold(13))
                .foregroundStyle(CivicPalette.navy)
              macroLine(board.article.perHundred)
            }
          }
          CivicCard {
            VStack(alignment: .leading, spacing: 10) {
              Text("Portion  \(Int(board.grams)) g")
                .font(CivicType.semibold(13))
                .foregroundStyle(CivicPalette.navy)
              PortionSliderRepresentable(grams: $board.grams)
                .frame(height: 32)
              macroLine(board.portion)
            }
          }
          CivicPrimaryButton(title: "Assign slot") {
            board.continueTapped()
          }
          Button {
            board.pinWish()
          } label: {
            Text(board.didPin ? "Pinned to wish board" : "Pin to wish board")
              .font(CivicType.medium(14))
              .foregroundStyle(CivicPalette.blue)
              .frame(maxWidth: .infinity)
          }
          .disabled(board.didPin)
        }
        .padding(16)
      }
    }
    .navigationTitle("Brief")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func macroLine(_ bundle: MacroBundle) -> some View {
    Text("\(Int(bundle.energyKcal.rounded())) kcal · P \(Int(bundle.proteinGrams.rounded())) · C \(Int(bundle.carbGrams.rounded())) · F \(Int(bundle.fatGrams.rounded()))")
      .font(CivicType.regular(13))
      .foregroundStyle(CivicPalette.ink)
  }
}
