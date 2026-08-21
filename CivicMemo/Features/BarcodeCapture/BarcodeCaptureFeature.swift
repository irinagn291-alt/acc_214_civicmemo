import SwiftUI

@MainActor
@Observable
final class BarcodeCaptureFeature {
  var manualCode = ""
  var isWorking = false
  var fault: String?
  var onResolved: ((CatalogArticle) -> Void)?

  private let catalog: CatalogGateway
  private var lookupTask: Task<Void, Never>?

  init(catalog: CatalogGateway = .worldOffice) {
    self.catalog = catalog
  }

  func scanned(_ raw: String) {
    lookup(raw)
  }

  func submitManual() {
    lookup(manualCode)
  }

  private func lookup(_ raw: String) {
    let code = CommodityCodePolicy.normalize(raw) ?? raw
    isWorking = true
    fault = nil
    lookupTask?.cancel()
    lookupTask = Task {
      do {
        let article = try await catalog.lookup(code)
        guard !Task.isCancelled else { return }
        isWorking = false
        onResolved?(article)
      } catch {
        guard !Task.isCancelled else { return }
        isWorking = false
        fault = (error as? CatalogFault)?.message ?? error.localizedDescription
      }
    }
  }
}

struct BarcodeCaptureView: View {
  @Bindable var board: BarcodeCaptureFeature

  var body: some View {
    ZStack {
      CivicBlotter()
      VStack(spacing: 16) {
        BarcodeScannerRepresentable { raw in
          board.scanned(raw)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(CivicPalette.navy, lineWidth: 1))
        Text("Manual commodity code")
          .font(CivicType.medium(13))
          .foregroundStyle(CivicPalette.slate)
          .frame(maxWidth: .infinity, alignment: .leading)
        TextField("EAN / UPC digits", text: $board.manualCode)
          .keyboardType(.numberPad)
          .font(CivicType.regular(16))
          .padding(12)
          .background(Color.white)
        CivicPrimaryButton(title: "Open code") {
          board.submitManual()
        }
        if board.isWorking {
          ProgressView()
        }
        if let fault = board.fault {
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
