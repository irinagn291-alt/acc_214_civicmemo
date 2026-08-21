import SwiftUI

@MainActor
@Observable
final class BriefingFeature {
  var page = 0
  var onFinished: (() -> Void)?

  func nextTapped() {
    page += 1
  }

  func finishTapped() {
    onFinished?()
  }
}

struct BriefingView: View {
  @Bindable var board: BriefingFeature

  private let pages: [(image: String, title: String, note: String)] = [
    ("BriefingWelcome", "Civic desk", "A quiet office memo for energy and macros. Local only — no account."),
    ("BriefingScan", "Look up or scan", "Search the civic catalog or read a carton barcode into a memo line."),
    ("BriefingSlots", "Four desk slots", "AM Desk, Midday, and PM Desk can be planned. Break is consumed only."),
    ("BriefingSeats", "Household seats", "Two to four local desks share this phone. ShareLink sends a day's memo."),
  ]

  var body: some View {
    ZStack {
      CivicBlotter()
      GeometryReader { geo in
      VStack(spacing: 20) {
        TabView(selection: $board.page) {
          ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
            VStack(spacing: 16) {
              Image(page.image)
                .resizable()
                .scaledToFit()
                .frame(width: geo.size.width - 40, height: 200)
              Text(page.title)
                .font(CivicType.bold(24))
                .foregroundStyle(CivicPalette.navy)
                .multilineTextAlignment(.center)
                .frame(width: geo.size.width - 40)
              Text(page.note)
                .font(CivicType.regular(15))
                .foregroundStyle(CivicPalette.slate)
                .multilineTextAlignment(.center)
                .lineLimit(5)
                .frame(width: geo.size.width - 48)
              Spacer(minLength: 4)
            }
            .frame(width: geo.size.width, height: geo.size.height - 80)
            .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(width: geo.size.width)
        CivicPrimaryButton(title: board.page == pages.count - 1 ? "Open the desk" : "Next") {
          if board.page == pages.count - 1 {
            board.finishTapped()
          } else {
            board.nextTapped()
          }
        }
        .padding(.horizontal, 24)
        Spacer().frame(height: 12)
      }
      .padding(.top, 32)
      }
    }
  }
}

#Preview {
  BriefingView(board: BriefingFeature())
}
