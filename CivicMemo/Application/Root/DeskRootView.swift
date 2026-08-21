import ComposableArchitecture
import SwiftUI

struct DeskRootView: View {
  @Bindable var store: StoreOf<DeskRootFeature>

  var body: some View {
    Group {
      if let briefing = store.scope(state: \.briefing, action: \.briefing) {
        BriefingView(store: briefing)
      } else if let desk = store.scope(state: \.desk, action: \.desk) {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
          DeskTodayView(store: desk)
        } destination: { store in
          switch store.case {
          case let .catalogLookup(store):
            CatalogLookupView(store: store)
          case let .barcodeCapture(store):
            BarcodeCaptureView(store: store)
          case let .articleBrief(store):
            ArticleBriefView(store: store)
          case let .slotAssign(store):
            SlotAssignView(store: store)
          case let .eatenRoster(store):
            EatenRosterView(store: store)
          case let .wishBoard(store):
            WishBoardView(store: store)
          case let .quotaEditor(store):
            QuotaEditorView(store: store)
          case let .deskPlan(store):
            DeskPlanView(store: store)
          case let .seatRoster(store):
            SeatRosterView(store: store)
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
    .onAppear { store.send(.appear) }
  }
}

#Preview {
  DeskRootView(
    store: Store(initialState: DeskRootFeature.State(briefing: BriefingFeature.State())) {
      DeskRootFeature()
    }
  )
}
