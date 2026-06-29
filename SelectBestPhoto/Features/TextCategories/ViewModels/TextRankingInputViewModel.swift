import Foundation

enum TextRankingInputScreenState: Equatable {
    case loading
    case loaded
    case error(String)
}

enum TextRankingInputSaveState: Equatable {
    case idle
    case saving
    case completing
    case failed(String)
}

enum TextRankingInputCompletionDestination: Equatable {
    case waiting(String)
    case result(String)
}

struct TextRankingSlotState: Identifiable, Equatable {
    var id: Int {
        rank
    }

    var rank: Int
    var candidate: TextCandidate?

    var accessibilityLabel: String {
        if let candidate {
            "\(rank)位、\(candidate.name)、選択済み"
        } else {
            "\(rank)位、未選択"
        }
    }
}

@MainActor
final class TextRankingInputViewModel: ObservableObject {
    @Published private(set) var screenState: TextRankingInputScreenState = .loading
    @Published private(set) var category: TextCategory?
    @Published private(set) var candidates: [TextCandidate] = []
    @Published private(set) var selectionsByRank: [Int: String] = [:]
    @Published private(set) var validationMessages: [String] = []
    @Published private(set) var saveState: TextRankingInputSaveState = .idle
    @Published private(set) var completionDestination: TextRankingInputCompletionDestination?

    let year: Int
    let categoryId: String

    private let repository: TextCategoryRepository
    private let pairContextProvider: PairContextProviding
    private let now: () -> Date
    private var context: PairContext?
    private var categoryObservationTask: Task<Void, Never>?
    private var candidateObservationTask: Task<Void, Never>?

    var title: String {
        category?.name ?? "順位入力"
    }

    var slots: [TextRankingSlotState] {
        guard let category else {
            return []
        }
        let candidatesById = Dictionary(uniqueKeysWithValues: candidates.map { ($0.id, $0) })
        return (1 ... category.settings.inputRankLimit).map { rank in
            TextRankingSlotState(rank: rank, candidate: selectionsByRank[rank].flatMap { candidatesById[$0] })
        }
    }

    var selectedCandidateIds: Set<String> {
        Set(selectionsByRank.values)
    }

    var canComplete: Bool {
        guard let category else {
            return false
        }
        return category.status == .confirmed
            && candidates.count >= category.settings.inputRankLimit
            && selectionsByRank.count == category.settings.inputRankLimit
            && selectedCandidateIds.count == category.settings.inputRankLimit
            && saveState != .saving
            && saveState != .completing
    }

    var progressText: String {
        guard let category else {
            return "読み込み中"
        }
        return "\(selectionsByRank.count)/\(category.settings.inputRankLimit)位"
    }

    init(
        repository: TextCategoryRepository,
        pairContextProvider: PairContextProviding,
        year: Int,
        categoryId: String,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.pairContextProvider = pairContextProvider
        self.year = year
        self.categoryId = categoryId
        self.now = now
    }

    deinit {
        categoryObservationTask?.cancel()
        candidateObservationTask?.cancel()
    }

