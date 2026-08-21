import SwiftUI

@MainActor
@Observable
final class SlotAssignFeature {
  var article: CatalogArticle
  var grams: Double
  var today: DayStamp
  var slot: DeskSlot = .amDesk
  var kind: LedgerKind = .consumed
  var planDay: DayStamp
  var notice: String?
  var onCommitted: ((IntakeRecord) -> Void)?

  private let makeID: () -> UUID

  init(
    article: CatalogArticle,
    grams: Double,
    today: DayStamp,
    makeID: @escaping () -> UUID = { UUID() }
  ) {
    self.article = article
    self.grams = grams
    self.today = today
    self.planDay = today
    self.makeID = makeID
  }

  func pickSlot(_ slot: DeskSlot) {
    self.slot = slot
    if slot == .breakSlot, kind == .scheduled {
      kind = .consumed
      notice = "Break stays on the consumed desk only."
    }
  }

  func pickKind(_ kind: LedgerKind) {
    if kind == .scheduled, slot == .breakSlot {
      notice = "Break cannot be planned. Pick AM Desk, Midday, or PM Desk."
      return
    }
    self.kind = kind
    notice = nil
  }

  @discardableResult
  func confirm() -> IntakeRecord? {
    if kind == .scheduled, !slot.isPlanEligible {
      notice = "Break cannot be planned."
      return nil
    }
    let day = kind == .consumed ? today : planDay
    let record = IntakeRecord(
      id: makeID(),
      article: article,
      grams: grams,
      slot: slot,
      day: day,
      kind: kind
    )
    onCommitted?(record)
    return record
  }
}

struct SlotAssignView: View {
  @Bindable var board: SlotAssignFeature
  private let calendar = Calendar.current

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text(board.article.displayName)
            .font(CivicType.bold(20))
            .foregroundStyle(CivicPalette.navy)
          Text("\(Int(board.grams)) g")
            .font(CivicType.regular(14))
            .foregroundStyle(CivicPalette.slate)
          Text("Desk slot")
            .font(CivicType.semibold(13))
            .foregroundStyle(CivicPalette.navy)
          HStack(spacing: 8) {
            ForEach(DeskSlot.allCases, id: \.self) { slot in
              Button {
                board.pickSlot(slot)
              } label: {
                VStack(spacing: 6) {
                  Image(slot.artName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                  CivicChip(title: slot.deskTitle, selected: board.slot == slot)
                }
              }
              .buttonStyle(.plain)
            }
          }
          Text("Ledger")
            .font(CivicType.semibold(13))
            .foregroundStyle(CivicPalette.navy)
          HStack {
            Button {
              board.pickKind(.consumed)
            } label: {
              CivicChip(title: "Consumed", selected: board.kind == .consumed)
            }
            Button {
              board.pickKind(.scheduled)
            } label: {
              CivicChip(title: "Plan", selected: board.kind == .scheduled)
            }
          }
          if board.kind == .scheduled {
            DatePicker(
              "Plan day",
              selection: Binding(
                get: { board.planDay.dateValue(calendar: calendar) },
                set: { board.planDay = DayStamp.from($0, calendar: calendar) }
              ),
              in: board.today.dateValue(calendar: calendar)...board.today.shifting(days: 13, calendar: calendar).dateValue(calendar: calendar),
              displayedComponents: .date
            )
            .font(CivicType.regular(14))
          }
          if let notice = board.notice {
            Text(notice)
              .font(CivicType.regular(13))
              .foregroundStyle(CivicPalette.slate)
          }
          CivicPrimaryButton(title: "Write memo line") {
            board.confirm()
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("Assign")
    .navigationBarTitleDisplayMode(.inline)
  }
}
