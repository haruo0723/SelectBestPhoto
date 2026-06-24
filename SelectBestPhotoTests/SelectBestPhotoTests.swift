@testable import SelectBestPhoto
import Testing

struct SelectBestPhotoTests {
    @Test func appModuleLoads() {
        #expect(String(describing: SelectBestPhotoApp.self) == "SelectBestPhotoApp")
    }
}
