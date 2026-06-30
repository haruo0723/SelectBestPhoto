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

    @Test func resultViewModelDisplaysSavedResultWhenResultAlreadyExists() async {
        let context = makeResultContext()
        let savedResult = makeSavedResult()
        let repository = FakeResultRepository(resultContext: context, existingResult: savedResult)
        let viewModel = await makeResultViewModel(repository: repository)

        await viewModel.load()

        #expect(await viewModel.screenState == .loaded)
        #expect(await viewModel.result == savedResult)
        #expect(await viewModel.displayEntries.map(\.entry.candidateName) == ["保存済み2位", "保存済み1位"])
        #expect(repository.savedResults.isEmpty)
    }

    @Test func resultViewModelDoesNotExposeResultWhenInputsAreIncomplete() async {
        let repository = FakeResultRepository(resultContext: nil, error: TextCategoryRepositoryError.inputsNotCompleted)
        let viewModel = await makeResultViewModel(repository: repository)

        await viewModel.load()

        #expect(await viewModel.screenState == .waitingForPartner)
        #expect(await viewModel.displayEntries.isEmpty)
        #expect(repository.savedResults.isEmpty)
    }

    @Test func cancelingResetConfirmationDoesNotCallRepositoryAndKeepsResult() async {
        let repository = FakeResultRepository(resultContext: makeResultContext())
        let viewModel = await makeResultViewModel(repository: repository)
        await viewModel.load()

        await viewModel.requestResetConfirmation()
        await viewModel.cancelResetConfirmation()

        #expect(repository.resetCalls.isEmpty)
        #expect(await viewModel.isResetConfirmationPresented == false)
        #expect(await viewModel.screenState == .loaded)
        #expect(await viewModel.result != nil)
    }

    @Test func confirmedResetRoutesBackToCandidateManagement() async {
        let repository = FakeResultRepository(resultContext: makeResultContext())
        let viewModel = await makeResultViewModel(repository: repository)
        await viewModel.load()

        await viewModel.requestResetConfirmation()
        await viewModel.confirmReset()

        #expect(repository.resetCalls == [ResetCall(pairId: "pair-1", year: 2026, categoryId: "category-1")])
        #expect(await viewModel.resetDestinationCategoryId == "category-1")
        #expect(await viewModel.resetState == .idle)
        #expect(await viewModel.screenState == .waitingForPartner)
        #expect(await viewModel.result == nil)
        #expect(await viewModel.displayEntries.isEmpty)
    }

    @Test func failedResetKeepsCurrentResultAndShowsRetryableMessage() async {
        let repository = FakeResultRepository(resultContext: makeResultContext(), resetError: TextCategoryRepositoryError.categoryNotFound)
        let viewModel = await makeResultViewModel(repository: repository)
        await viewModel.load()

        await viewModel.requestResetConfirmation()
        await viewModel.confirmReset()

        #expect(repository.resetCalls.count == 1)
        #expect(await viewModel.screenState == .loaded)
        #expect(await viewModel.result != nil)
        #expect(await viewModel.resetDestinationCategoryId == nil)
        #expect(await viewModel.resetState == .failed("リセットできませんでした。現在の状態を再読み込みするか、もう一度お試しください。"))
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

private func makeSavedResult() -> TextCategoryResult {
    TextCategoryResult(
        id: "category-1-generation-0",
        pairId: "pair-1",
        year: 2026,
        categoryId: "category-1",
        generation: 0,
        entries: [
            makeResultEntry(id: "saved-1", rank: 1, name: "保存済み1位", totalPoints: 999),
            makeResultEntry(id: "saved-2", rank: 2, name: "保存済み2位", totalPoints: 998),
        ],
        sourceUserIds: ["user-a", "user-b"],
        createdAt: Date(timeIntervalSince1970: 1_800_000_001)
    )
}

private func makeResultEntry(id: String, rank: Int, name: String, totalPoints: Int) -> TextCategoryResultEntry {
    TextCategoryResultEntry(
        id: id,
        rank: rank,
        candidateId: id,
        candidateName: name,
        totalPoints: totalPoints,
        userBreakdowns: [
            TextCategoryUserPointBreakdown(userId: "user-a", selectedRank: rank, points: totalPoints),
            TextCategoryUserPointBreakdown(userId: "user-b", selectedRank: nil, points: 0),
        ],
        imagePlaceholderKind: .futureImageSlot
    )
}

private struct FixedResultPairContextProvider: PairContextProviding {
    func currentContext() async throws -> PairContext {
        PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
    }
}

private struct ResetCall: Equatable {
    var pairId: String
    var year: Int
    var categoryId: String
}

private final class FakeResultRepository: TextCategoryRepository, @unchecked Sendable {
    let resultContext: TextCategoryResultContext?
    let existingResult: TextCategoryResult?
    let error: Error?
    let resetError: Error?
    private(set) var savedResults: [TextCategoryResult] = []
    private(set) var resetCalls: [ResetCall] = []

    init(
        resultContext: TextCategoryResultContext?,
        existingResult: TextCategoryResult? = nil,
        error: Error? = nil,
        resetError: Error? = nil
    ) {
        self.resultContext = resultContext
        self.existingResult = existingResult
        self.error = error
        self.resetError = resetError
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

    func resetCategory(pairId: String, year: Int, categoryId: String) async throws {
        resetCalls.append(ResetCall(pairId: pairId, year: year, categoryId: categoryId))
        if let resetError {
            throw resetError
        }
    }

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

    func saveResultIfNeeded(_ result: TextCategoryResult) async throws -> TextCategoryResult {
        if let existingResult, existingResult.generation == result.generation {
            return existingResult
        }
        savedResults.append(result)
        return result
    }
}
