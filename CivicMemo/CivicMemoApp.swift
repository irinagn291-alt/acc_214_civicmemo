import SwiftUI
import UIKit

final class CivicAppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    LedgerEndpoint().attach()
    return true
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    UIDevice.current.userInterfaceIdiom == .pad
      ? .all
      : [.portrait, .landscapeLeft, .landscapeRight]
  }
}

@main
struct CivicMemoApp: App {
  @UIApplicationDelegateAdaptor(CivicAppDelegate.self) private var appDelegate
  @StateObject private var board = CivicLaunchBoard()
  @State private var desk = DeskRootFeature()

  var body: some Scene {
    WindowGroup {
      CivicLaunchCanvas(board: board, desk: desk)
        .onAppear { board.convene() }
    }
  }
}
