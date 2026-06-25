@testable import SelectBestPhoto
import Foundation
import Testing

struct TextCategoryResultCalculatorTests {
    @Test func calculatesTotalPointsAndUserBreakdowns() throws {
        let calculator: TextCategoryResultCalculating = TextCategoryResultCalculator(now: {
            Date(timeIntervalSince1970: 1_800_000_300)
        })
        let category = makeCategory(inputRankLimit: 3, revealRankLimit: 2)
        let candidates = [
            makeCandidate(id: "candidate-a", name: "候補A", createdAtOffset: 1),
            makeCandidate(id: "candidate-b", name: "候補B", createdAtOffset: 2),
            makeCandidate(id: "candidate-c", name: "候補C", createdAtOffset: 3)
        ]
        let inputs = [
            makeInput(userId: "user-a", selections: [
                RankedTextSelection(rank: 1, candidateId: "candidate-a"),
                RankedTextSelection(rank: 2, candidateId: "candidate-b"),
                RankedTextSelection(rank: 3, candidateId: "candidate-c")
            ]),
            makeInput(userId: "user-b", selections: [
                RankedTextSelection(rank: 1, candidateId: "candidate-b"),
                RankedTextSelection(rank: 2, candidateId: "candidate-a"),
                RankedTextSelection(rank: 3, candidateId: "candidate-c")
            ])
        ]

        let result = try calculator.calculate(category: category, candidates: candidates, inputs: inputs)

        #expect(result.id == "category-1-generation-0")
        #expect(result.sourceUserIds == ["user-a", "user-b"])
        #expect(result.entries.map(\.candidateId) == ["candidate-a", "candidate-b"])
        #expect(result.entries.map(\.totalPoints) == [15, 15])
        #expect(result.entries[0].userBreakdowns == [
            TextCategoryUserPointBreakdown(userId: "user-a", selectedRank: 1, points: 10),
            TextCategoryUserPointBreakdown(userId: "user-b", selectedRank: 2, points: 5)
        ])
    }

    @Test func sortsTiesByHighestRankThenCandidateCreationOrder() throws {
        let calculator = TextCategoryResultCalculator(now: { Date(timeIntervalSince1970: 1_800_000_300) })
        let category = makeCategory(inputRankLimit: 2, revealRankLimit: 3)
        let candidates = [
            makeCandidate(id: "candidate-created-first", name: "作成順1", createdAtOffset: 1),
            makeCandidate(id: "candidate-best-rank", name: "最高順位あり", createdAtOffset: 2),
            makeCandidate(id: "candidate-created-last", name: "作成順3", createdAtOffset: 3)
        ]
        let inputs = [
            makeInput(userId: "user-a", selections: [
                RankedTextSelection(rank: 1, candidateId: "candidate-best-rank"),
                RankedTextSelection(rank: 2, candidateId: "candidate-created-first")
            ]),
            makeInput(userId: "user-b", selections: [
                RankedTextSelection(rank: 1, candidateId: "candidate-created-last"),
                RankedTextSelection(rank: 2, candidateId: "candidate-created-first")
            ])
        ]

        let result = try calculator.calculate(category: category, candidates: candidates, inputs: inputs)

        #expect(result.entries.map(\.candidateId) == [
            "candidate-best-rank",
            "candidate-created-last",
            "candidate-created-first"
        ])
        #expect(result.entries.map(\.rank) == [1, 2, 3])
    }

    private func makeCategory(inputRankLimit: Int, revealRankLimit: Int) -> TextCategory {
        TextCategory(
            id: "category-1",
            pairId: "pair-1",
            year: 2026,
            name: "今年の名言",
            status: .confirmed,
            settings: TextCategorySettings(
                inputRankLimit: inputRankLimit,
                revealRankLimit: revealRankLimit,
                pointsByRank: (1...inputRankLimit).map { rank in
                    RankPoint(rank: rank, points: [1: 10, 2: 5, 3: 1][rank] ?? 1)
                }
            ),
            generation: 0,
            createdByUserId: "user-a",
            confirmedAt: Date(timeIntervalSince1970: 1_800_000_000),
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
        )
    }

    private func makeCandidate(id: String, name: String, createdAtOffset: TimeInterval) -> TextCandidate {
        TextCandidate(
            id: id,
            pairId: "pair-1",
            year: 2026,
            categoryId: "category-1",
            name: name,
            imagePlaceholderKind: .none,
            createdByUserId: "user-a",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000 + createdAtOffset),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_100)
        )
    }

    private func makeInput(userId: String, selections: [RankedTextSelection]) -> TextCategoryInput {
        TextCategoryInput(
            id: userId,
            pairId: "pair-1",
            year: 2026,
            categoryId: "category-1",
            userId: userId,
            generation: 0,
            status: .completed,
            selections: selections,
            completedAt: Date(timeIntervalSince1970: 1_800_000_200),
            updatedAt: Date(timeIntervalSince1970: 1_800_000_200)
        )
    }
}
