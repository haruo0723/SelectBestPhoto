import Foundation
@testable import SelectBestPhoto
import Testing

struct TextCategoryListViewModelTests {
    @Test func routeForDraftCategoryOpensCandidateManagement() {
        let category = makeCategory(status: .draft)
        let state = TextCategoryListRowState(category: category, ownInputStatus: .notStarted, partnerInputStatus: .notStarted)

        #expect(state.route == .candidateManagement(category.id))
        #expect(state.statusText == "準備中")
        #expect(state.resultAvailabilityText == "結果は未公開")
    }

    @Test func routeForConfirmedCategoryWithOwnInputNotCompletedOpensRankingInput() {
        let category = makeCategory(status: .confirmed)
        let state = TextCategoryListRowState(category: category, ownInputStatus: .inProgress, partnerInputStatus: .completed)

        #expect(state.route == .rankingInput(category.id))
        #expect(state.ownInputText == "自分: 入力中")
        #expect(state.partnerInputText == "相手: 完了")
    }

    @Test func routeForOwnCompletedAndPartnerNotCompletedOpensWaiting() {
        let category = makeCategory(status: .confirmed)
        let state = TextCategoryListRowState(category: category, ownInputStatus: .completed, partnerInputStatus: .inProgress)

        #expect(state.route == .waiting(category.id))
        #expect(state.resultAvailabilityText == "結果は未公開")
    }

    @Test func routeForBothCompletedOpensResult() {
        let category = makeCategory(status: .confirmed)
        let state = TextCategoryListRowState(category: category, ownInputStatus: .completed, partnerInputStatus: .completed)

        #expect(state.route == .result(category.id))
        #expect(state.resultAvailabilityText == "結果を表示できます")
    }

    @Test func viewModelBuildsRowsAndEmptyStateFromObservedCategories() async {
        let repository = FakeListRepository(categories: [
            makeCategory(
                id: "category-a",
                name: "今年の名言",
                status: .draft,
                updatedAt: Date(timeIntervalSince1970: 1_800_000_200)
            ),
            makeCategory(
                id: "category-b",
                name: "行ってよかった場所",
                status: .confirmed,
                updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
            ),
        ])
        let contextProvider = FixedListPairContextProvider(
            context: PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
        )
        let viewModel = await TextCategoryListViewModel(
            repository: repository,
            pairContextProvider: contextProvider,
            initialYear: 2026,
            inputStatuses: [
                "category-b": TextCategoryInputStatusPair(own: .completed, partner: .completed),
            ]
        )

        await viewModel.load()

        let rows = await waitForRows(viewModel, expectedCount: 2)
        #expect(await viewModel.screenState == .loaded)
        #expect(rows.count == 2)
        guard rows.count == 2 else {
            return
        }
        #expect(rows.map(\.category.name) == ["今年の名言", "行ってよかった場所"])
        #expect(rows[0].route == .candidateManagement("category-a"))
        #expect(rows[1].route == .result("category-b"))
    }

    @Test func viewModelMarksEmptyWhenObservedCategoryListIsEmpty() async {
        let repository = FakeListRepository(categories: [])
        let contextProvider = FixedListPairContextProvider(
            context: PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
        )
        let viewModel = await TextCategoryListViewModel(
            repository: repository,
            pairContextProvider: contextProvider,
            initialYear: 2026
        )

        await viewModel.load()

        await waitForState(viewModel, expectedState: .empty)
        #expect(await viewModel.screenState == .empty)
        #expect(await viewModel.rows.isEmpty)
    }

    @Test func viewModelBuildsRowsFromCategoryInputStatusSummary() async {
        let repository = FakeListRepository(
            categories: [
                makeCategory(
                    id: "category-a",
                    name: "行ってよかった場所",
                    status: .confirmed,
                    inputStatuses: [
                        "user-a": .completed,
                        "user-b": .inProgress,
                    ]
                ),
            ]
        )
        let contextProvider = FixedListPairContextProvider(
            context: PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
        )
        let viewModel = await TextCategoryListViewModel(
            repository: repository,
            pairContextProvider: contextProvider,
            initialYear: 2026
        )

        await viewModel.load()

        let rows = await waitForRows(viewModel, expectedCount: 1)
        await waitForRoute(viewModel, expectedRoute: .waiting("category-a"))
        #expect(rows.first?.ownInputStatus == .completed)
        #expect(rows.first?.partnerInputStatus == .inProgress)
        #expect(await viewModel.rows.first?.route == .waiting("category-a"))
    }

    private func makeCategory(
        id: String = "category-1",
        name: String = "今年の名言",
        status: TextCategoryStatus,
        inputStatuses: [String: InputStatus] = [:],
        updatedAt: Date = Date(timeIntervalSince1970: 1_800_000_100)
    ) -> TextCategory {
        TextCategory(
            id: id,
            pairId: "pair-1",
            year: 2026,
            name: name,
            status: status,
            inputStatuses: inputStatuses,
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
            updatedAt: updatedAt
        )
    }

    private func waitForRows(
        _ viewModel: TextCategoryListViewModel,
        expectedCount: Int,
        maxAttempts: Int = 100
    ) async -> [TextCategoryListRowState] {
        for _ in 0 ..< maxAttempts {
            let rows = await viewModel.rows
            if rows.count == expectedCount {
                return rows
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return await viewModel.rows
    }

    private func waitForState(
        _ viewModel: TextCategoryListViewModel,
        expectedState: TextCategoryListScreenState,
        maxAttempts: Int = 100
    ) async {
        for _ in 0 ..< maxAttempts {
            if await viewModel.screenState == expectedState {
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    private func waitForRoute(
        _ viewModel: TextCategoryListViewModel,
        expectedRoute: TextCategoryListRoute,
        maxAttempts: Int = 100
    ) async {
        for _ in 0 ..< maxAttempts {
            if await viewModel.rows.first?.route == expectedRoute {
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}

private struct FixedListPairContextProvider: PairContextProviding {
    let context: PairContext

    func currentContext() async throws -> PairContext {
        context
    }
}

private final class FakeListRepository: TextCategoryRepository, @unchecked Sendable {
    let categories: [TextCategory]

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

    func loadInput(pairId _: String, year _: Int, categoryId _: String, userId _: String) async throws -> TextCategoryInput? {
        nil
    }

    func loadResultContext(pairId _: String, year _: Int, categoryId _: String) async throws -> TextCategoryResultContext {
        TextCategoryResultContext(category: categories[0], candidates: [], inputs: [])
    }

    func saveResultIfNeeded(_ result: TextCategoryResult) async throws -> TextCategoryResult {
        result
    }
}
