import Foundation

protocol TextCategoryResultCalculating: Sendable {
    func calculate(
        category: TextCategory,
        candidates: [TextCandidate],
        inputs: [TextCategoryInput]
    ) throws -> TextCategoryResult
}

struct TextCategoryResultCalculator: TextCategoryResultCalculating {
    var now: @Sendable () -> Date

    init(now: @escaping @Sendable () -> Date = Date.init) {
        self.now = now
    }

    func calculate(
        category: TextCategory,
        candidates: [TextCandidate],
        inputs: [TextCategoryInput]
    ) throws -> TextCategoryResult {
        try TextCategoryValidator.validate(category: category)
        try TextCategoryValidator.validate(candidates: candidates)
        let candidateIds = Set(candidates.map(\.id))
        for input in inputs {
            try TextCategoryValidator.validate(
                input: input,
                settings: category.settings,
                categoryGeneration: category.generation,
                candidateIds: candidateIds
            )
        }

        let pointsByRank = Dictionary(uniqueKeysWithValues: category.settings.pointsByRank.map { ($0.rank, $0.points) })
        let sourceUserIds = inputs.map(\.userId)
        let inputsByUserId = Dictionary(uniqueKeysWithValues: inputs.map { ($0.userId, $0) })
        let candidateOrder = Dictionary(uniqueKeysWithValues: candidates.enumerated().map { ($0.element.id, $0.offset) })

        let rankedEntries = candidates.map { candidate in
            makeIntermediateEntry(
                candidate: candidate,
                sourceUserIds: sourceUserIds,
                inputsByUserId: inputsByUserId,
                pointsByRank: pointsByRank,
                candidateOrder: candidateOrder[candidate.id] ?? Int.max
            )
        }
        .sorted { lhs, rhs in
            if lhs.totalPoints != rhs.totalPoints {
                return lhs.totalPoints > rhs.totalPoints
            }
            if lhs.bestSelectedRank != rhs.bestSelectedRank {
                return lhs.bestSelectedRank < rhs.bestSelectedRank
            }
            if lhs.candidate.createdAt != rhs.candidate.createdAt {
                return lhs.candidate.createdAt < rhs.candidate.createdAt
            }
            return lhs.candidateOrder < rhs.candidateOrder
        }
        .prefix(category.settings.revealRankLimit)

        let entries = rankedEntries.enumerated().map { index, intermediate in
            TextCategoryResultEntry(
                id: intermediate.candidate.id,
                rank: index + 1,
                candidateId: intermediate.candidate.id,
                candidateName: intermediate.candidate.name,
                totalPoints: intermediate.totalPoints,
                userBreakdowns: intermediate.userBreakdowns,
                imagePlaceholderKind: intermediate.candidate.imagePlaceholderKind
            )
        }

        return TextCategoryResult(
            id: "\(category.id)-generation-\(category.generation)",
            pairId: category.pairId,
            year: category.year,
            categoryId: category.id,
            generation: category.generation,
            entries: entries,
            sourceUserIds: sourceUserIds,
            createdAt: now()
        )
    }

    private func makeIntermediateEntry(
        candidate: TextCandidate,
        sourceUserIds: [String],
        inputsByUserId: [String: TextCategoryInput],
        pointsByRank: [Int: Int],
        candidateOrder: Int
    ) -> IntermediateEntry {
        let breakdowns = sourceUserIds.map { userId in
            let selectedRank = inputsByUserId[userId]?.selections.first { $0.candidateId == candidate.id }?.rank
            return TextCategoryUserPointBreakdown(
                userId: userId,
                selectedRank: selectedRank,
                points: selectedRank.flatMap { pointsByRank[$0] } ?? 0
            )
        }
        let bestSelectedRank = breakdowns.compactMap(\.selectedRank).min() ?? Int.max
        let totalPoints = breakdowns.reduce(0) { $0 + $1.points }

        return IntermediateEntry(
            candidate: candidate,
            totalPoints: totalPoints,
            bestSelectedRank: bestSelectedRank,
            candidateOrder: candidateOrder,
            userBreakdowns: breakdowns
        )
    }
}

private struct IntermediateEntry {
    var candidate: TextCandidate
    var totalPoints: Int
    var bestSelectedRank: Int
    var candidateOrder: Int
    var userBreakdowns: [TextCategoryUserPointBreakdown]
}
