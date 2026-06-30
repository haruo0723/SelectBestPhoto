import Foundation
@testable import SelectBestPhoto
import Testing

struct TextCategorySettingsViewModelTests {
    @Test func saveValidDraftCreatesDraftCategoryAndMovesToCandidateManagement() async {
        let repository = FakeSettingsRepository()
        let viewModel = await makeViewModel(repository: repository)
        await MainActor.run {
            viewModel.draft.name = "今年の名言"
            viewModel.setInputRankLimit(4)
            viewModel.setRevealRankLimit(2)
            viewModel.setPoints(20, forRank: 1)
        }

        await viewModel.saveDraft()

        let createdCategory = repository.createdCategories.first
        #expect(createdCategory?.id == "category-new")
        #expect(createdCategory?.pairId == "pair-1")
        #expect(createdCategory?.year == 2026)
        #expect(createdCategory?.name == "今年の名言")
        #expect(createdCategory?.status == .draft)
        #expect(createdCategory?.settings.inputRankLimit == 4)
        #expect(createdCategory?.settings.revealRankLimit == 2)
        #expect(createdCategory?.settings.pointsByRank.first?.points == 20)
        #expect(createdCategory?.createdByUserId == "user-a")
        #expect(await viewModel.saveState == .saved(categoryId: "category-new"))
    }

    @Test func invalidDraftShowsValidationMessagesAndDoesNotCreateCategory() async {
        let repository = FakeSettingsRepository()
        let viewModel = await makeViewModel(repository: repository)
        await MainActor.run {
            viewModel.draft.name = " "
        }

        await viewModel.saveDraft()

        #expect(repository.createdCategories.isEmpty)
        #expect(await viewModel.validationMessages == ["部門名を入力してください。"])
        #expect(await viewModel.saveState == .editing)
    }

    @Test func revealRankLimitCannotExceedInputRankLimit() async {
        let viewModel = await makeViewModel()

        await MainActor.run {
            viewModel.setInputRankLimit(2)
            viewModel.setRevealRankLimit(50)
        }

        #expect(await viewModel.draft.inputRankLimit == 2)
        #expect(await viewModel.draft.revealRankLimit == 2)
        #expect(await viewModel.draft.pointsByRank.map(\.rank) == [1, 2])
    }

    @Test func saveFailureKeepsEditingValues() async {
        let repository = FakeSettingsRepository(saveError: TextCategoryRepositoryError.pairContextUnavailable)
        let viewModel = await makeViewModel(repository: repository)
        await MainActor.run {
            viewModel.draft.name = "行ってよかった場所"
            viewModel.setInputRankLimit(5)
        }

        await viewModel.saveDraft()

        #expect(await viewModel.draft.name == "行ってよかった場所")
        #expect(await viewModel.draft.inputRankLimit == 5)
        #expect(await viewModel.saveState == .failed("保存できませんでした。通信状況を確認してもう一度お試しください。"))
    }

    @Test func saveExistingDraftUpdatesCategoryWithoutChangingOriginalIdentity() async {
        let repository = FakeSettingsRepository()
        let existingCategory = makeCategory(id: "category-existing", name: "変更前", status: .draft)
        let viewModel = await makeViewModel(repository: repository, existingCategory: existingCategory)
        await MainActor.run {
            viewModel.draft.name = "変更後"
            viewModel.setRevealRankLimit(1)
        }

        await viewModel.saveDraft()

        #expect(repository.createdCategories.isEmpty)
        let updatedCategory = repository.updatedCategories.first
        #expect(updatedCategory?.id == "category-existing")
        #expect(updatedCategory?.name == "変更後")
        #expect(updatedCategory?.createdByUserId == "user-a")
        #expect(updatedCategory?.settings.revealRankLimit == 1)
        #expect(await viewModel.saveState == .saved(categoryId: "category-existing"))
    }

    @Test func confirmedCategoryCannotBeSaved() async {
        let repository = FakeSettingsRepository()
        let existingCategory = makeCategory(id: "category-confirmed", name: "確定済み", status: .confirmed)
        let viewModel = await makeViewModel(repository: repository, existingCategory: existingCategory)
        await MainActor.run {
            viewModel.draft.name = "変更後"
        }

        await viewModel.saveDraft()

        #expect(repository.createdCategories.isEmpty)
        #expect(repository.updatedCategories.isEmpty)
        #expect(await viewModel.validationMessages == ["確定済み部門の設定は変更できません。"])
    }

    @MainActor
    private func makeViewModel(
        repository: FakeSettingsRepository = FakeSettingsRepository(),
        existingCategory: TextCategory? = nil
    ) -> TextCategorySettingsViewModel {
        TextCategorySettingsViewModel(
            repository: repository,
            pairContextProvider: FixedSettingsPairContextProvider(),
            year: 2026,
            existingCategory: existingCategory,
            now: { Date(timeIntervalSince1970: 1_800_000_000) },
            makeCategoryId: { "category-new" }
        )
    }

    private func makeCategory(id: String, name: String, status: TextCategoryStatus) -> TextCategory {
        TextCategory(
            id: id,
            pairId: "pair-1",
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
            createdAt: Date(timeIntervalSince1970: 1_799_999_900),
            updatedAt: Date(timeIntervalSince1970: 1_799_999_950)
        )
    }
}

private struct FixedSettingsPairContextProvider: PairContextProviding {
    func currentContext() async throws -> PairContext {
        PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
    }
}

private final class FakeSettingsRepository: TextCategoryRepository, @unchecked Sendable {
    private(set) var createdCategories: [TextCategory] = []
    private(set) var updatedCategories: [TextCategory] = []
    private let saveError: Error?

    init(saveError: Error? = nil) {
        self.saveError = saveError
    }

    func observeCategories(pairId _: String, year _: Int) -> AsyncThrowingStream<[TextCategory], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func createCategory(_ category: TextCategory) async throws {
        if let saveError {
            throw saveError
        }
        createdCategories.append(category)
    }

    func updateDraftCategory(_ category: TextCategory) async throws {
        if let saveError {
            throw saveError
        }
        updatedCategories.append(category)
    }

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
        throw TextCategoryRepositoryError.categoryNotFound
    }

    func saveResultIfNeeded(_ result: TextCategoryResult) async throws -> TextCategoryResult {
        result
    }
}
