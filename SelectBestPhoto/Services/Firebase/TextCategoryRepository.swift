import Foundation

struct PairContext: Equatable, Sendable {
    var pairId: String
    var userId: String
}

protocol PairContextProviding: Sendable {
    func currentContext() async throws -> PairContext
}

protocol TextCategoryRepository: Sendable {
    func observeCategories(pairId: String, year: Int) -> AsyncThrowingStream<[TextCategory], Error>
    func createCategory(_ category: TextCategory) async throws
    func updateDraftCategory(_ category: TextCategory) async throws
    func confirmCategory(pairId: String, year: Int, categoryId: String) async throws
    func resetCategory(pairId: String, year: Int, categoryId: String) async throws

    func observeCandidates(pairId: String, year: Int, categoryId: String) -> AsyncThrowingStream<[TextCandidate], Error>
    func addCandidate(_ candidate: TextCandidate) async throws
    func updateCandidate(_ candidate: TextCandidate) async throws
    func deleteCandidate(pairId: String, year: Int, categoryId: String, candidateId: String) async throws

    func saveInput(_ input: TextCategoryInput) async throws
    func completeInput(_ input: TextCategoryInput) async throws
    func loadResultContext(pairId: String, year: Int, categoryId: String) async throws -> TextCategoryResultContext
    func saveResultIfNeeded(_ result: TextCategoryResult) async throws
}

struct TextCategoryResultContext: Sendable, Equatable {
    var category: TextCategory
    var candidates: [TextCandidate]
    var inputs: [TextCategoryInput]
}

enum TextCategoryFirestorePath {
    static func year(pairId: String, year: Int) -> String {
        "pairs/\(pairId)/years/\(year)"
    }

    static func category(pairId: String, year: Int, categoryId: String) -> String {
        "\(categories(pairId: pairId, year: year))/\(categoryId)"
    }

    static func categories(pairId: String, year: Int) -> String {
        "\(Self.year(pairId: pairId, year: year))/textCategories"
    }

    static func candidates(pairId: String, year: Int, categoryId: String) -> String {
        "\(category(pairId: pairId, year: year, categoryId: categoryId))/candidates"
    }

    static func candidate(pairId: String, year: Int, categoryId: String, candidateId: String) -> String {
        "\(candidates(pairId: pairId, year: year, categoryId: categoryId))/\(candidateId)"
    }

    static func inputs(pairId: String, year: Int, categoryId: String) -> String {
        "\(category(pairId: pairId, year: year, categoryId: categoryId))/inputs"
    }

    static func input(pairId: String, year: Int, categoryId: String, userId: String) -> String {
        "\(inputs(pairId: pairId, year: year, categoryId: categoryId))/\(userId)"
    }

    static func results(pairId: String, year: Int, categoryId: String) -> String {
        "\(category(pairId: pairId, year: year, categoryId: categoryId))/results"
    }

    static func result(pairId: String, year: Int, categoryId: String, resultId: String) -> String {
        "\(results(pairId: pairId, year: year, categoryId: categoryId))/\(resultId)"
    }
}
