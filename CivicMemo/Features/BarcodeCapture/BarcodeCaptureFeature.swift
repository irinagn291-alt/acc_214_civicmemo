import ComposableArchitecture
import SwiftUI

@Reducer
struct BarcodeCaptureFeature {
  @ObservableState
  struct State: Equatable {
    var manualCode = ""
    var isWorking = false
    var fault: String?
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case scanned(String)
    case submitManual
    case resolved(Result<CatalogArticle, CatalogFault>)
    case delegate(Delegate)
    enum Delegate: Equatable {
      case resolved(CatalogArticle)
    }
  }

  @Dependency(\.catalogGateway) var catalogGateway

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding:
        return .none
      case let .scanned(raw):
        return lookup(raw, state: &state)
      case .submitManual:
        return lookup(state.manualCode, state: &state)
      case let .resolved(.success(article)):
        state.isWorking = false
        return .send(.delegate(.resolved(article)))
      case let .resolved(.failure(fault)):
        state.isWorking = false
        state.fault = fault.message
        return .none
      case .delegate:
        return .none
      }
    }
  }

  private func lookup(_ raw: String, state: inout State) -> Effect<Action> {
    let code = CommodityCodePolicy.normalize(raw) ?? raw
    state.isWorking = true
    state.fault = nil
    return .run { send in
      do {
        let article = try await catalogGateway.lookup(code)
        await send(.resolved(.success(article)))
      } catch {
        await send(.resolved(.failure(CatalogFault(message: error.localizedDescription))))
      }
    }
  }
}

struct BarcodeCaptureView: View {
  @Bindable var store: StoreOf<BarcodeCaptureFeature>

  var body: some View {
    ZStack {
      CivicBlotter()
      VStack(spacing: 16) {
        BarcodeScannerRepresentable { raw in
          store.send(.scanned(raw))
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(CivicPalette.navy, lineWidth: 1))
        Text("Manual commodity code")
          .font(CivicType.medium(13))
          .foregroundStyle(CivicPalette.slate)
          .frame(maxWidth: .infinity, alignment: .leading)
        TextField("EAN / UPC digits", text: $store.manualCode)
          .keyboardType(.numberPad)
          .font(CivicType.regular(16))
          .padding(12)
          .background(Color.white)
        CivicPrimaryButton(title: "Open code") {
          store.send(.submitManual)
        }
        if store.isWorking {
          ProgressView()
        }
        if let fault = store.fault {
          Text(fault)
            .font(CivicType.regular(13))
            .foregroundStyle(CivicPalette.slate)
        }
        Spacer()
      }
      .padding(16)
    }
    .navigationTitle("Scan")
    .navigationBarTitleDisplayMode(.inline)
  }
}
