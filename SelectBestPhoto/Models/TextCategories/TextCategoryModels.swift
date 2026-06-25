import Foundation

enum InputStatus: String, Codable, Equatable {
    case notStarted
    case inProgress
    case completed
}

enum TextCategoryStatus: String, Codable, Equatable {
    case draft
    case confirmed
    case resultAvailable
}

struct TextCategory: Codable, Identifiable, Equatable {
    var id: String
    var pairId: String
    var year: Int
    var name: String
    var status: TextCategoryStatus
    var settings: TextCategorySettings
    var generation: Int
    var createdByUserId: String
    var confirmedAt: Date?
    var createdAt: Date
    var updatedAt: Date
}

struct TextCategorySettings: Codable, Equatable {
    var inputRankLimit: Int
    var revealRankLimit: Int
    var pointsByRank: [RankPoint]
}

struct RankPoint: Codable, Identifiable, Equatable {
    var id: Int {
        rank
    }

    var rank: Int
    var points: Int
}

struct TextCandidate: Codable, Identifiable, Equatable {
    var id: String
    var pairId: String
    var year: Int
    var categoryId: String
    var name: String
    var imagePlaceholderKind: TextCandidateImagePlaceholderKind
    var createdByUserId: String
    var createdAt: Date
    var updatedAt: Date
}

enum TextCandidateImagePlaceholderKind: String, Codable, Equatable {
    case none
    case futureImageSlot
}

struct TextCategoryInput: Codable, Identifiable, Equatable {
    var id: String
    var pairId: String
    var year: Int
    var categoryId: String
    var userId: String
    var generation: Int
    var status: InputStatus
    var selections: [RankedTextSelection]
    var completedAt: Date?
    var updatedAt: Date
}

struct RankedTextSelection: Codable, Identifiable, Equatable {
    var id: String
    var rank: Int
    var candidateId: String

    init(id: String? = nil, rank: Int, candidateId: String) {
        self.rank = rank
        self.candidateId = candidateId
        self.id = id ?? "\(rank)-\(candidateId)"
    }
}

struct TextCategoryResult: Codable, Identifiable, Equatable {
    var id: String
    var pairId: String
    var year: Int
    var categoryId: String
    var generation: Int
    var entries: [TextCategoryResultEntry]
    var sourceUserIds: [String]
    var createdAt: Date
}

struct TextCategoryResultEntry: Codable, Identifiable, Equatable {
    var id: String
    var rank: Int
    var candidateId: String
    var candidateName: String
    var totalPoints: Int
    var userBreakdowns: [TextCategoryUserPointBreakdown]
    var imagePlaceholderKind: TextCandidateImagePlaceholderKind
}

struct TextCategoryUserPointBreakdown: Codable, Identifiable, Equatable {
    var id: String {
        userId
    }

    var userId: String
    var selectedRank: Int?
    var points: Int
}

enum TextCategoryValidationError: Error, Equatable {
    case blankCategoryName
    case invalidInputRankLimit
    case invalidRevealRankLimit
    case invalidRankPoint(rank: Int)
    case missingRankPoint(rank: Int)
    case duplicateRankPoint(rank: Int)
    case blankCandidateName
    case duplicateCandidateId(String)
    case invalidSelectionRank(Int)
    case duplicateSelectionRank(Int)
    case duplicateSelectedCandidateId(String)
    case unknownSelectedCandidateId(String)
    case incompleteSelection(expected: Int, actual: Int)
    case generationMismatch(expected: Int, actual: Int)
}

enum TextCategoryValidator {
    static let rankLimitRange = 1 ... 50

    static func validate(category: TextCategory) throws {
        if category.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw TextCategoryValidationError.blankCategoryName
        }
        try validate(settings: category.settings)
    }

    static func validate(settings: TextCategorySettings) throws {
        guard rankLimitRange.contains(settings.inputRankLimit) else {
            throw TextCategoryValidationError.invalidInputRankLimit
        }
        guard rankLimitRange.contains(settings.revealRankLimit),
              settings.revealRankLimit <= settings.inputRankLimit
        else {
            throw TextCategoryValidationError.invalidRevealRankLimit
        }
        guard settings.pointsByRank.count <= rankLimitRange.upperBound else {
            throw TextCategoryValidationError.invalidRankPoint(rank: settings.pointsByRank.count)
        }

        var seenRanks: Set<Int> = []
        for point in settings.pointsByRank {
            guard rankLimitRange.contains(point.rank), point.rank <= settings.inputRankLimit, point.points >= 1 else {
                throw TextCategoryValidationError.invalidRankPoint(rank: point.rank)
            }
            guard seenRanks.insert(point.rank).inserted else {
                throw TextCategoryValidationError.duplicateRankPoint(rank: point.rank)
            }
        }

        for rank in 1 ... settings.inputRankLimit where !seenRanks.contains(rank) {
            throw TextCategoryValidationError.missingRankPoint(rank: rank)
        }
    }

    static func validate(candidate: TextCandidate) throws {
        if candidate.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw TextCategoryValidationError.blankCandidateName
        }
    }

    static func validate(candidates: [TextCandidate]) throws {
        var seenIds: Set<String> = []
        for candidate in candidates {
            try validate(candidate: candidate)
            guard seenIds.insert(candidate.id).inserted else {
                throw TextCategoryValidationError.duplicateCandidateId(candidate.id)
            }
        }
    }

    static func validate(
        input: TextCategoryInput,
        settings: TextCategorySettings,
        categoryGeneration: Int,
        candidateIds: Set<String>? = nil
    ) throws {
        try validate(settings: settings)

        guard input.generation == categoryGeneration else {
            throw TextCategoryValidationError.generationMismatch(expected: categoryGeneration, actual: input.generation)
        }
        if input.status == .completed, input.selections.count != settings.inputRankLimit {
            throw TextCategoryValidationError.incompleteSelection(
                expected: settings.inputRankLimit,
                actual: input.selections.count
            )
        }

        var seenRanks: Set<Int> = []
        var seenCandidateIds: Set<String> = []
        for selection in input.selections {
            guard 1 ... settings.inputRankLimit ~= selection.rank else {
                throw TextCategoryValidationError.invalidSelectionRank(selection.rank)
            }
            guard seenRanks.insert(selection.rank).inserted else {
                throw TextCategoryValidationError.duplicateSelectionRank(selection.rank)
            }
            guard seenCandidateIds.insert(selection.candidateId).inserted else {
                throw TextCategoryValidationError.duplicateSelectedCandidateId(selection.candidateId)
            }
            if let candidateIds, !candidateIds.contains(selection.candidateId) {
                throw TextCategoryValidationError.unknownSelectedCandidateId(selection.candidateId)
            }
        }
    }
}
