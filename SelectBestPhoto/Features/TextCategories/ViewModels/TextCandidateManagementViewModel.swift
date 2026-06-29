import Foundation

enum TextCandidateManagementScreenState: Equatable {
    case loading
    case loaded
    case error(String)
}

enum TextCandidateManagementActionState: Equatable {
    case idle
    case saving
    case confirming
    case failed(String)
}

struct TextCandidateRowState: Identifiable, Equatable {
    var id: String {
        candidate.id
    }

    var candidate: TextCandidate
    var draftName: String
}

@MainActor
final class TextCandidateManagementViewModel: ObservableObject {
    @Published private(set) var screenState: TextCandidateManagementScreenState = .loading
    @Published private(set) var category: TextCategory?
    @Published private(set) var rows: [TextCandidateRowState] = []
    @Published private(set) var validationMessages: [String] = []
    @Published private(set) var actionState: TextCandidateManagementActionState = .idle
    @Published var newCandidateName = ""
    @Published private(set) var confirmedCategoryId: String?

    let year: Int
    let categoryId: String

    private let repository: TextCategoryRepository
    private let pairContextProvider: PairContextProviding
    private let now: () -> Date
    private let makeCandidateId: () -> String
    private var context: PairContext?
    private var categoryObservationTask: Task<Void, Never>?
    private var candidateObservationTask: Task<Void, Never>?

    var isEditable: Bool {
        category?.status == .draft && actionState != .saving && actionState != .confirming
    }

    var canConfirm: Bool {
        guard let category else {
            return false
        }
        return isEditable && rows.count >= category.settings.inputRankLimit
    }

    var candidateCountText: String {
        guard let category else {
            return "\(rows.count)件"
        }
        return "\(rows.count)/\(category.settings.inputRankLimit)件"
    }

    var confirmationHint: String {
        guard let category else {
            return "部門を読み込み中です。"
        }
        if category.status != .draft {
            return "確定済みのため候補と設定は変更できません。"
        }
        let shortage = category.settings.inputRankLimit - rows.count
        if shortage > 0 {
            return "確定にはあと\(shortage)件の候補が必要です。"
        }
        return "候補と部門設定を確定できます。"
    }

    init(
        repository: TextCategoryRepository,
        pairContextProvider: PairContextProviding,
        year: Int,
        categoryId: String,
        now: @escaping () -> Date = Date.init,
        makeCandidateId: @escaping () -> String = { UUID().uuidString }
    ) {
        self.repository = repository
        self.pairContextProvider = pairContextProvider
        self.year = year
        self.categoryId = categoryId
        self.now = now
        self.makeCandidateId = makeCandidateId
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
                screenState = .error("候補管理を読み込めませんでした。")
            }
        }
    }

    func addCandidate() async {
        clearTransientMessages()
        guard let context, let category, isEditable else {
            validationMessages = ["確定済み部門の候補は変更できません。"]
            return
        }
        let name = newCandidateName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            validationMessages = ["候補名を入力してください。"]
            return
        }

        let timestamp = now()
        let candidate = TextCandidate(
            id: makeCandidateId(),
            pairId: context.pairId,
            year: year,
            categoryId: category.id,
            name: name,
            imagePlaceholderKind: .futureImageSlot,
            createdByUserId: context.userId,
            createdAt: timestamp,
            updatedAt: timestamp
        )

        actionState = .saving
        do {
            try await repository.addCandidate(candidate)
            newCandidateName = ""
            actionState = .idle
        } catch {
            actionState = .failed("候補を保存できませんでした。入力内容を残したまま再試行できます。")
        }
    }

    func updateDraftName(_ name: String, forCandidateId candidateId: String) {
        guard let index = rows.firstIndex(where: { $0.id == candidateId }) else {
            return
        }
        rows[index].draftName = name
        clearTransientMessages()
    }

    func saveCandidateName(candidateId: String) async {
        clearTransientMessages()
        guard isEditable else {
            validationMessages = ["確定済み部門の候補は変更できません。"]
            return
        }
        guard let index = rows.firstIndex(where: { $0.id == candidateId }) else {
            return
        }
        let name = rows[index].draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            validationMessages = ["候補名を入力してください。"]
            return
        }

        var candidate = rows[index].candidate
        candidate.name = name
        candidate.updatedAt = now()

        actionState = .saving
        do {
            try await repository.updateCandidate(candidate)
            actionState = .idle
        } catch {
            actionState = .failed("候補名を保存できませんでした。")
        }
    }

    func deleteCandidate(candidateId: String) async {
        clearTransientMessages()
        guard let context, isEditable else {
            validationMessages = ["確定済み部門の候補は変更できません。"]
            return
        }
        actionState = .saving
        do {
            try await repository.deleteCandidate(
                pairId: context.pairId,
                year: year,
                categoryId: categoryId,
                candidateId: candidateId
            )
            actionState = .idle
        } catch {
            actionState = .failed("候補を削除できませんでした。")
        }
    }

    func confirmCategory() async {
        clearTransientMessages()
        guard let context, let category else {
            validationMessages = ["部門を読み込んでから確定してください。"]
            return
        }
        guard rows.count >= category.settings.inputRankLimit else {
            validationMessages = ["候補数が入力対象順位に足りません。"]
            return
        }
        guard isEditable else {
            validationMessages = ["確定済み部門の候補は変更できません。"]
            return
        }

        actionState = .confirming
        do {
            try await repository.confirmCategory(pairId: context.pairId, year: year, categoryId: category.id)
            confirmedCategoryId = category.id
            actionState = .idle
        } catch TextCategoryRepositoryError.insufficientCandidates {
            actionState = .idle
            validationMessages = ["候補数が入力対象順位に足りません。"]
        } catch {
            actionState = .failed("候補と設定を確定できませんでした。")
        }
    }

    func clearConfirmedCategoryNavigation() {
        confirmedCategoryId = nil
    }

    private func apply(category: TextCategory, context: PairContext) {
        self.category = category
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
        rows = candidates
            .sorted { lhs, rhs in
                if lhs.createdAt == rhs.createdAt {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhs.createdAt < rhs.createdAt
            }
            .map { candidate in
                if let existing = rows.first(where: { $0.id == candidate.id }), existing.candidate.name == candidate.name {
                    return TextCandidateRowState(candidate: candidate, draftName: existing.draftName)
                }
                return TextCandidateRowState(candidate: candidate, draftName: candidate.name)
            }
        screenState = .loaded
    }

    private func clearTransientMessages() {
        validationMessages = []
        if case .failed = actionState {
            actionState = .idle
        }
    }
}
