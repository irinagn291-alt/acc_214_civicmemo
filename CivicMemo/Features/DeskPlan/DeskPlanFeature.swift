import SwiftUI

@MainActor
@Observable
final class DeskPlanFeature {
  var today: DayStamp
  var selected: DayStamp
  var records: [IntakeRecord]
  var horizon = 14
  var onDelete: ((UUID) -> Void)?

  init(today: DayStamp, selected: DayStamp, records: [IntakeRecord]) {
    self.today = today
    self.selected = selected
    self.records = records
  }

  func select(_ day: DayStamp) {
    selected = day
  }

  func delete(_ id: UUID) {
    records.removeAll { $0.id == id }
    onDelete?(id)
  }
}

struct DeskPlanView: View {
  @Bindable var board: DeskPlanFeature
  private let calendar = Calendar.current

  var body: some View {
    ZStack {
      CivicBlotter()
      VStack(alignment: .leading, spacing: 12) {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(planDays, id: \.self) { day in
              Button {
                board.select(day)
              } label: {
                VStack(spacing: 4) {
                  Text(short(day))
                    .font(CivicType.medium(12))
                  Text("\(Int(energy(day).rounded()))")
                    .font(CivicType.semibold(12))
                }
                .foregroundStyle(board.selected == day ? .white : CivicPalette.navy)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(board.selected == day ? CivicPalette.navy : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
              .buttonStyle(.plain)
            }
          }
        }
        let rows = plannedRows(on: board.selected)
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
                    Button("Drop") { board.delete(row.id) }
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
    (0..<board.horizon).map { board.today.shifting(days: $0, calendar: calendar) }
  }

  private func plannedRows(on day: DayStamp) -> [IntakeRecord] {
    board.records.filter { $0.kind == .scheduled && $0.day == day }
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
