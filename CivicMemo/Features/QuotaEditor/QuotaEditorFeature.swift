import ComposableArchitecture
import SwiftUI

@Reducer
struct QuotaEditorFeature {
  @ObservableState
  struct State: Equatable {
    var energy: String
    var protein: String
    var carbs: String
    var fat: String

    init(quota: NutritionQuota) {
      energy = String(Int(quota.energyKcal))
      protein = String(Int(quota.proteinGrams))
      carbs = String(Int(quota.carbGrams))
      fat = String(Int(quota.fatGrams))
    }
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case save
    case delegate(Delegate)
    enum Delegate: Equatable {
      case saved(NutritionQuota)
    }
  }

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case .save:
        let quota = NutritionQuota(
          energyKcal: Double(state.energy) ?? NutritionQuota.civicDefault.energyKcal,
          proteinGrams: Double(state.protein) ?? NutritionQuota.civicDefault.proteinGrams,
          carbGrams: Double(state.carbs) ?? NutritionQuota.civicDefault.carbGrams,
          fatGrams: Double(state.fat) ?? NutritionQuota.civicDefault.fatGrams
        )
        return .send(.delegate(.saved(quota)))
      case .delegate:
        return .none
      }
    }
  }
}

struct QuotaEditorView: View {
  @Bindable var store: StoreOf<QuotaEditorFeature>
  @State private var showContact = false

  var body: some View {
    ZStack {
      CivicBlotter()
      VStack(spacing: 14) {
        field("Energy kcal", text: $store.energy)
        field("Protein g", text: $store.protein)
        field("Carbs g", text: $store.carbs)
        field("Fat g", text: $store.fat)
        CivicPrimaryButton(title: "Save goals") {
          store.send(.save)
        }
        CivicPrimaryButton(title: "Contact Us") {
          showContact = true
        }
        Spacer()
      }
      .padding(16)
    }
    .navigationTitle("Goals")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showContact) {
      CivicContactPane()
    }
  }

  private func field(_ title: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(CivicType.medium(13))
        .foregroundStyle(CivicPalette.slate)
      TextField(title, text: text)
        .keyboardType(.decimalPad)
        .font(CivicType.regular(16))
        .padding(12)
        .background(Color.white)
    }
  }
}
