import Foundation
@testable import SelectBestPhoto
import Testing

struct TextCategoryMVPFlowIntegrationTests {
    @Test func mainMVPFlowCreatesRanksRevealsResultAndResetsForReEntry() async {
        let repository = InMemoryMVPFlowRepository()
        let userAProvider = FixedMVPFlowPairContextProvider(userId: "user-a")
        let userBProvider = FixedMVPFlowPairContextProvider(userId: "user-b")

        await createAndConfirmMVPFlowCategory(repository: repository, pairContextProvider: userAProvider)
        await completeMVPFlowInput(
            repository: repository,
            pairContextProvider: userAProvider,
            firstCandidateId: "candidate-1",
            secondCandidateId: "candidate-2",
            expectedDestination: .waiting("category-1")
        )
        await assertMVPFlowWaitsForPartner(repository: repository, pairContextProvider: userAProvider)
        await completeMVPFlowInput(
            repository: repository,
            pairContextProvider: userBProvider,
            firstCandidateId: "candidate-2",
            secondCandidateId: "candidate-1",
            expectedDestination: .result("category-1")
        )
        await assertMVPFlowResultAndReset(repository: repository, pairContextProvider: userAProvider)
        await assertMVPFlowCanReEnterAfterReset(repository: repository, pairContextProvider: userAProvider)
    }
}

private func createAndConfirmMVPFlowCategory(
    repository: InMemoryMVPFlowRepository,
    pairContextProvider: FixedMVPFlowPairContextProvider
) async {
    let settingsViewModel = await TextCategorySettingsViewModel(
        repository: repository,
        pairContextProvider: pairContextProvider,
        year: 2026,
        now: { Date(timeIntervalSince1970: 1_800_000_000) },
        makeCategoryId: { "category-1" }
    )
    await MainActor.run {
        settingsViewModel.draft.name = "今年の名言"
        settingsViewModel.setInputRankLimit(2)
        settingsViewModel.setRevealRankLimit(2)
        settingsViewModel.setPoints(10, forRank: 1)
        settingsViewModel.setPoints(5, forRank: 2)
    }
    await settingsViewModel.saveDraft()

    #expect(await settingsViewModel.saveState == .saved(categoryId: "category-1"))
    #expect(repository.category?.status == .draft)

    let candidateViewModel = await TextCandidateManagementViewModel(
        repository: repository,
        pairContextProvider: pairContextProvider,
        year: 2026,
        categoryId: "category-1",
        now: { Date(timeIntervalSince1970: 1_800_000_100) },
        makeCandidateId: repository.nextCandidateId
    )
    await candidateViewModel.load()
    await waitForMVPFlowCandidates(candidateViewModel, expectedCount: 0)

    await MainActor.run {
        candidateViewModel.newCandidateName = "初日の出を見に行った"
    }
    await candidateViewModel.addCandidate()
    await MainActor.run {
        candidateViewModel.newCandidateName = "深夜に食べたラーメン"
    }
    await candidateViewModel.addCandidate()
    await candidateViewModel.load()
    await waitForMVPFlowCandidates(candidateViewModel, expectedCount: 2)

    await candidateViewModel.confirmCategory()

    #expect(await candidateViewModel.confirmedCategoryId == "category-1")
    #expect(repository.category?.status == .confirmed)
}

private func completeMVPFlowInput(
    repository: InMemoryMVPFlowRepository,
    pairContextProvider: FixedMVPFlowPairContextProvider,
    firstCandidateId: String,
    secondCandidateId: String,
    expectedDestination: TextRankingInputCompletionDestination
) async {
    let viewModel = await makeMVPFlowRankingViewModel(
        repository: repository,
        pairContextProvider: pairContextProvider
    )
    await viewModel.load()
    await waitForMVPFlowRankingState(viewModel, expectedState: .loaded)

    await viewModel.selectCandidate(firstCandidateId, forRank: 1)
    await viewModel.selectCandidate(secondCandidateId, forRank: 2)
    await viewModel.completeInput()

    #expect(await viewModel.completionDestination == expectedDestination)
}

private func assertMVPFlowWaitsForPartner(
    repository: InMemoryMVPFlowRepository,
    pairContextProvider: FixedMVPFlowPairContextProvider
) async {
    let viewModel = await makeMVPFlowResultViewModel(
        repository: repository,
        pairContextProvider: pairContextProvider
    )
    await viewModel.load()

    #expect(await viewModel.screenState == .waitingForPartner)
    #expect(await viewModel.displayEntries.isEmpty)
}

