import SwiftUI

struct SelectBestPhotoRootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            TextCategoryListView(viewModel: TextCategoryDemoDependencies.makeListViewModel())
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

private enum TextCategoryDemoDependencies {
    @MainActor
    static func makeListViewModel() -> TextCategoryListViewModel {
        TextCategoryListViewModel(
            repository: InMemoryTextCategoryRepository(categories: demoCategories),
            pairContextProvider: StaticPairContextProvider(context: PairContext(pairId: "demo-pair", userId: "user-a")),
            initialYear: 2026,
            currentUserId: "user-a",
            partnerUserId: "user-b",
            inputStatuses: [
                "category-confirmed": TextCategoryInputStatusPair(own: .inProgress, partner: .notStarted),
                "category-waiting": TextCategoryInputStatusPair(own: .completed, partner: .inProgress),
                "category-result": TextCategoryInputStatusPair(own: .completed, partner: .completed),
            ]
        )
    }

    private static var demoCategories: [TextCategory] {
        [
            makeCategory(
                id: "category-draft",
                name: "今年の名言",
                status: .draft,
                updatedAtOffset: 300
            ),
            makeCategory(
                id: "category-confirmed",
                name: "行ってよかった場所",
                status: .confirmed,
                updatedAtOffset: 200
            ),
            makeCategory(
                id: "category-waiting",
                name: "また食べたいもの",
                status: .confirmed,
                updatedAtOffset: 100
            ),
            makeCategory(
                id: "category-result",
                name: "今年いちばん笑ったこと",
                status: .resultAvailable,
                updatedAtOffset: 0
            ),
        ]
    }

    private static func makeCategory(
        id: String,
        name: String,
        status: TextCategoryStatus,
        updatedAtOffset: TimeInterval
    ) -> TextCategory {
        TextCategory(
            id: id,
            pairId: "demo-pair",
            year: 2026,
            name: name,
            status: status,
            settings: TextCategorySettings(
                inputRankLimit: 3,
                revealRankLimit: 2,
                pointsByRank: [
                    RankPoint(rank: 1, points: 10),
                    RankPoint(rank: 2, points: 5),
                    RankPoint(rank: 3, points: 1),
                ]
            ),
            generation: 0,
            createdByUserId: "user-a",
            confirmedAt: status == .draft ? nil : Date(timeIntervalSince1970: 1_800_000_000),
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000 + updatedAtOffset)
        )
    }
}

private struct StaticPairContextProvider: PairContextProviding {
    let context: PairContext

    func currentContext() async throws -> PairContext {
        context
    }
}

private final class InMemoryTextCategoryRepository: TextCategoryRepository, @unchecked Sendable {
    private let categories: [TextCategory]

    init(categories: [TextCategory]) {
        self.categories = categories
    }

    func observeCategories(pairId: String, year: Int) -> AsyncThrowingStream<[TextCategory], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(categories.filter { $0.pairId == pairId && $0.year == year })
            continuation.finish()
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

    func loadResultContext(pairId _: String, year _: Int, categoryId _: String) async throws -> TextCategoryResultContext {
        guard let category = categories.first else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        return TextCategoryResultContext(category: category, candidates: [], inputs: [])
    }

    func saveResultIfNeeded(_: TextCategoryResult) async throws {}
}
