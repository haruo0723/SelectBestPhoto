import FirebaseCore
import SwiftUI

struct SelectBestPhotoRootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            TextCategoryListView(
                viewModel: TextCategoryDependencies.makeListViewModel(),
                makeSettingsViewModel: TextCategoryDependencies.makeSettingsViewModel(year:),
                makeCandidateManagementViewModel: TextCategoryDependencies.makeCandidateManagementViewModel(year:categoryId:),
                makeRankingInputViewModel: TextCategoryDependencies.makeRankingInputViewModel(year:categoryId:),
                makeWaitingViewModel: TextCategoryDependencies.makeWaitingViewModel(year:categoryId:),
                makeResultViewModel: TextCategoryDependencies.makeResultViewModel(year:categoryId:)
            )
            .tabItem {
                Label("発表", systemImage: "trophy")
            }

            NavigationStack {
                List {
                    Section("アプリ") {
                        Label("テキスト候補型カスタム部門 MVP", systemImage: "text.badge.star")
                        Label("iPhone専用", systemImage: "iphone")
                    }
                }
                .navigationTitle("設定")
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}

private enum TextCategoryDependencies {
    @MainActor
    static func makeListViewModel() -> TextCategoryListViewModel {
        guard FirebaseApp.app() != nil else {
            return TextCategoryListViewModel(
                repository: UnavailableTextCategoryRepository(),
                pairContextProvider: UnavailablePairContextProvider()
            )
        }

        return TextCategoryListViewModel(
            repository: FirestoreTextCategoryRepository(),
            pairContextProvider: FirebasePairContextProvider()
        )
    }

    @MainActor
    static func makeSettingsViewModel(year: Int) -> TextCategorySettingsViewModel {
        guard FirebaseApp.app() != nil else {
            return TextCategorySettingsViewModel(
                repository: UnavailableTextCategoryRepository(),
                pairContextProvider: UnavailablePairContextProvider(),
                year: year
            )
        }

        return TextCategorySettingsViewModel(
            repository: FirestoreTextCategoryRepository(),
            pairContextProvider: FirebasePairContextProvider(),
            year: year
        )
    }

    @MainActor
    static func makeCandidateManagementViewModel(year: Int, categoryId: String) -> TextCandidateManagementViewModel {
        guard FirebaseApp.app() != nil else {
            return TextCandidateManagementViewModel(
                repository: UnavailableTextCategoryRepository(),
                pairContextProvider: UnavailablePairContextProvider(),
                year: year,
                categoryId: categoryId
            )
        }

        return TextCandidateManagementViewModel(
            repository: FirestoreTextCategoryRepository(),
            pairContextProvider: FirebasePairContextProvider(),
            year: year,
            categoryId: categoryId
        )
    }

    @MainActor
    static func makeRankingInputViewModel(year: Int, categoryId: String) -> TextRankingInputViewModel {
        guard FirebaseApp.app() != nil else {
            return TextRankingInputViewModel(
                repository: UnavailableTextCategoryRepository(),
                pairContextProvider: UnavailablePairContextProvider(),
                year: year,
                categoryId: categoryId
            )
        }

        return TextRankingInputViewModel(
            repository: FirestoreTextCategoryRepository(),
            pairContextProvider: FirebasePairContextProvider(),
            year: year,
            categoryId: categoryId
        )
    }

    @MainActor
    static func makeWaitingViewModel(year: Int, categoryId: String) -> TextCategoryWaitingViewModel {
        guard FirebaseApp.app() != nil else {
            return TextCategoryWaitingViewModel(
                repository: UnavailableTextCategoryRepository(),
                pairContextProvider: UnavailablePairContextProvider(),
                year: year,
                categoryId: categoryId
            )
        }

        return TextCategoryWaitingViewModel(
            repository: FirestoreTextCategoryRepository(),
            pairContextProvider: FirebasePairContextProvider(),
            year: year,
            categoryId: categoryId
        )
    }

    @MainActor
    static func makeResultViewModel(year: Int, categoryId: String) -> TextCategoryResultViewModel {
        guard FirebaseApp.app() != nil else {
            return TextCategoryResultViewModel(
                repository: UnavailableTextCategoryRepository(),
                pairContextProvider: UnavailablePairContextProvider(),
                year: year,
                categoryId: categoryId
            )
        }

        return TextCategoryResultViewModel(
            repository: FirestoreTextCategoryRepository(),
            pairContextProvider: FirebasePairContextProvider(),
            year: year,
            categoryId: categoryId
        )
    }
}

private struct UnavailablePairContextProvider: PairContextProviding {
    func currentContext() async throws -> PairContext {
        throw TextCategoryRepositoryError.pairContextUnavailable
    }
}

private final class UnavailableTextCategoryRepository: TextCategoryRepository, @unchecked Sendable {
    func observeCategories(pairId _: String, year _: Int) -> AsyncThrowingStream<[TextCategory], Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: TextCategoryRepositoryError.pairContextUnavailable)
        }
    }

    func createCategory(_: TextCategory) async throws {}
    func updateDraftCategory(_: TextCategory) async throws {}
    func confirmCategory(pairId _: String, year _: Int, categoryId _: String) async throws {}
    func resetCategory(pairId _: String, year _: Int, categoryId _: String) async throws {}

    func observeCandidates(pairId _: String, year _: Int, categoryId _: String) -> AsyncThrowingStream<[TextCandidate], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func addCandidate(_: TextCandidate) async throws {}
    func updateCandidate(_: TextCandidate) async throws {}
    func deleteCandidate(pairId _: String, year _: Int, categoryId _: String, candidateId _: String) async throws {}
    func saveInput(_: TextCategoryInput) async throws {}
    func completeInput(_: TextCategoryInput) async throws {}

    func loadInput(pairId _: String, year _: Int, categoryId _: String, userId _: String) async throws -> TextCategoryInput? {
        nil
    }

    func loadResultContext(pairId _: String, year _: Int, categoryId _: String) async throws -> TextCategoryResultContext {
        throw TextCategoryRepositoryError.pairContextUnavailable
    }

    func saveResultIfNeeded(_: TextCategoryResult) async throws {}
}