private func assertMVPFlowResultAndReset(
    repository: InMemoryMVPFlowRepository,
    pairContextProvider: FixedMVPFlowPairContextProvider
) async {
    let viewModel = await makeMVPFlowResultViewModel(
        repository: repository,
        pairContextProvider: pairContextProvider
    )
    await viewModel.load()

    #expect(await viewModel.screenState == .loaded)
    #expect(await viewModel.displayEntries.map(\.entry.candidateName) == [
        "深夜に食べたラーメン",
        "初日の出を見に行った"
    ])
    #expect(await viewModel.displayEntries.map(\.entry.totalPoints) == [15, 15])
    #expect(repository.savedResults.count == 1)

    await viewModel.requestResetConfirmation()
    await viewModel.confirmReset()

    #expect(await viewModel.resetDestinationCategoryId == "category-1")
    #expect(repository.category?.status == .draft)
    #expect(repository.category?.generation == 1)
    #expect(repository.inputs.isEmpty)
    #expect(repository.savedResults.isEmpty)
    #expect(repository.candidates.map(\.name) == [
        "初日の出を見に行った",
        "深夜に食べたラーメン"
    ])
}

private func assertMVPFlowCanReEnterAfterReset(
    repository: InMemoryMVPFlowRepository,
    pairContextProvider: FixedMVPFlowPairContextProvider
) async {
    let viewModel = await TextCandidateManagementViewModel(
        repository: repository,
        pairContextProvider: pairContextProvider,
        year: 2026,
        categoryId: "category-1",
        now: { Date(timeIntervalSince1970: 1_800_000_300) },
        makeCandidateId: repository.nextCandidateId
    )
    await viewModel.load()
    await waitForMVPFlowCandidates(viewModel, expectedCount: 2)

    #expect(await viewModel.isEditable == true)
    #expect(await viewModel.canConfirm == true)
}

@MainActor
private func makeMVPFlowRankingViewModel(
    repository: InMemoryMVPFlowRepository,
    pairContextProvider: FixedMVPFlowPairContextProvider
) -> TextRankingInputViewModel {
    TextRankingInputViewModel(
        repository: repository,
        pairContextProvider: pairContextProvider,
        year: 2026,
        categoryId: "category-1",
        now: { Date(timeIntervalSince1970: 1_800_000_200) }
    )
}

@MainActor
private func makeMVPFlowResultViewModel(
    repository: InMemoryMVPFlowRepository,
    pairContextProvider: FixedMVPFlowPairContextProvider
) -> TextCategoryResultViewModel {
    TextCategoryResultViewModel(
        repository: repository,
        pairContextProvider: pairContextProvider,
        calculator: TextCategoryResultCalculator(now: { Date(timeIntervalSince1970: 1_800_000_250) }),
        year: 2026,
        categoryId: "category-1"
    )
}

private func waitForMVPFlowCandidates(
    _ viewModel: TextCandidateManagementViewModel,
    expectedCount: Int,
    maxAttempts: Int = 100
) async {
    for _ in 0 ..< maxAttempts {
        if await viewModel.screenState == .loaded,
           await viewModel.rows.count == expectedCount {
            return
        }
        try? await Task.sleep(for: .milliseconds(10))
    }
}

