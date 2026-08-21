import SwiftUI

@MainActor
@Observable
final class SeatRosterFeature {
  var roster: HouseholdRoster
  var notice: String?
  var onSwitched: ((UUID) -> Void)?
  var onRosterChanged: ((HouseholdRoster) -> Void)?

  private let makeID: () -> UUID

  init(roster: HouseholdRoster, makeID: @escaping () -> UUID = { UUID() }) {
    self.roster = roster
    self.makeID = makeID
  }

  func activate(_ id: UUID) {
    guard roster.seats.contains(where: { $0.id == id }) else { return }
    roster.activeSeatID = id
    onSwitched?(id)
  }

  func addSeat() {
    guard roster.seats.count < 4 else {
      notice = "Four seats is the household ceiling."
      return
    }
    let labels = ["Desk North", "Desk South", "Desk East", "Desk West"]
    let initials = ["DN", "DS", "DE", "DW"]
    let index = roster.seats.count
    roster.seats.append(HouseholdSeat(id: makeID(), deskLabel: labels[index], initials: initials[index]))
    notice = nil
    onRosterChanged?(roster)
  }

  func dropSeat(_ id: UUID) {
    guard roster.seats.count > 2 else {
      notice = "Two seats stay on the household desk."
      return
    }
    roster.seats.removeAll { $0.id == id }
    if roster.activeSeatID == id {
      roster.activeSeatID = roster.seats[0].id
      onRosterChanged?(roster)
      onSwitched?(roster.activeSeatID)
      return
    }
    onRosterChanged?(roster)
  }
}

struct SeatRosterView: View {
  @Bindable var board: SeatRosterFeature

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text("2–4 local seats. Each desk has its own file.")
            .font(CivicType.regular(13))
            .foregroundStyle(CivicPalette.slate)
          if let notice = board.notice {
            Text(notice)
              .font(CivicType.regular(13))
              .foregroundStyle(CivicPalette.navy)
          }
          ForEach(board.roster.seats) { seat in
            CivicCard {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text(seat.deskLabel)
                    .font(CivicType.semibold(15))
                  Text(seat.initials)
                    .font(CivicType.regular(12))
                    .foregroundStyle(CivicPalette.slate)
                }
                Spacer()
                if board.roster.activeSeatID == seat.id {
                  CivicChip(title: "Active", selected: true)
                } else {
                  Button("Sit") { board.activate(seat.id) }
                    .font(CivicType.medium(13))
                    .foregroundStyle(CivicPalette.blue)
                }
                if board.roster.seats.count > 2 {
                  Button("Drop") { board.dropSeat(seat.id) }
                    .font(CivicType.medium(13))
                    .foregroundStyle(CivicPalette.slate)
                }
              }
            }
          }
          CivicPrimaryButton(title: "Add seat") {
            board.addSeat()
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("Seats")
    .navigationBarTitleDisplayMode(.inline)
  }
}
