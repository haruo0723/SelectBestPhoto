import Testing
@testable import SelectBestPhoto

struct SelectBestPhotoTests {
    @Test func appModuleLoads() {
        #expect(String(describing: SelectBestPhotoApp.self) == "SelectBestPhotoApp")
    }
}