private func waitForMVPFlowRankingState(
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

private struct FixedMVPFlowPairContextProvider: PairContextProviding {
    let userId: String

    func currentContext() async throws -> PairContext {
        PairContext(pairId: "pair-1", userId: userId, memberIds: ["user-a", "user-b"])
    }
}

private final class InMemoryMVPFlowRepository: TextCategoryRepository, @unchecked Sendable {
    private(set) var category: TextCategory?
    private(set) var candidates: [TextCandidate] = []
    private(set) var inputs: [String: TextCategoryInput] = [:]
    private(set) var savedResults: [TextCategoryResult] = []
    private var candidateIdCounter = 0

    func nextCandidateId() -> String {
        candidateIdCounter += 1
        return "candidate-\(candidateIdCounter)"
    }

    func observeCategories(pairId: String, year: Int) -> AsyncThrowingStream<[TextCategory], Error> {
        AsyncThrowingStream { continuation in
            if let category, category.pairId == pairId, category.year == year {
                continuation.yield([category])
            } else {
                continuation.yield([])
            }
            continuation.finish()
        }
    }

    func createCategory(_ category: TextCategory) async throws {
        try TextCategoryValidator.validate(category: category)
        self.category = category
    }

    func updateDraftCategory(_ category: TextCategory) async throws {
        guard let current = self.category, current.id == category.id else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        try TextCategoryRepositoryPolicy.validateDraftMutation(category: current)
        try TextCategoryValidator.validate(category: category)
        self.category = category
    }

    func confirmCategory(pairId: String, year: Int, categoryId: String) async throws {
        guard var category = category,
              category.pairId == pairId,
              category.year == year,
              category.id == categoryId
        else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        let categoryCandidates = candidates.filter { $0.categoryId == categoryId }
        try TextCategoryRepositoryPolicy.validateConfirmation(category: category, candidates: categoryCandidates)
        category.status = .confirmed
        category.confirmedAt = Date(timeIntervalSince1970: 1_800_000_150)
        category.updatedAt = Date(timeIntervalSince1970: 1_800_000_150)
        self.category = category
    }

    func resetCategory(pairId: String, year: Int, categoryId: String) async throws {
        guard var category = category,
              category.pairId == pairId,
              category.year == year,
              category.id == categoryId
        else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        inputs.removeAll()
        savedResults.removeAll()
        category.status = .draft
        category.inputStatuses = [:]
        category.generation += 1
        category.confirmedAt = nil
        category.updatedAt = Date(timeIntervalSince1970: 1_800_000_300)
        self.category = category
    }

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

    func addCandidate(_ candidate: TextCandidate) async throws {
        guard let category, category.id == candidate.categoryId else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        try TextCategoryRepositoryPolicy.validateDraftMutation(category: category)
        try TextCategoryValidator.validate(candidate: candidate)
        candidates.append(candidate)
    }

    func updateCandidate(_ candidate: TextCandidate) async throws {
        guard let category, category.id == candidate.categoryId else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        try TextCategoryRepositoryPolicy.validateDraftMutation(category: category)
        guard let index = candidates.firstIndex(where: { $0.id == candidate.id }) else {
            throw TextCategoryRepositoryError.invalidDocument(candidate.id)
        }
        try TextCategoryValidator.validate(candidate: candidate)
        candidates[index] = candidate
    }

    func deleteCandidate(pairId: String, year: Int, categoryId: String, candidateId: String) async throws {
        guard let category,
              category.pairId == pairId,
              category.year == year,
              category.id == categoryId
        else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        try TextCategoryRepositoryPolicy.validateDraftMutation(category: category)
        candidates.removeAll { $0.id == candidateId }
    }

    func saveInput(_ input: TextCategoryInput) async throws {
        try validate(input: input)
        inputs[input.userId] = input
        updateInputStatus(userId: input.userId, status: input.status)
    }

    func completeInput(_ input: TextCategoryInput) async throws {
        var completedInput = input
        completedInput.status = .completed
        completedInput.completedAt = completedInput.completedAt ?? Date(timeIntervalSince1970: 1_800_000_220)
        try validate(input: completedInput)
        inputs[completedInput.userId] = completedInput
        updateInputStatus(userId: completedInput.userId, status: .completed)
    }

    func loadInput(pairId: String, year: Int, categoryId: String, userId: String) async throws -> TextCategoryInput? {
        guard let input = inputs[userId],
              input.pairId == pairId,
              input.year == year,
              input.categoryId == categoryId
        else {
            return nil
        }
        return input
    }

    func loadResultContext(pairId: String, year: Int, categoryId: String) async throws -> TextCategoryResultContext {
        guard let category,
              category.pairId == pairId,
              category.year == year,
              category.id == categoryId
        else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        let categoryCandidates = candidates.filter { $0.categoryId == categoryId }
        let categoryInputs = Array(inputs.values)
        try TextCategoryRepositoryPolicy.validateCompletedInputs(
            category: category,
            candidates: categoryCandidates,
            inputs: categoryInputs,
            memberIds: ["user-a", "user-b"]
        )
        return TextCategoryResultContext(category: category, candidates: categoryCandidates, inputs: categoryInputs)
    }

    func saveResultIfNeeded(_ result: TextCategoryResult) async throws -> TextCategoryResult {
        if let existingResult = savedResults.first(where: { $0.id == result.id && $0.generation == result.generation }) {
            return existingResult
        }
        savedResults.append(result)
        return result
    }

    private func validate(input: TextCategoryInput) throws {
        guard let category, category.id == input.categoryId else {
            throw TextCategoryRepositoryError.categoryNotFound
        }
        try TextCategoryValidator.validate(
            input: input,
            settings: category.settings,
            categoryGeneration: category.generation,
            candidateIds: Set(candidates.map(\.id))
        )
    }

    private func updateInputStatus(userId: String, status: InputStatus) {
        guard var category else {
            return
        }
        category.inputStatuses[userId] = status
        category.updatedAt = Date(timeIntervalSince1970: 1_800_000_225)
        self.category = category
    }
}
