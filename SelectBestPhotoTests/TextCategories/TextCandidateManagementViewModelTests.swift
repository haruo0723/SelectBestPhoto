import Foundation
@testable import SelectBestPhoto
import Testing

struct TextCandidateManagementViewModelTests {
    @Test func addCandidateCreatesFutureImagePlaceholderCandidateAndClearsInput() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2)],
            candidates: []
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForState(viewModel, expectedState: .loaded)
        await MainActor.run {
            viewModel.newCandidateName = "  今年の名言  "
        }

        await viewModel.addCandidate()

        let addedCandidate = repository.addedCandidates.first
        #expect(addedCandidate?.id == "candidate-new")
        #expect(addedCandidate?.pairId == "pair-1")
        #expect(addedCandidate?.year == 2026)
        #expect(addedCandidate?.categoryId == "category-1")
        #expect(addedCandidate?.name == "今年の名言")
        #expect(addedCandidate?.imagePlaceholderKind == .futureImageSlot)
        #expect(addedCandidate?.createdByUserId == "user-a")
        #expect(await viewModel.newCandidateName == "")
    }

    @Test func blankCandidateNameIsRejectedAndInputIsKept() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2)],
            candidates: []
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForState(viewModel, expectedState: .loaded)
        await MainActor.run {
            viewModel.newCandidateName = "   "
        }

        await viewModel.addCandidate()

        #expect(repository.addedCandidates.isEmpty)
        #expect(await viewModel.newCandidateName == "   ")
        #expect(await viewModel.validationMessages == ["候補名を入力してください。"])
    }

    @Test func duplicateCandidateNamesAreAllowedAsSeparateCandidates() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2)],
            candidates: [makeCandidate(id: "candidate-existing", name: "同じ名前")]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForState(viewModel, expectedState: .loaded)
        await MainActor.run {
            viewModel.newCandidateName = "同じ名前"
        }

        await viewModel.addCandidate()

        #expect(repository.addedCandidates.map(\.name) == ["同じ名前"])
    }

    @Test func editCandidateNameUpdatesRepositoryCandidate() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2)],
            candidates: [makeCandidate(id: "candidate-1", name: "変更前")]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRows(viewModel, expectedCount: 1)

        await MainActor.run {
            viewModel.updateDraftName("変更後", forCandidateId: "candidate-1")
        }
        await viewModel.saveCandidateName(candidateId: "candidate-1")

        #expect(repository.updatedCandidates.first?.id == "candidate-1")
        #expect(repository.updatedCandidates.first?.name == "変更後")
    }

    @Test func deleteCandidateCallsRepositoryWithCurrentPairContext() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2)],
            candidates: [makeCandidate(id: "candidate-1", name: "候補1")]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRows(viewModel, expectedCount: 1)

        await viewModel.deleteCandidate(candidateId: "candidate-1")

        #expect(repository.deletedCandidateIds == ["candidate-1"])
    }

    @Test func insufficientCandidatesCannotBeConfirmed() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2)],
            candidates: [makeCandidate(id: "candidate-1", name: "候補1")]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRows(viewModel, expectedCount: 1)

        await viewModel.confirmCategory()

        #expect(repository.confirmedCategoryIds.isEmpty)
        #expect(await viewModel.canConfirm == false)
        #expect(await viewModel.validationMessages == ["候補数が入力対象順位に足りません。"])
    }

    @Test func enoughCandidatesCanConfirmCategoryAndMoveToRankingInput() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2)],
            candidates: [
                makeCandidate(id: "candidate-1", name: "候補1"),
                makeCandidate(id: "candidate-2", name: "候補2"),
            ]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRows(viewModel, expectedCount: 2)

        await viewModel.confirmCategory()

        #expect(repository.confirmedCategoryIds == ["category-1"])
        #expect(await viewModel.confirmedCategoryId == "category-1")
    }

    @Test func clearingConfirmedCategoryNavigationRemovesDestinationState() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2)],
            candidates: [
                makeCandidate(id: "candidate-1", name: "候補1"),
                makeCandidate(id: "candidate-2", name: "候補2"),
            ]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRows(viewModel, expectedCount: 2)
        await viewModel.confirmCategory()

        await MainActor.run {
            viewModel.clearConfirmedCategoryNavigation()
        }

        #expect(await viewModel.confirmedCategoryId == nil)
    }

    @Test func loadRestartsCandidateObservationAfterReload() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2)],
            candidateBatches: [
                [],
                [makeCandidate(id: "candidate-1", name: "候補1")],
            ]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForState(viewModel, expectedState: .loaded)

        await viewModel.load()
        await waitForRows(viewModel, expectedCount: 1)

        #expect(repository.observeCandidatesCallCount == 2)
        #expect(await viewModel.screenState == .loaded)
    }

    @Test func confirmedCategoryDisablesCandidateMutation() async {
        let repository = FakeCandidateManagementRepository(
            categories: [makeCategory(inputRankLimit: 2, status: .confirmed)],
            candidates: [
                makeCandidate(id: "candidate-1", name: "候補1"),
                makeCandidate(id: "candidate-2", name: "候補2"),
            ]
        )
        let viewModel = await makeViewModel(repository: repository)
        await viewModel.load()
        await waitForRows(viewModel, expectedCount: 2)
        await MainActor.run {
            viewModel.newCandidateName = "候補3"
        }

        await viewModel.addCandidate()
        await viewModel.saveCandidateName(candidateId: "candidate-1")
        await viewModel.deleteCandidate(candidateId: "candidate-1")

        #expect(repository.addedCandidates.isEmpty)
        #expect(repository.updatedCandidates.isEmpty)
        #expect(repository.deletedCandidateIds.isEmpty)
        #expect(await viewModel.isEditable == false)
        #expect(await viewModel.validationMessages == ["確定済み部門の候補は変更できません。"])
    }

    @MainActor
    private func makeViewModel(repository: FakeCandidateManagementRepository) -> TextCandidateManagementViewModel {
        TextCandidateManagementViewModel(
            repository: repository,
            pairContextProvider: FixedCandidateManagementPairContextProvider(),
            year: 2026,
            categoryId: "category-1",
            now: { Date(timeIntervalSince1970: 1_800_000_000) },
            makeCandidateId: { "candidate-new" }
        )
    }
}

