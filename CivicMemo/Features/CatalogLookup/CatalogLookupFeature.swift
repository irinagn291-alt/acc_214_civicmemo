import ComposableArchitecture
import SwiftUI

@Reducer
struct CatalogLookupFeature {
  @ObservableState
  struct State: Equatable {
    var query = ""
    var hits: [CatalogArticle] = []
    var isWorking = false
    var fault: String?
  }

  enum Action: BindableAction, Equatable {
    case binding(BindingAction<State>)
    case appear
    case submitLookup
    case hitsReady(Result<[CatalogArticle], CatalogFault>)
    case pick(CatalogArticle)
    case delegate(Delegate)
    enum Delegate: Equatable {
      case picked(CatalogArticle)
    }
  }

  private enum CancelID { case lookup }

  @Dependency(\.catalogGateway) var catalogGateway
  @Dependency(\.continuousClock) var clock

  var body: some ReducerOf<Self> {
    BindingReducer()
    Reduce { state, action in
      switch action {
      case .binding(\.query):
        return .run { send in
          try await clock.sleep(for: .milliseconds(380))
          await send(.submitLookup)
        }
        .cancellable(id: CancelID.lookup, cancelInFlight: true)
      case .binding:
        return .none
      case .appear:
        return .none
      case .submitLookup:
        let term = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
          state.hits = []
          state.isWorking = false
          return .none
        }
        state.isWorking = true
        state.fault = nil
        return .run { send in
          do {
            let rows = try await catalogGateway.search(term)
            await send(.hitsReady(.success(rows)))
          } catch {
            await send(.hitsReady(.failure(CatalogFault(message: error.localizedDescription))))
          }
        }
        .cancellable(id: CancelID.lookup, cancelInFlight: true)
      case let .hitsReady(.success(rows)):
        state.isWorking = false
        state.hits = rows
        return .none
      case let .hitsReady(.failure(fault)):
        state.isWorking = false
        state.fault = fault.message
        return .none
      case let .pick(article):
        return .send(.delegate(.picked(article)))
      case .delegate:
        return .none
      }
    }
  }
}

struct CatalogLookupView: View {
  @Bindable var store: StoreOf<CatalogLookupFeature>

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          TextField("Commodity name", text: $store.query)
            .font(CivicType.regular(16))
            .padding(12)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(CivicPalette.fog))
            .textInputAutocapitalization(.never)
          CivicPrimaryButton(title: "Search catalog") {
            store.send(.submitLookup)
          }
          if store.isWorking {
            ProgressView()
              .frame(maxWidth: .infinity)
          }
          if let fault = store.fault {
            Text(fault)
              .font(CivicType.regular(13))
              .foregroundStyle(CivicPalette.slate)
          }
          Text("Local shelf")
            .font(CivicType.semibold(14))
            .foregroundStyle(CivicPalette.navy)
          ForEach(CivicDemoSeed.shelf) { article in
            articleRow(article)
          }
          if !store.hits.isEmpty {
            Text("Catalog hits")
              .font(CivicType.semibold(14))
              .foregroundStyle(CivicPalette.navy)
            ForEach(store.hits) { article in
              articleRow(article)
            }
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("Lookup")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear { store.send(.appear) }
  }

  private func articleRow(_ article: CatalogArticle) -> some View {
    Button {
      store.send(.pick(article))
    } label: {
      CivicCard {
        HStack(spacing: 12) {
          if let asset = article.shelfAsset {
            Image(asset)
              .resizable()
              .scaledToFit()
              .frame(width: 48, height: 48)
          }
          VStack(alignment: .leading, spacing: 4) {
            Text(article.displayName)
              .font(CivicType.semibold(15))
              .foregroundStyle(CivicPalette.ink)
            Text("\(Int(article.perHundred.energyKcal.rounded())) kcal / 100 g")
              .font(CivicType.regular(12))
              .foregroundStyle(CivicPalette.slate)
          }
          Spacer()
        }
      }
    }
    .buttonStyle(.plain)
  }
}
