import Foundation
@testable import SelectBestPhoto
import Testing

struct TextCategoryRepositoryBoundaryTests {
    @Test func firestorePathBuilderCreatesSchemaCompatibleRelativePaths() {
        #expect(TextCategoryFirestorePath.year(pairId: "pair-1", year: 2026) == "pairs/pair-1/years/2026")
        #expect(
            TextCategoryFirestorePath.category(pairId: "pair-1", year: 2026, categoryId: "category-1")
                == "pairs/pair-1/years/2026/textCategories/category-1"
        )
        #expect(
            TextCategoryFirestorePath.candidates(pairId: "pair-1", year: 2026, categoryId: "category-1")
                == "pairs/pair-1/years/2026/textCategories/category-1/candidates"
        )
        #expect(
            TextCategoryFirestorePath.candidate(
                pairId: "pair-1",
                year: 2026,
                categoryId: "category-1",
                candidateId: "candidate-1"
            ) == "pairs/pair-1/years/2026/textCategories/category-1/candidates/candidate-1"
        )
        #expect(
            TextCategoryFirestorePath.input(
                pairId: "pair-1",
                year: 2026,
                categoryId: "category-1",
                userId: "user-a"
            ) == "pairs/pair-1/years/2026/textCategories/category-1/inputs/user-a"
        )
        #expect(
            TextCategoryFirestorePath.result(
                pairId: "pair-1",
                year: 2026,
                categoryId: "category-1",
                resultId: "result-1"
            ) == "pairs/pair-1/years/2026/textCategories/category-1/results/result-1"
        )
    }

    @Test func pairContextProviderCanBeReplacedInTests() async throws {
        let provider = FixedPairContextProvider(
            context: PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"])
        )

        let context = try await provider.currentContext()

        #expect(context == PairContext(pairId: "pair-1", userId: "user-a", memberIds: ["user-a", "user-b"]))
        #expect(context.partnerUserId == "user-b")
    }

    @Test func repositoryProtocolCanBeImplementedByFakeForViewModelTests() async throws {
        let category = makeCategory()
        let repository = FakeTextCategoryRepository(categories: [category])
        let stream = repository.observeCategories(pairId: "pair-1", year: 2026)
        var iterator = stream.makeAsyncIterator()

        let categories = try await iterator.next()

        #expect(categories == [category])
        try await repository.confirmCategory(pairId: "pair-1", year: 2026, categoryId: "category-1")
        #expect(repository.confirmedCategoryIds == ["category-1"])
    }

    @Test func repositoryPolicyRejectsConfirmingCategoryWithInsufficientCandidates() throws {
        let category = makeCategory(inputRankLimit: 2)
        let candidates = [
            makeCandidate(id: "candidate-1", name: "候補1"),
        ]

        #expect(throws: TextCategoryRepositoryError.insufficientCandidates(expected: 2, actual: 1)) {
            try TextCategoryRepositoryPolicy.validateConfirmation(category: category, candidates: candidates)
        }
    }

    @Test func repositoryPolicyRejectsMutationAfterCategoryConfirmed() throws {
        let category = makeCategory(status: .confirmed, confirmedAt: Date())

        #expect(throws: TextCategoryRepositoryError.cannotModifyConfirmedCategory) {
            try TextCategoryRepositoryPolicy.validateDraftMutation(category: category)
        }
    }

    @Test func repositoryPolicyRequiresBothPairInputsCompletedBeforeResultContextLoads() throws {
        let category = makeCategory(inputRankLimit: 1)
        let candidates = [
            makeCandidate(id: "candidate-1", name: "候補1"),
        ]
        let inputs = [
            makeInput(userId: "user-a", candidateId: "candidate-1", status: .completed),
            makeInput(userId: "user-b", candidateId: "candidate-1", status: .inProgress),
        ]

        #expect(throws: TextCategoryRepositoryError.inputsNotCompleted) {
            try TextCategoryRepositoryPolicy.validateCompletedInputs(
                category: category,
                candidates: candidates,
                inputs: inputs,
                memberIds: ["user-a", "user-b"]
            )
        }
    }

    private func makeCategory(
        inputRankLimit: Int = 1,
        status: TextCategoryStatus = .draft,
        confirmedAt: Date? = nil
    ) -> TextCategory {
        TextCategory(
            id: "category-1",
            pairId: "pair-1",
            year: 2026,
            name: "今年の名言",
            status: status,
            settings: TextCategorySettings(
                inputRankLimit: inputRankLimit,
                revealRankLimit: 1,
                pointsByRank: (1 ... inputRankLimit).map { RankPoint(rank: $0, points: 11 - $0) }
            ),
            generation: 0,
            createdByUserId: "user-a",
            confirmedAt: confirmedAt,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
        )
    }

    private func makeCandidate(id: String, name: String) -> TextCandidate {
        TextCandidate(
            id: id,
            pairId: "pair-1",
            year: 2026,
            categoryId: "category-1",
            name: name,
            imagePlaceholderKind: .none,
            createdByUserId: "user-a",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
        )
    }

    private func makeInput(userId: String, candidateId: String, status: InputStatus) -> TextCategoryInput {
        TextCategoryInput(
            id: userId,
            pairId: "pair-1",
            year: 2026,
            categoryId: "category-1",
            userId: userId,
            generation: 0,
            status: status,
            selections: [
                RankedTextSelection(rank: 1, candidateId: candidateId),
            ],
            completedAt: status == .completed ? Date(timeIntervalSince1970: 1_800_000_200) : nil,
            updatedAt: Date(timeIntervalSince1970: 1_800_000_200)
        )
    }
}

private struct FixedPairContextProvider: PairContextProviding {
    let context: PairContext

    func currentContext() async throws -> PairContext {
        context
    }
}

private final class FakeTextCategoryRepository: TextCategoryRepository, @unchecked Sendable {
    let categories: [TextCategory]
    var confirmedCategoryIds: [String] = []

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

    func confirmCategory(pairId _: String, year _: Int, categoryId: String) async throws {
        confirmedCategoryIds.append(categoryId)
    }

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
