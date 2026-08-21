import SwiftUI

@MainActor
@Observable
final class QuotaEditorFeature {
  var energy: String
  var protein: String
  var carbs: String
  var fat: String
  var onSaved: ((NutritionQuota) -> Void)?

  init(quota: NutritionQuota) {
    energy = String(Int(quota.energyKcal))
    protein = String(Int(quota.proteinGrams))
    carbs = String(Int(quota.carbGrams))
    fat = String(Int(quota.fatGrams))
  }

  func save() {
    onSaved?(
      NutritionQuota(
        energyKcal: Double(energy) ?? NutritionQuota.civicDefault.energyKcal,
        proteinGrams: Double(protein) ?? NutritionQuota.civicDefault.proteinGrams,
        carbGrams: Double(carbs) ?? NutritionQuota.civicDefault.carbGrams,
        fatGrams: Double(fat) ?? NutritionQuota.civicDefault.fatGrams
      )
    )
  }
}

struct QuotaEditorView: View {
  @Bindable var board: QuotaEditorFeature
  @State private var showContact = false

  var body: some View {
    ZStack {
      CivicBlotter()
      VStack(spacing: 14) {
        field("Energy kcal", text: $board.energy)
        field("Protein g", text: $board.protein)
        field("Carbs g", text: $board.carbs)
        field("Fat g", text: $board.fat)
        CivicPrimaryButton(title: "Save goals") {
          board.save()
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
