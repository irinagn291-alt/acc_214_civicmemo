import SwiftUI

struct DeskRootView: View {
  @Bindable var root: DeskRootFeature

  var body: some View {
    Group {
      if let briefing = root.briefing {
        BriefingView(board: briefing)
      } else if let desk = root.desk {
        NavigationStack(path: $root.path) {
          DeskTodayView(board: desk)
            .navigationDestination(for: DeskRoute.self) { route in
              destination(route)
            }
        }
      } else {
        ZStack {
          CivicBlotter()
          ProgressView()
        }
      }
    }
    .tint(CivicPalette.blue)
    .onAppear { root.appear() }
  }

  @ViewBuilder
  private func destination(_ route: DeskRoute) -> some View {
    switch route {
    case .catalogLookup:
      CatalogLookupView(board: root.lookup)
    case .barcodeCapture:
      BarcodeCaptureView(board: root.capture)
    case .articleBrief:
      if let brief = root.brief {
        ArticleBriefView(board: brief)
      }
    case .slotAssign:
      if let assign = root.assign {
        SlotAssignView(board: assign)
      }
    case .eatenRoster:
      if let eaten = root.eaten {
        EatenRosterView(board: eaten)
      }
    case .wishBoard:
      if let wish = root.wish {
        WishBoardView(board: wish)
      }
    case .quotaEditor:
      if let quota = root.quota {
        QuotaEditorView(board: quota)
      }
    case .deskPlan:
      if let plan = root.plan {
        DeskPlanView(board: plan)
      }
    case .seatRoster:
      if let seats = root.seats {
        SeatRosterView(board: seats)
      }
    }
  }
}

#Preview {
  DeskRootView(root: {
    let root = DeskRootFeature(archive: .memoryPreview)
    root.briefing = BriefingFeature()
    return root
  }())
}
