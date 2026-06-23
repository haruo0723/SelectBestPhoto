import FirebaseCore
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseAppConfigurator.configureIfPossible()
        return true
    }
}

enum FirebaseAppConfigurator {
    static func configureIfPossible(bundle: Bundle = .main) {
        guard FirebaseApp.app() == nil else {
            return
        }

        guard bundle.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return
        }

        FirebaseApp.configure()
    }
}
