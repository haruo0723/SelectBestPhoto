import SwiftUI

@main
struct SelectBestPhotoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            SelectBestPhotoRootView()
        }
    }
}
