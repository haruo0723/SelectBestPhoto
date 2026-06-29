import Foundation
@testable import SelectBestPhoto
import Testing

struct TextCategoryResultViewModelTests {
    @Test func resultViewModelDisplaysRevealEntriesFromLowerRankToHigherRankAndSavesResult() async {
        let context = makeResultContext()
        let repository = FakeResultRepository(resultContext: context)
        let viewModel = await makeResultViewModel(repository: repository)

        await viewModel.load()

        #expect(await viewModel.screenState == .loaded)
        #expect(await viewModel.displayEntries.map(\.entry.rank) == [2, 1])
        #expect(await viewModel.displayEntries.map(\.entry.candidateName) == ["候補2", "候補1"])
        #expect(repository.savedResults.count == 1)
        #expect(repository.savedResults.first?.id == "category-1-generation-0")
    }

    @Test func resultViewModelDoesNotExposeResultWhenInputsAreIncomplete() async {
        let repository = FakeResultRepository(resultContext: nil, error: TextCategoryRepositoryError.inputsNotCompleted)
        let viewModel = await makeResultViewModel(repository: repository)

        await viewModel.load()

        #expect(await viewModel.screenState == .waitingForPartner)
        #expect(await viewModel.displayEntries.isEmpty)
        #expect(repository.savedResults.isEmpty)
    }

    @MainActor
    private func makeResultViewModel(repository: FakeResultRepository) -> TextCategoryResultViewModel {
        TextCategoryResultViewModel(
            repository: repository,
            pairContextProvider: FixedResultPairContextProvider(),
            calculator: TextCategoryResultCalculator(now: { Date(timeIntervalSince1970: 1_800_000_500) }),
            year: 2026,
            categoryId: "category-1"
        )
    }
}

private func makeResultContext() -> TextCategoryResultContext {
    let category = TextCategory(
        id: "category-1",
        pairId: "pair-1",
        year: 2026,
        name: "今年の名言",
        status: .confirmed,
        inputStatuses: ["user-a": .completed, "user-b": .completed],
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
    let candidates = [
        makeResultCandidate(id: "candidate-1", name: "候補1", createdAt: 1_800_000_000),
        makeResultCandidate(id: "candidate-2", name: "候補2", createdAt: 1_800_000_001),
    ]
    let inputs = [
        makeResultInput(userId: "user-a", selections: [
            RankedTextSelection(rank: 1, candidateId: "candidate-1"),
            RankedTextSelection(rank: 2, candidateId: "candidate-2"),
        ]),
        makeResultInput(userId: "user-b", selections: [
            RankedTextSelection(rank: 1, candidateId: "candidate-1"),
            RankedTextSelection(rank: 2, candidateId: "candidate-2"),
        ]),
    ]
    return TextCategoryResultContext(category: category, candidates: candidates, inputs: inputs)
}

private func makeResultCandidate(id: String, name: String, createdAt: TimeInterval) -> TextCandidate {
    TextCandidate(
        id: id,
        pairId: "pair-1",
        year: 2026,
        categoryId: "category-1",
        name: name,
        imagePlaceholderKind: .futureImageSlot,
        createdByUserId: "user-a",
        createdAt: Date(timeIntervalSince1970: createdAt),
        updatedAt: Date(timeIntervalSince1970: createdAt)
    )
}

private func makeResultInput(userId: String, selections: [RankedTextSelection]) -> TextCategoryInput {
    TextCategoryInput(
        id: userId,
        pairId: "pair-1",
        year: 2026,
        categoryId: "category-1",
        userId: userId,
        generation: 0,
        status: .completed,
        selections: selections,
        completedAt: Date(timeIntervalSince1970: 1_800_000_100),
        updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
    )
}

private struct FixedResultPairContextProvider: PairContextProviding {
    func currentContext() async throws -> PairContext {
        PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
    }
}

private final class FakeResultRepository: TextCategoryRepository, @unchecked Sendable {
    let resultContext: TextCategoryResultContext?
    let error: Error?
    private(set) var savedResults: [TextCategoryResult] = []

    init(resultContext: TextCategoryResultContext?, error: Error? = nil) {
        self.resultContext = resultContext
        self.error = error
    }

    func observeCategories(pairId _: String, year _: Int) -> AsyncThrowingStream<[TextCategory], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
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
        if let error {
            throw error
        }
        guard let resultContext else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        return resultContext
    }

    func saveResultIfNeeded(_ result: TextCategoryResult) async throws {
        savedResults.append(result)
    }
}
