import Foundation

struct TextCategorySettingsDraft: Equatable {
    var name: String
    var inputRankLimit: Int
    var revealRankLimit: Int
    var pointsByRank: [RankPoint]

    static func `default`() -> TextCategorySettingsDraft {
        TextCategorySettingsDraft(
            name: "",
            inputRankLimit: 3,
            revealRankLimit: 3,
            pointsByRank: [
                RankPoint(rank: 1, points: 10),
                RankPoint(rank: 2, points: 5),
                RankPoint(rank: 3, points: 1),
            ]
        )
    }
}

enum TextCategorySettingsSaveState: Equatable {
    case editing
    case saving
    case saved(categoryId: String)
    case failed(String)
}

@MainActor
final class TextCategorySettingsViewModel: ObservableObject {
    @Published var draft: TextCategorySettingsDraft
    @Published private(set) var validationMessages: [String] = []
    @Published private(set) var saveState: TextCategorySettingsSaveState = .editing

    let year: Int
    private let repository: TextCategoryRepository
    private let pairContextProvider: PairContextProviding
    private let existingCategory: TextCategory?
    private let now: () -> Date
    private let makeCategoryId: () -> String

    var canSave: Bool {
        saveState != .saving && existingCategory?.status != .confirmed && existingCategory?.status != .resultAvailable
    }

    init(
        repository: TextCategoryRepository,
        pairContextProvider: PairContextProviding,
        year: Int,
        draft: TextCategorySettingsDraft = .default(),
        existingCategory: TextCategory? = nil,
        now: @escaping () -> Date = Date.init,
        makeCategoryId: @escaping () -> String = { UUID().uuidString }
    ) {
        self.repository = repository
        self.pairContextProvider = pairContextProvider
        self.year = year
        self.draft = existingCategory.map(TextCategorySettingsDraft.init(category:)) ?? draft
        self.existingCategory = existingCategory
        self.now = now
        self.makeCategoryId = makeCategoryId
        normalizeRankPoints()
    }

    func setInputRankLimit(_ value: Int) {
        draft.inputRankLimit = min(max(value, TextCategoryValidator.rankLimitRange.lowerBound), TextCategoryValidator.rankLimitRange.upperBound)
        if draft.revealRankLimit > draft.inputRankLimit {
            draft.revealRankLimit = draft.inputRankLimit
        }
        normalizeRankPoints()
        clearTransientMessages()
    }

    func setRevealRankLimit(_ value: Int) {
        draft.revealRankLimit = min(max(value, TextCategoryValidator.rankLimitRange.lowerBound), draft.inputRankLimit)
        clearTransientMessages()
    }

    func setPoints(_ points: Int, forRank rank: Int) {
        guard let index = draft.pointsByRank.firstIndex(where: { $0.rank == rank }) else {
            return
        }
        draft.pointsByRank[index].points = max(0, points)
        clearTransientMessages()
    }

    func saveDraft() async {
        clearTransientMessages()
        guard existingCategory?.status != .confirmed, existingCategory?.status != .resultAvailable else {
            validationMessages = ["確定済み部門の設定は変更できません。"]
            return
        }

        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let settings = TextCategorySettings(
            inputRankLimit: draft.inputRankLimit,
            revealRankLimit: draft.revealRankLimit,
            pointsByRank: draft.pointsByRank
        )

        do {
            try validate(name: trimmedName, settings: settings)
        } catch {
            validationMessages = messages(for: error)
            return
        }

        saveState = .saving
        do {
            let context = try await pairContextProvider.currentContext()
            let timestamp = now()
            let category: TextCategory
            if var existingCategory {
                existingCategory.name = trimmedName
                existingCategory.settings = settings
                existingCategory.updatedAt = timestamp
                category = existingCategory
                try await repository.updateDraftCategory(category)
            } else {
                category = TextCategory(
                    id: makeCategoryId(),
                    pairId: context.pairId,
                    year: year,
                    name: trimmedName,
                    status: .draft,
                    settings: settings,
                    generation: 0,
                    createdByUserId: context.userId,
                    confirmedAt: nil,
                    createdAt: timestamp,
                    updatedAt: timestamp
                )
                try await repository.createCategory(category)
            }
            draft.name = trimmedName
            saveState = .saved(categoryId: category.id)
        } catch {
            saveState = .failed("保存できませんでした。通信状況を確認してもう一度お試しください。")
        }
    }

    private func normalizeRankPoints() {
        var pointsByRank = Dictionary(uniqueKeysWithValues: draft.pointsByRank.map { ($0.rank, $0.points) })
        draft.pointsByRank = (1 ... draft.inputRankLimit).map { rank in
            RankPoint(rank: rank, points: pointsByRank[rank] ?? defaultPoints(for: rank))
        }
    }

    private func defaultPoints(for rank: Int) -> Int {
        max(draft.inputRankLimit - rank + 1, 1)
    }

    private func validate(name: String, settings: TextCategorySettings) throws {
        let category = TextCategory(
            id: "validation",
            pairId: "validation",
            year: year,
            name: name,
            status: .draft,
            settings: settings,
            generation: 0,
            createdByUserId: "validation",
            confirmedAt: nil,
            createdAt: now(),
            updatedAt: now()
        )
        try TextCategoryValidator.validate(category: category)
    }

    private func messages(for error: Error) -> [String] {
        guard let validationError = error as? TextCategoryValidationError else {
            return ["入力内容を確認してください。"]
        }
        switch validationError {
        case .blankCategoryName:
            return ["部門名を入力してください。"]
        case .invalidInputRankLimit:
            return ["入力対象順位は1位から50位までにしてください。"]
        case .invalidRevealRankLimit:
            return ["発表対象順位は入力対象順位以内にしてください。"]
        case let .invalidRankPoint(rank):
            return ["\(rank)位のポイントは1以上にしてください。"]
        case let .missingRankPoint(rank):
            return ["\(rank)位のポイントを設定してください。"]
        case let .duplicateRankPoint(rank):
            return ["\(rank)位のポイント設定が重複しています。"]
        default:
            return ["入力内容を確認してください。"]
        }
    }

    private func clearTransientMessages() {
        validationMessages = []
        if case .failed = saveState {
            saveState = .editing
        }
    }
}

private extension TextCategorySettingsDraft {
    init(category: TextCategory) {
        self.init(
            name: category.name,
            inputRankLimit: category.settings.inputRankLimit,
            revealRankLimit: category.settings.revealRankLimit,
            pointsByRank: category.settings.pointsByRank
        )
    }
}