    func load() {
        categoryObservationTask?.cancel()
        candidateObservationTask?.cancel()
        categoryObservationTask = nil
        candidateObservationTask = nil
        screenState = .loading
        categoryObservationTask = Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let context = try await pairContextProvider.currentContext()
                self.context = context
                for try await categories in repository.observeCategories(pairId: context.pairId, year: year) {
                    guard let category = categories.first(where: { $0.id == categoryId }) else {
                        screenState = .error("部門を読み込めませんでした。")
                        return
                    }
                    apply(category: category, context: context)
                }
            } catch {
                if Task.isCancelled {
                    return
                }
                screenState = .error("順位入力を読み込めませんでした。")
            }
        }
    }

    func selectCandidate(_ candidateId: String, forRank rank: Int) async {
        clearTransientMessages()
        guard canEditRank(rank), candidates.contains(where: { $0.id == candidateId }) else {
            validationMessages = ["選択できない候補です。"]
            return
        }
        for (existingRank, existingCandidateId) in selectionsByRank where existingCandidateId == candidateId && existingRank != rank {
            selectionsByRank.removeValue(forKey: existingRank)
        }
        selectionsByRank[rank] = candidateId
        await saveDraft()
    }

    func clearSelection(forRank rank: Int) async {
        clearTransientMessages()
        guard selectionsByRank[rank] != nil else {
            return
        }
        selectionsByRank.removeValue(forKey: rank)
        await saveDraft()
    }

    func completeInput() async {
        clearTransientMessages()
        guard canComplete else {
            validationMessages = completionValidationMessages()
            return
        }
        guard let input = makeInput(status: .completed) else {
            validationMessages = ["順位入力を読み込んでから完了してください。"]
            return
        }

        saveState = .completing
        do {
            try await repository.completeInput(input)
            saveState = .idle
            completionDestination = nextDestination()
        } catch {
            saveState = .failed("入力を完了できませんでした。")
        }
    }

    func clearCompletionDestination() {
        completionDestination = nil
    }

    func isCandidateSelectedElsewhere(_ candidateId: String, forRank rank: Int) -> Bool {
        selectionsByRank.contains { existingRank, selectedCandidateId in
            existingRank != rank && selectedCandidateId == candidateId
        }
    }

    private func saveDraft() async {
        guard let input = makeInput(status: .inProgress) else {
            validationMessages = ["順位入力を読み込んでから保存してください。"]
            return
        }
        saveState = .saving
        do {
            try await repository.saveInput(input)
            saveState = .idle
        } catch {
            saveState = .failed("入力を保存できませんでした。選択内容を残したまま再試行できます。")
        }
    }

    private func apply(category: TextCategory, context: PairContext) {
        self.category = category
        if category.status == .draft {
            screenState = .error("候補と設定が確定されていません。")
            return
        }
        if candidateObservationTask == nil {
            candidateObservationTask = Task { [weak self] in
                guard let self else {
                    return
                }
                do {
                    for try await candidates in repository.observeCandidates(
                        pairId: context.pairId,
                        year: year,
                        categoryId: category.id
                    ) {
                        apply(candidates: candidates)
                    }
                } catch {
                    if Task.isCancelled {
                        return
                    }
                    screenState = .error("候補一覧を読み込めませんでした。")
                }
            }
        }
    }

    private func apply(candidates: [TextCandidate]) {
        let sortedCandidates = candidates.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            return lhs.createdAt < rhs.createdAt
        }
        self.candidates = sortedCandidates
        let validCandidateIds = Set(sortedCandidates.map(\.id))
        selectionsByRank = selectionsByRank.filter { validCandidateIds.contains($0.value) }
        screenState = .loaded
    }

    private func makeInput(status: InputStatus) -> TextCategoryInput? {
        guard let context, let category else {
            return nil
        }
        let timestamp = now()
        return TextCategoryInput(
            id: context.userId,
            pairId: context.pairId,
            year: year,
            categoryId: category.id,
            userId: context.userId,
            generation: category.generation,
            status: status,
            selections: selectionsByRank
                .sorted { $0.key < $1.key }
                .map { rank, candidateId in
                    RankedTextSelection(rank: rank, candidateId: candidateId)
                },
            completedAt: status == .completed ? timestamp : nil,
            updatedAt: timestamp
        )
    }

    private func canEditRank(_ rank: Int) -> Bool {
        guard let category else {
            return false
        }
        return category.status == .confirmed && 1 ... category.settings.inputRankLimit ~= rank
    }

    private func completionValidationMessages() -> [String] {
        guard let category else {
            return ["順位入力を読み込んでください。"]
        }
        if category.status != .confirmed {
            return ["候補と設定が確定されていません。"]
        }
        if candidates.count < category.settings.inputRankLimit {
            return ["候補数が入力対象順位に足りません。"]
        }
        if selectionsByRank.count < category.settings.inputRankLimit {
            return ["すべての順位に候補を選んでください。"]
        }
        if selectedCandidateIds.count != selectionsByRank.count {
            return ["同じ候補を複数順位に選ぶことはできません。"]
        }
        return ["入力内容を確認してください。"]
    }

    private func nextDestination() -> TextRankingInputCompletionDestination {
        guard let category, let context else {
            return .waiting(categoryId)
        }
        let partnerStatus = context.partnerUserId.flatMap { category.inputStatuses[$0] } ?? .notStarted
        if partnerStatus == .completed {
            return .result(category.id)
        }
        return .waiting(category.id)
    }

    private func clearTransientMessages() {
        validationMessages = []
        if case .failed = saveState {
            saveState = .idle
        }
    }
}
