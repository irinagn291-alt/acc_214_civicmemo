import SwiftUI

@MainActor
@Observable
final class DeskTodayFeature {
  var snapshot: SeatSnapshot
  var day: DayStamp
  var memoText: String = ""

  var onOpenLookup: (() -> Void)?
  var onOpenCapture: (() -> Void)?
  var onOpenEaten: (() -> Void)?
  var onOpenWish: (() -> Void)?
  var onOpenQuota: (() -> Void)?
  var onOpenPlan: (() -> Void)?
  var onOpenSeats: (() -> Void)?

  private let archive: SeatFileArchive
  private let calendar: Calendar

  init(
    snapshot: SeatSnapshot,
    day: DayStamp,
    archive: SeatFileArchive = .disk,
    calendar: Calendar = .current
  ) {
    self.snapshot = snapshot
    self.day = day
    self.archive = archive
    self.calendar = calendar
    self.memoText = DayMemoComposer.text(snapshot: snapshot, day: day, calendar: calendar)
  }

  var consumed: [IntakeRecord] {
    snapshot.records.filter { $0.kind == .consumed && $0.day == day }
  }

  var totals: MacroBundle {
    snapshot.consumedBundle(on: day)
  }

  func appear() {
    refreshMemo()
  }

  func applyCommit(_ record: IntakeRecord) {
    snapshot.append(record)
    persist()
  }

  func deleteRecord(_ id: UUID) {
    snapshot.removeRecord(id)
    persist()
  }

  func applyWish(_ article: CatalogArticle) {
    _ = snapshot.pinWish(article)
    persist()
  }

  func unpinWish(_ sku: String) {
    snapshot.unpinWish(sku)
    persist()
  }

  func replaceQuota(_ quota: NutritionQuota) {
    snapshot.quota = quota
    persist()
  }

  func replaceSnapshot(_ snapshot: SeatSnapshot) {
    self.snapshot = snapshot
    refreshMemo()
  }

  private func persist() {
    refreshMemo()
    try? archive.saveSnapshot(snapshot)
  }

  private func refreshMemo() {
    memoText = DayMemoComposer.text(snapshot: snapshot, day: day, calendar: calendar)
  }
}

struct DeskTodayView: View {
  @Bindable var board: DeskTodayFeature

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          header
          meters
          slotStrip
          actions
          if board.consumed.isEmpty {
            CivicEmptyBoard(
              image: "EmptyDesk",
              title: "Desk is clear",
              note: "Look up a commodity or scan a carton to write the first line."
            )
          } else {
            ForEach(board.consumed) { row in
              recordCard(row)
            }
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("Today")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          board.onOpenSeats?()
        } label: {
          Text(board.snapshot.seat.initials)
            .font(CivicType.semibold(12))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(CivicPalette.navy)
            .clipShape(Circle())
        }
      }
      ToolbarItem(placement: .topBarTrailing) {
        ShareLink(item: board.memoText) {
          Text("Share")
            .font(CivicType.medium(14))
            .foregroundStyle(CivicPalette.blue)
        }
      }
    }
    .onAppear { board.appear() }
  }

  private var header: some View {
    HStack(alignment: .center, spacing: 12) {
      Image("Splash")
        .resizable()
        .scaledToFill()
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
      VStack(alignment: .leading, spacing: 4) {
        Text(board.snapshot.seat.deskLabel)
          .font(CivicType.bold(20))
          .foregroundStyle(CivicPalette.navy)
        Text("Household memo · local seats")
          .font(CivicType.regular(13))
          .foregroundStyle(CivicPalette.slate)
      }
      Spacer()
    }
  }

  private var meters: some View {
    CivicCard {
      VStack(spacing: 12) {
        QuotaMeter(title: "Energy", value: board.totals.energyKcal, cap: board.snapshot.quota.energyKcal, unit: "kcal")
        QuotaMeter(title: "Protein", value: board.totals.proteinGrams, cap: board.snapshot.quota.proteinGrams, unit: "g")
        QuotaMeter(title: "Carbs", value: board.totals.carbGrams, cap: board.snapshot.quota.carbGrams, unit: "g")
        QuotaMeter(title: "Fat", value: board.totals.fatGrams, cap: board.snapshot.quota.fatGrams, unit: "g")
      }
    }
  }

  private var slotStrip: some View {
    HStack(spacing: 8) {
      ForEach(DeskSlot.allCases, id: \.self) { slot in
        VStack(spacing: 6) {
          Image(slot.artName)
            .resizable()
            .scaledToFit()
            .frame(height: 52)
          Text(slot.deskTitle)
            .font(CivicType.medium(10))
            .foregroundStyle(CivicPalette.navy)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
      }
    }
  }

  private var actions: some View {
    VStack(spacing: 10) {
      HStack(spacing: 10) {
        CivicPrimaryButton(title: "Lookup") { board.onOpenLookup?() }
        Button {
          board.onOpenCapture?()
        } label: {
          Text("Scan")
            .font(CivicType.semibold(16))
            .foregroundStyle(CivicPalette.navy)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(CivicPalette.navy, lineWidth: 1))
        }
        .buttonStyle(.plain)
      }
      HStack(spacing: 10) {
        navChip("Eaten") { board.onOpenEaten?() }
        navChip("Wish") { board.onOpenWish?() }
        navChip("Goals") { board.onOpenQuota?() }
        navChip("Plan") { board.onOpenPlan?() }
      }
    }
  }

  private func navChip(_ title: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(CivicType.medium(13))
        .foregroundStyle(CivicPalette.navy)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(CivicPalette.fog)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
  }

  private func recordCard(_ row: IntakeRecord) -> some View {
    CivicCard {
      HStack(alignment: .top, spacing: 12) {
        Image(row.slot.artName)
          .resizable()
          .scaledToFit()
          .frame(width: 44, height: 44)
        VStack(alignment: .leading, spacing: 4) {
          Text(row.article.displayName)
            .font(CivicType.semibold(15))
            .foregroundStyle(CivicPalette.ink)
          Text("\(row.slot.deskTitle) · \(Int(row.grams)) g · \(Int(row.portionBundle.energyKcal.rounded())) kcal")
            .font(CivicType.regular(12))
            .foregroundStyle(CivicPalette.slate)
        }
        Spacer()
        Button {
          board.deleteRecord(row.id)
        } label: {
          Text("Drop")
            .font(CivicType.medium(12))
            .foregroundStyle(CivicPalette.navy)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(CivicPalette.fog)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
      }
    }
  }
}
