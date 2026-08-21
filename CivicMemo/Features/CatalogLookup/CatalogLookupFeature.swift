import SwiftUI

@MainActor
@Observable
final class CatalogLookupFeature {
  var query = ""
  var hits: [CatalogArticle] = []
  var isWorking = false
  var fault: String?
  var onPicked: ((CatalogArticle) -> Void)?

  private let catalog: CatalogGateway
  private var lookupTask: Task<Void, Never>?

  init(catalog: CatalogGateway = .worldOffice) {
    self.catalog = catalog
  }

  func scheduleLookup() {
    lookupTask?.cancel()
    lookupTask = Task {
      try? await Task.sleep(nanoseconds: 380_000_000)
      guard !Task.isCancelled else { return }
      await submitLookup()
    }
  }

  func submitLookup() async {
    let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else {
      hits = []
      isWorking = false
      return
    }
    isWorking = true
    fault = nil
    do {
      let rows = try await catalog.search(term)
      guard !Task.isCancelled else { return }
      isWorking = false
      hits = rows
    } catch {
      guard !Task.isCancelled else { return }
      isWorking = false
      fault = (error as? CatalogFault)?.message ?? error.localizedDescription
    }
  }

  func pick(_ article: CatalogArticle) {
    onPicked?(article)
  }
}

struct CatalogLookupView: View {
  @Bindable var board: CatalogLookupFeature

  var body: some View {
    ZStack {
      CivicBlotter()
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          TextField("Commodity name", text: $board.query)
            .font(CivicType.regular(16))
            .padding(12)
            .background(Color.white)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(CivicPalette.fog))
            .textInputAutocapitalization(.never)
            .onChange(of: board.query) { _, _ in
              board.scheduleLookup()
            }
          CivicPrimaryButton(title: "Search catalog") {
            Task { await board.submitLookup() }
          }
          if board.isWorking {
            ProgressView()
              .frame(maxWidth: .infinity)
          }
          if let fault = board.fault {
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
          if !board.hits.isEmpty {
            Text("Catalog hits")
              .font(CivicType.semibold(14))
              .foregroundStyle(CivicPalette.navy)
            ForEach(board.hits) { article in
              articleRow(article)
            }
          }
        }
        .padding(16)
      }
    }
    .navigationTitle("Lookup")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func articleRow(_ article: CatalogArticle) -> some View {
    Button {
      board.pick(article)
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