private func makeCategory(
    inputRankLimit: Int,
    status: TextCategoryStatus = .draft
) -> TextCategory {
    TextCategory(
        id: "category-1",
        pairId: "pair-1",
        year: 2026,
        name: "今年の名言",
        status: status,
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

private func makeCandidate(id: String, name: String) -> TextCandidate {
    TextCandidate(
        id: id,
        pairId: "pair-1",
        year: 2026,
        categoryId: "category-1",
        name: name,
        imagePlaceholderKind: .futureImageSlot,
        createdByUserId: "user-a",
        createdAt: Date(timeIntervalSince1970: 1_800_000_000 + Double(id.hashValue % 100)),
        updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
    )
}

private func waitForRows(
    _ viewModel: TextCandidateManagementViewModel,
    expectedCount: Int,
    maxAttempts: Int = 100
) async {
    for _ in 0 ..< maxAttempts {
        if await viewModel.rows.count == expectedCount {
            return
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
}

private func waitForState(
    _ viewModel: TextCandidateManagementViewModel,
    expectedState: TextCandidateManagementScreenState,
    maxAttempts: Int = 100
) async {
    for _ in 0 ..< maxAttempts {
        if await viewModel.screenState == expectedState {
            return
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
}

private struct FixedCandidateManagementPairContextProvider: PairContextProviding {
    func currentContext() async throws -> PairContext {
        PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
    }
}

private final class FakeCandidateManagementRepository: TextCategoryRepository, @unchecked Sendable {
    let categories: [TextCategory]
    private let candidateBatches: [[TextCandidate]]
    private(set) var addedCandidates: [TextCandidate] = []
    private(set) var updatedCandidates: [TextCandidate] = []
    private(set) var deletedCandidateIds: [String] = []
    private(set) var confirmedCategoryIds: [String] = []
    private(set) var observeCandidatesCallCount = 0

    convenience init(categories: [TextCategory], candidates: [TextCandidate]) {
        self.init(categories: categories, candidateBatches: [candidates])
    }

    init(categories: [TextCategory], candidateBatches: [[TextCandidate]]) {
        self.categories = categories
        self.candidateBatches = candidateBatches.isEmpty ? [[]] : candidateBatches
    }

    func observeCategories(pairId: String, year: Int) -> AsyncThrowingStream<[TextCategory], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(categories.filter { $0.pairId == pairId && $0.year == year })
            continuation.finish()
        }
    }

    func createCategory(_: TextCategory) async throws {}
    func updateDraftCategory(_: TextCategory) async throws {}

    func confirmCategory(pairId _: String, year _: Int, categoryId: String) async throws {
        confirmedCategoryIds.append(categoryId)
    }

    func resetCategory(pairId _: String, year _: Int, categoryId _: String) async throws {}

    func observeCandidates(pairId: String, year: Int, categoryId: String) -> AsyncThrowingStream<[TextCandidate], Error> {
        let batchIndex = min(observeCandidatesCallCount, candidateBatches.count - 1)
        observeCandidatesCallCount += 1
        let candidates = candidateBatches[batchIndex]
        return AsyncThrowingStream { continuation in
            continuation.yield(
                candidates.filter {
                    $0.pairId == pairId && $0.year == year && $0.categoryId == categoryId
                }
            )
            continuation.finish()
        }
    }

    func addCandidate(_ candidate: TextCandidate) async throws {
        addedCandidates.append(candidate)
    }

    func updateCandidate(_ candidate: TextCandidate) async throws {
        updatedCandidates.append(candidate)
    }

    func deleteCandidate(pairId _: String, year _: Int, categoryId _: String, candidateId: String) async throws {
        deletedCandidateIds.append(candidateId)
    }

    func saveInput(_: TextCategoryInput) async throws {}
    func completeInput(_: TextCategoryInput) async throws {}

    func loadInput(pairId _: String, year _: Int, categoryId _: String, userId _: String) async throws -> TextCategoryInput? {
        nil
    }

    func loadResultContext(pairId _: String, year _: Int, categoryId _: String) async throws -> TextCategoryResultContext {
        TextCategoryResultContext(category: categories[0], candidates: candidateBatches.last ?? [], inputs: [])
    }

    func saveResultIfNeeded(_: TextCategoryResult) async throws {}
}
