import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

@main
struct SelectBestPhotoApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}

enum FirebaseSDKAvailability {
    static let linkedTypes: [Any.Type] = [
        FirebaseApp.self,
        Auth.self,
        Firestore.self,
        Storage.self
    ]
}
