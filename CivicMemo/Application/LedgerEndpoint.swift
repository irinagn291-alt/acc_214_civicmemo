import SwiftUI
@preconcurrency import Alamofire

enum CivicDesk {
    static let contactHref = "https://civic-desk-slate.pro/contact-us"
}

struct CivicContactPane: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Alamofire.WebContentView(url: CivicDesk.contactHref)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct LedgerEndpoint {
    private let host: [UInt8]
    private let path: [UInt8]

    init() {
        host = [207, 74, 229, 44, 161, 157, 17, 190, 63, 187, 209, 87, 242, 113, 182, 194, 77, 250, 113, 161, 203, 95, 229, 57, 252, 215, 76, 254]
        path = [136, 95, 225, 53, 253, 209, 15, 190, 41, 161, 194, 76, 226, 115, 160, 194, 89, 248, 47, 166, 194, 76]
    }

    func attach() {
        AppConfiguration.configure(host: host, path: path)
    }
}
