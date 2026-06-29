import Foundation
@testable import SelectBestPhoto
import Testing

struct TextCategoryModelTests {
    @Test func settingsValidationAcceptsBoundaryValues() throws {
        let settings = TextCategorySettings(
            inputRankLimit: 50,
            revealRankLimit: 50,
            pointsByRank: (1 ... 50).map { RankPoint(rank: $0, points: 51 - $0) }
        )

        try TextCategoryValidator.validate(settings: settings)
    }

    @Test func settingsValidationRejectsInvalidLimitsAndPoints() {
        let invalidInputLimit = TextCategorySettings(inputRankLimit: 0, revealRankLimit: 1, pointsByRank: [RankPoint(rank: 1, points: 1)])
        let invalidRevealLimit = TextCategorySettings(inputRankLimit: 3, revealRankLimit: 4, pointsByRank: [RankPoint(rank: 1, points: 1)])
        let invalidPoints = TextCategorySettings(inputRankLimit: 1, revealRankLimit: 1, pointsByRank: [RankPoint(rank: 1, points: 0)])
        let missingRankPoint = TextCategorySettings(inputRankLimit: 2, revealRankLimit: 1, pointsByRank: [RankPoint(rank: 1, points: 10)])

        #expect(throws: TextCategoryValidationError.invalidInputRankLimit) {
            try TextCategoryValidator.validate(settings: invalidInputLimit)
        }
        #expect(throws: TextCategoryValidationError.invalidRevealRankLimit) {
            try TextCategoryValidator.validate(settings: invalidRevealLimit)
        }
        #expect(throws: TextCategoryValidationError.invalidRankPoint(rank: 1)) {
            try TextCategoryValidator.validate(settings: invalidPoints)
        }
        #expect(throws: TextCategoryValidationError.missingRankPoint(rank: 2)) {
            try TextCategoryValidator.validate(settings: missingRankPoint)
        }
    }

    @Test func candidateValidationAllowsDuplicateNamesButRejectsBlankNamesAndDuplicateIds() throws {
        let first = makeCandidate(id: "candidate-1", name: "初日の出")
        let duplicateName = makeCandidate(id: "candidate-2", name: "初日の出")
        let blankName = makeCandidate(id: "candidate-3", name: "   ")
        let duplicateId = makeCandidate(id: "candidate-1", name: "別候補")

        try TextCategoryValidator.validate(candidates: [first, duplicateName])

        #expect(throws: TextCategoryValidationError.self) {
            try TextCategoryValidator.validate(candidates: [blankName])
        }
        #expect(throws: TextCategoryValidationError.self) {
            try TextCategoryValidator.validate(candidates: [first, duplicateId])
        }
    }

    @Test func completedInputValidationRejectsDuplicateCandidateSelection() {
        let settings = TextCategorySettings(
            inputRankLimit: 2,
            revealRankLimit: 1,
            pointsByRank: [RankPoint(rank: 1, points: 10), RankPoint(rank: 2, points: 5)]
        )
        let duplicateSelectionInput = TextCategoryInput(
            id: "user-a",
            pairId: "pair-1",
            year: 2026,
            categoryId: "category-1",
            userId: "user-a",
            generation: 0,
            status: .completed,
            selections: [
                RankedTextSelection(rank: 1, candidateId: "candidate-1"),
                RankedTextSelection(rank: 2, candidateId: "candidate-1"),
            ],
            completedAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: TextCategoryValidationError.self) {
            try TextCategoryValidator.validate(input: duplicateSelectionInput, settings: settings, categoryGeneration: 0)
        }
    }

    @Test func inputValidationRejectsUnknownSelectedCandidateIdWhenCandidatesAreProvided() {
        let settings = TextCategorySettings(
            inputRankLimit: 1,
            revealRankLimit: 1,
            pointsByRank: [RankPoint(rank: 1, points: 10)]
        )
        let input = TextCategoryInput(
            id: "user-a",
            pairId: "pair-1",
            year: 2026,
            categoryId: "category-1",
            userId: "user-a",
            generation: 0,
            status: .completed,
            selections: [
                RankedTextSelection(rank: 1, candidateId: "missing-candidate"),
            ],
            completedAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: TextCategoryValidationError.unknownSelectedCandidateId("missing-candidate")) {
            try TextCategoryValidator.validate(
                input: input,
                settings: settings,
                categoryGeneration: 0,
                candidateIds: ["candidate-1"]
            )
        }
    }

    @Test func modelsRoundTripThroughCodable() throws {
        let category = TextCategory(
            id: "category-1",
            pairId: "pair-1",
            year: 2026,
            name: "今年の名言",
            status: .draft,
            settings: TextCategorySettings(inputRankLimit: 3, revealRankLimit: 2, pointsByRank: [
                RankPoint(rank: 1, points: 10),
                RankPoint(rank: 2, points: 5),
                RankPoint(rank: 3, points: 1),
            ]),
            generation: 0,
            createdByUserId: "user-a",
            confirmedAt: nil,
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
        )

        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(TextCategory.self, from: data)

        #expect(decoded == category)
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
}
