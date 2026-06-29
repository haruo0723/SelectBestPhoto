import Foundation
@testable import SelectBestPhoto
import Testing

struct TextRankingInputViewModelTests {
    @Test func selectingSameCandidateForAnotherRankMovesSelection() async {
        let repository = FakeRankingInputRepository(
            categories: [makeRankingCategory(inputRankLimit: 2)],
            candidates: [
                makeRankingCandidate(id: "candidate-1", name: "候補1"),
                makeRankingCandidate(id: "candidate-2", name: "候補2"),
            ]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRankingState(viewModel, expectedState: .loaded)

        await viewModel.selectCandidate("candidate-1", forRank: 1)
        await viewModel.selectCandidate("candidate-1", forRank: 2)

        #expect(await viewModel.selectionsByRank == [2: "candidate-1"])
        #expect(repository.savedInputs.last?.selections == [RankedTextSelection(rank: 2, candidateId: "candidate-1")])
        #expect(await viewModel.canComplete == false)
    }

    @Test func savedDraftSelectionsAreRestoredWhenInputLoads() async {
        let repository = FakeRankingInputRepository(
            categories: [makeRankingCategory(inputRankLimit: 2, ownStatus: .inProgress)],
            candidates: [
                makeRankingCandidate(id: "candidate-1", name: "候補1"),
                makeRankingCandidate(id: "candidate-2", name: "候補2"),
            ],
            loadedInput: makeRankingInput(
                status: .inProgress,
                selections: [
                    RankedTextSelection(rank: 1, candidateId: "candidate-2"),
                    RankedTextSelection(rank: 2, candidateId: "candidate-1"),
                ]
            )
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRankingState(viewModel, expectedState: .loaded)

        #expect(await viewModel.selectionsByRank == [1: "candidate-2", 2: "candidate-1"])
        #expect(await viewModel.canComplete == true)
    }

    @Test func completedInputCannotBeEditedBackToDraft() async {
        let repository = FakeRankingInputRepository(
            categories: [makeRankingCategory(inputRankLimit: 1, ownStatus: .completed)],
            candidates: [makeRankingCandidate(id: "candidate-1", name: "候補1")],
            loadedInput: makeRankingInput(
                status: .completed,
                selections: [RankedTextSelection(rank: 1, candidateId: "candidate-1")]
            )
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRankingState(viewModel, expectedState: .loaded)

        await viewModel.clearSelection(forRank: 1)
        await viewModel.selectCandidate("candidate-1", forRank: 1)
        await viewModel.completeInput()

        #expect(await viewModel.selectionsByRank == [1: "candidate-1"])
        #expect(repository.savedInputs.isEmpty)
        #expect(repository.completedInputs.isEmpty)
        #expect(await viewModel.canComplete == false)
    }

    @Test func inputCannotCompleteUntilAllRanksAreSelected() async {
        let repository = FakeRankingInputRepository(
            categories: [makeRankingCategory(inputRankLimit: 2)],
            candidates: [
                makeRankingCandidate(id: "candidate-1", name: "候補1"),
                makeRankingCandidate(id: "candidate-2", name: "候補2"),
            ]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRankingState(viewModel, expectedState: .loaded)

        await viewModel.selectCandidate("candidate-1", forRank: 1)
        await viewModel.completeInput()

        #expect(repository.completedInputs.isEmpty)
        #expect(await viewModel.validationMessages == ["すべての順位に候補を選んでください。"])
    }

    @Test func completingInputSavesCompletedInputAndRoutesToWaitingWhenPartnerIncomplete() async {
        let repository = FakeRankingInputRepository(
            categories: [makeRankingCategory(inputRankLimit: 2, partnerStatus: .inProgress)],
            candidates: [
                makeRankingCandidate(id: "candidate-1", name: "候補1"),
                makeRankingCandidate(id: "candidate-2", name: "候補2"),
            ]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRankingState(viewModel, expectedState: .loaded)

        await viewModel.selectCandidate("candidate-1", forRank: 1)
        await viewModel.selectCandidate("candidate-2", forRank: 2)
        await viewModel.completeInput()

        let completedInput = repository.completedInputs.last
        #expect(completedInput?.id == "user-a")
        #expect(completedInput?.status == .completed)
        #expect(completedInput?.selections == [
            RankedTextSelection(rank: 1, candidateId: "candidate-1"),
            RankedTextSelection(rank: 2, candidateId: "candidate-2"),
        ])
        #expect(await viewModel.completionDestination == .waiting("category-1"))
    }

    @Test func completingInputRoutesToResultWhenPartnerCompleted() async {
        let repository = FakeRankingInputRepository(
            categories: [makeRankingCategory(inputRankLimit: 1, partnerStatus: .completed)],
            candidates: [makeRankingCandidate(id: "candidate-1", name: "候補1")]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRankingState(viewModel, expectedState: .loaded)

        await viewModel.selectCandidate("candidate-1", forRank: 1)
        await viewModel.completeInput()

        #expect(await viewModel.completionDestination == .result("category-1"))
    }

    @Test func draftCategoryCannotBeEditedFromRankingInput() async {
        let repository = FakeRankingInputRepository(
            categories: [makeRankingCategory(inputRankLimit: 1, status: .draft)],
            candidates: [makeRankingCandidate(id: "candidate-1", name: "候補1")]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()

        await waitForRankingState(viewModel, expectedState: .error("候補と設定が確定されていません。"))

        #expect(await viewModel.canComplete == false)
        #expect(repository.savedInputs.isEmpty)
    }

    @MainActor
    private func makeViewModel(repository: FakeRankingInputRepository) -> TextRankingInputViewModel {
        TextRankingInputViewModel(
            repository: repository,
            pairContextProvider: FixedRankingInputPairContextProvider(),
            year: 2026,
            categoryId: "category-1",
            now: { Date(timeIntervalSince1970: 1_800_000_000) }
        )
    }
}

private func makeRankingCategory(
    inputRankLimit: Int,
    status: TextCategoryStatus = .confirmed,
    ownStatus: InputStatus = .notStarted,
    partnerStatus: InputStatus = .notStarted
) -> TextCategory {
    TextCategory(
        id: "category-1",
        pairId: "pair-1",
        year: 2026,
        name: "今年の名言",
        status: status,
        inputStatuses: ["user-a": ownStatus, "user-b": partnerStatus],
        settings: TextCategorySettings(
            inputRankLimit: inputRankLimit,
            revealRankLimit: min(inputRankLimit, 2),
            pointsByRank: (1 ... inputRankLimit).map { RankPoint(rank: $0, points: 11 - $0) }
        ),
        generation: 0,
        createdByUserId: "user-a",
        confirmedAt: status == .draft ? nil : Date(timeIntervalSince1970: 1_800_000_000),
        createdAt: Date(timeIntervalSince1970: 1_799_999_900),
        updatedAt: Date(timeIntervalSince1970: 1_799_999_950)
    )
}

private func makeRankingInput(
    status: InputStatus,
    selections: [RankedTextSelection]
) -> TextCategoryInput {
    TextCategoryInput(
        id: "user-a",
        pairId: "pair-1",
        year: 2026,
        categoryId: "category-1",
        userId: "user-a",
        generation: 0,
        status: status,
        selections: selections,
        completedAt: status == .completed ? Date(timeIntervalSince1970: 1_800_000_000) : nil,
        updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
}

private func makeRankingCandidate(id: String, name: String) -> TextCandidate {
    TextCandidate(
        id: id,
        pairId: "pair-1",
        year: 2026,
        categoryId: "category-1",
        name: name,
        imagePlaceholderKind: .futureImageSlot,
        createdByUserId: "user-a",
        createdAt: Date(timeIntervalSince1970: 1_800_000_000 + Double(abs(id.hashValue % 100))),
        updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
    )
}

private func waitForRankingState(
    _ viewModel: TextRankingInputViewModel,
    expectedState: TextRankingInputScreenState,
    maxAttempts: Int = 100
) async {
    for _ in 0 ..< maxAttempts {
        if await viewModel.screenState == expectedState {
            return
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
}

private struct FixedRankingInputPairContextProvider: PairContextProviding {
    func currentContext() async throws -> PairContext {
        PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
    }
}

private final class FakeRankingInputRepository: TextCategoryRepository, @unchecked Sendable {
    let categories: [TextCategory]
    let candidates: [TextCandidate]
    let loadedInput: TextCategoryInput?
    private(set) var savedInputs: [TextCategoryInput] = []
    private(set) var completedInputs: [TextCategoryInput] = []

    init(categories: [TextCategory], candidates: [TextCandidate], loadedInput: TextCategoryInput? = nil) {
        self.categories = categories
        self.candidates = candidates
        self.loadedInput = loadedInput
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

    func observeCandidates(pairId: String, year: Int, categoryId: String) -> AsyncThrowingStream<[TextCandidate], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(
                candidates.filter {
                    $0.pairId == pairId && $0.year == year && $0.categoryId == categoryId
                }
            )
            continuation.finish()
        }
    }

    func addCandidate(_: TextCandidate) async throws {}
    func updateCandidate(_: TextCandidate) async throws {}
    func deleteCandidate(pairId _: String, year _: Int, categoryId _: String, candidateId _: String) async throws {}

    func saveInput(_ input: TextCategoryInput) async throws {
        savedInputs.append(input)
    }

    func completeInput(_ input: TextCategoryInput) async throws {
        completedInputs.append(input)
    }

    func loadInput(pairId: String, year: Int, categoryId: String, userId: String) async throws -> TextCategoryInput? {
        guard loadedInput?.pairId == pairId,
              loadedInput?.year == year,
              loadedInput?.categoryId == categoryId,
              loadedInput?.userId == userId
        else {
            return nil
        }
        return loadedInput
    }

    func loadResultContext(pairId _: String, year _: Int, categoryId _: String) async throws -> TextCategoryResultContext {
        TextCategoryResultContext(category: categories[0], candidates: candidates, inputs: completedInputs)
    }

    func saveResultIfNeeded(_: TextCategoryResult) async throws {}
}
