@testable import SelectBestPhoto
import Foundation
import Testing

struct TextCategoryRepositoryBoundaryTests {
    @Test func firestorePathBuilderCreatesSchemaCompatibleRelativePaths() {
        #expect(TextCategoryFirestorePath.year(pairId: "pair-1", year: 2026) == "pairs/pair-1/years/2026")
        #expect(TextCategoryFirestorePath.category(pairId: "pair-1", year: 2026, categoryId: "category-1") == "pairs/pair-1/years/2026/textCategories/category-1")
        #expect(TextCategoryFirestorePath.candidates(pairId: "pair-1", year: 2026, categoryId: "category-1") == "pairs/pair-1/years/2026/textCategories/category-1/candidates")
        #expect(TextCategoryFirestorePath.candidate(pairId: "pair-1", year: 2026, categoryId: "category-1", candidateId: "candidate-1") == "pairs/pair-1/years/2026/textCategories/category-1/candidates/candidate-1")
        #expect(TextCategoryFirestorePath.input(pairId: "pair-1", year: 2026, categoryId: "category-1", userId: "user-a") == "pairs/pair-1/years/2026/textCategories/category-1/inputs/user-a")
        #expect(TextCategoryFirestorePath.result(pairId: "pair-1", year: 2026, categoryId: "category-1", resultId: "result-1") == "pairs/pair-1/years/2026/textCategories/category-1/results/result-1")
    }

    @Test func pairContextProviderCanBeReplacedInTests() async throws {
        let provider = FixedPairContextProvider(context: PairContext(pairId: "pair-1", userId: "user-a"))

        let context = try await provider.currentContext()

        #expect(context == PairContext(pairId: "pair-1", userId: "user-a"))
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

    private func makeCategory() -> TextCategory {
        TextCategory(
            id: "category-1",
            pairId: "pair-1",
            year: 2026,
            name: "今年の名言",
            status: .draft,
            settings: TextCategorySettings(inputRankLimit: 1, revealRankLimit: 1, pointsByRank: [RankPoint(rank: 1, points: 10)]),
            generation: 0,
            createdByUserId: "user-a",
            confirmedAt: nil,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
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

    func createCategory(_ category: TextCategory) async throws {}

    func updateDraftCategory(_ category: TextCategory) async throws {}

    func confirmCategory(pairId: String, year: Int, categoryId: String) async throws {
        confirmedCategoryIds.append(categoryId)
    }

    func resetCategory(pairId: String, year: Int, categoryId: String) async throws {}

    func observeCandidates(pairId: String, year: Int, categoryId: String) -> AsyncThrowingStream<[TextCandidate], Error> {
        AsyncThrowingStream { continuation in
            continuation.yield([])
            continuation.finish()
        }
    }

    func addCandidate(_ candidate: TextCandidate) async throws {}

    func updateCandidate(_ candidate: TextCandidate) async throws {}

    func deleteCandidate(pairId: String, year: Int, categoryId: String, candidateId: String) async throws {}

    func saveInput(_ input: TextCategoryInput) async throws {}

    func completeInput(_ input: TextCategoryInput) async throws {}

    func loadResultContext(pairId: String, year: Int, categoryId: String) async throws -> TextCategoryResultContext {
        TextCategoryResultContext(category: categories[0], candidates: [], inputs: [])
    }

    func saveResultIfNeeded(_ result: TextCategoryResult) async throws {}
}
