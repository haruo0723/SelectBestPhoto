import Foundation
@testable import SelectBestPhoto
import Testing

struct TextCategoryWaitingViewModelTests {
    @Test func waitingScreenShowsOnlyInputStatusesBeforePartnerCompletes() async {
        let repository = FakeWaitingRepository(
            categories: [makeWaitingCategory(ownStatus: .completed, partnerStatus: .inProgress)]
        )
        let viewModel = await makeWaitingViewModel(repository: repository)

        await viewModel.load()
        await waitForWaitingState(viewModel, expectedState: .waiting)

        #expect(await viewModel.statusItems == [
            TextCategoryWaitingStatusItem(id: "own", title: "自分", status: .completed),
            TextCategoryWaitingStatusItem(id: "partner", title: "相手", status: .inProgress),
        ])
        #expect(repository.loadInputCallCount == 0)
        #expect(repository.loadResultContextCallCount == 0)
        #expect(await viewModel.canShowResult == false)
    }

    @Test func waitingScreenCanRouteToResultAfterBothUsersComplete() async {
        let repository = FakeWaitingRepository(
            categories: [makeWaitingCategory(ownStatus: .completed, partnerStatus: .completed)]
        )
        let viewModel = await makeWaitingViewModel(repository: repository)

        await viewModel.load()
        await waitForWaitingState(viewModel, expectedState: .resultAvailable)
        await viewModel.showResult()

        #expect(await viewModel.resultCategoryId == "category-1")
    }

    @MainActor
    private func makeWaitingViewModel(repository: FakeWaitingRepository) -> TextCategoryWaitingViewModel {
        TextCategoryWaitingViewModel(
            repository: repository,
            pairContextProvider: FixedWaitingPairContextProvider(),
            year: 2026,
            categoryId: "category-1"
        )
    }
}

private func waitForWaitingState(
    _ viewModel: TextCategoryWaitingViewModel,
    expectedState: TextCategoryWaitingScreenState,
    maxAttempts: Int = 100
) async {
    for _ in 0 ..< maxAttempts {
        if await viewModel.screenState == expectedState {
            return
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
}

private func makeWaitingCategory(
    ownStatus: InputStatus,
    partnerStatus: InputStatus,
    status: TextCategoryStatus = .confirmed
) -> TextCategory {
    TextCategory(
        id: "category-1",
        pairId: "pair-1",
        year: 2026,
        name: "今年の名言",
        status: status,
        inputStatuses: ["user-a": ownStatus, "user-b": partnerStatus],
        settings: TextCategorySettings(
            inputRankLimit: 2,
            revealRankLimit: 2,
            pointsByRank: [RankPoint(rank: 1, points: 10), RankPoint(rank: 2, points: 5)]
        ),
        generation: 0,
        createdByUserId: "user-a",
        confirmedAt: Date(timeIntervalSince1970: 1_800_000_000),
        createdAt: Date(timeIntervalSince1970: 1_799_999_900),
        updatedAt: Date(timeIntervalSince1970: 1_799_999_950)
    )
}

private struct FixedWaitingPairContextProvider: PairContextProviding {
    func currentContext() async throws -> PairContext {
        PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
    }
}

private final class FakeWaitingRepository: TextCategoryRepository, @unchecked Sendable {
    let categories: [TextCategory]
    private(set) var loadInputCallCount = 0
    private(set) var loadResultContextCallCount = 0

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
        loadInputCallCount += 1
        return nil
    }

    func loadResultContext(pairId _: String, year _: Int, categoryId _: String) async throws -> TextCategoryResultContext {
        loadResultContextCallCount += 1
        throw TextCategoryRepositoryError.inputsNotCompleted
    }

    func saveResultIfNeeded(_ result: TextCategoryResult) async throws -> TextCategoryResult {
        result
    }
}
