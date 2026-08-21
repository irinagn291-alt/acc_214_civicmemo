import SwiftUI

@MainActor
@Observable
final class EatenRosterFeature {
  var records: [IntakeRecord]
  var onDelete: ((UUID) -> Void)?

  init(records: [IntakeRecord]) {
    self.records = records
  }

  func delete(_ id: UUID) {
    records.removeAll { $0.id == id }
    onDelete?(id)
  }
}

struct EatenRosterView: View {
  @Bindable var board: EatenRosterFeature

  var body: some View {
    ZStack {
      CivicBlotter()
      if board.records.isEmpty {
        CivicEmptyBoard(
          image: "EmptyEaten",
          title: "Nothing consumed",
          note: "Assigned consumed lines for this day will sit here."
        )
        .padding(24)
      } else {
        List {
          ForEach(DeskSlot.allCases, id: \.self) { slot in
            let rows = board.records.filter { $0.slot == slot }
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
                      board.delete(row.id)
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
