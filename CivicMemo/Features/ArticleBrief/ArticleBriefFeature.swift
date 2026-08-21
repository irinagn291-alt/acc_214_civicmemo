import ComposableArchitecture
import SwiftUI

@Reducer
struct ArticleBriefFeature {
  @ObservableState
  struct State: Equatable {
    var article: CatalogArticle
    var grams: Double
    var didPin = false

    var portion: MacroBundle {
      article.portion(grams: grams)
    }
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case continueTapped
    case pinWish
    case delegate(Delegate)
    enum Delegate: Equatable {
      case continueAssign(article: CatalogArticle, grams: Double)
      case pinWish(CatalogArticle)
    }
  }

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case .continueTapped:
        return .send(.delegate(.continueAssign(article: state.article, grams: state.grams)))
      case .pinWish:
        state.didPin = true
        return .send(.delegate(.pinWish(state.article)))
      case .delegate:
        return .none
      }
    }
  }
}

struct ArticleBriefView: View {
  @Bindable var store: StoreOf<ArticleBriefFeature>

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          if let asset = store.article.shelfAsset {
            Image(asset)
              .resizable()
              .scaledToFit()
              .frame(height: 140)
              .frame(maxWidth: .infinity)
          }
          Text(store.article.displayName)
            .font(CivicType.bold(22))
            .foregroundStyle(CivicPalette.navy)
          if let brand = store.article.brandLine {
            Text(brand)
              .font(CivicType.regular(14))
              .foregroundStyle(CivicPalette.slate)
          }
          CivicCard {
            VStack(alignment: .leading, spacing: 8) {
              Text("Per 100 g")
                .font(CivicType.semibold(13))
                .foregroundStyle(CivicPalette.navy)
              macroLine(store.article.perHundred)
            }
          }
          CivicCard {
            VStack(alignment: .leading, spacing: 10) {
              Text("Portion  \(Int(store.grams)) g")
                .font(CivicType.semibold(13))
                .foregroundStyle(CivicPalette.navy)
              PortionSliderRepresentable(grams: $store.grams)
                .frame(height: 32)
              macroLine(store.portion)
            }
          }
          CivicPrimaryButton(title: "Assign slot") {
            store.send(.continueTapped)
          }
          Button {
            store.send(.pinWish)
          } label: {
            Text(store.didPin ? "Pinned to wish board" : "Pin to wish board")
              .font(CivicType.medium(14))
              .foregroundStyle(CivicPalette.blue)
              .frame(maxWidth: .infinity)
          }
          .disabled(store.didPin)
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
