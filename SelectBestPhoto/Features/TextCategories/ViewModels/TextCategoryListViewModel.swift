import Foundation

enum TextCategoryListRoute: Equatable, Hashable {
    case categorySettings(String)
    case candidateManagement(String)
    case rankingInput(String)
    case waiting(String)
    case result(String)
}

enum TextCategoryListScreenState: Equatable {
    case loading
    case empty
    case loaded
    case error(String)
}

struct TextCategoryInputStatusPair: Equatable {
    var own: InputStatus
    var partner: InputStatus

    static let notStarted = TextCategoryInputStatusPair(own: .notStarted, partner: .notStarted)
}

struct TextCategoryListRowState: Identifiable, Equatable {
    var id: String {
        category.id
    }

    var category: TextCategory
    var ownInputStatus: InputStatus
    var partnerInputStatus: InputStatus

    var route: TextCategoryListRoute {
        switch category.status {
        case .draft:
            .candidateManagement(category.id)
        case .confirmed:
            if ownInputStatus == .completed, partnerInputStatus == .completed {
                .result(category.id)
            } else if ownInputStatus == .completed {
                .waiting(category.id)
            } else {
                .rankingInput(category.id)
            }
        case .resultAvailable:
            .result(category.id)
        }
    }

    var statusText: String {
        switch category.status {
        case .draft:
            "準備中"
        case .confirmed:
            "入力受付中"
        case .resultAvailable:
            "結果公開中"
        }
    }

    var ownInputText: String {
        "自分: \(text(for: ownInputStatus))"
    }

    var partnerInputText: String {
        "相手: \(text(for: partnerInputStatus))"
    }

    var resultAvailabilityText: String {
        canShowResult ? "結果を表示できます" : "結果は未公開"
    }

    var canShowResult: Bool {
        category.status == .resultAvailable || (ownInputStatus == .completed && partnerInputStatus == .completed)
    }

    private func text(for status: InputStatus) -> String {
        switch status {
        case .notStarted:
            "未入力"
        case .inProgress:
            "入力中"
        case .completed:
            "完了"
        }
    }
}

@MainActor
final class TextCategoryListViewModel: ObservableObject {
    @Published private(set) var screenState: TextCategoryListScreenState = .loading
    @Published private(set) var rows: [TextCategoryListRowState] = []
    @Published var selectedYear: Int

    let availableYears: [Int]

    private let repository: TextCategoryRepository
    private let pairContextProvider: PairContextProviding
    private let currentUserId: String
    private let partnerUserId: String
    private var inputStatuses: [String: TextCategoryInputStatusPair]
    private var observationTask: Task<Void, Never>?

    init(
        repository: TextCategoryRepository,
        pairContextProvider: PairContextProviding,
        initialYear: Int = Calendar.current.component(.year, from: Date()),
        availableYears: [Int]? = nil,
        currentUserId: String,
        partnerUserId: String,
        inputStatuses: [String: TextCategoryInputStatusPair] = [:]
    ) {
        self.repository = repository
        self.pairContextProvider = pairContextProvider
        selectedYear = initialYear
        self.availableYears = availableYears ?? Array((initialYear - 2) ... (initialYear + 1)).reversed()
        self.currentUserId = currentUserId
        self.partnerUserId = partnerUserId
        self.inputStatuses = inputStatuses
    }

    deinit {
        observationTask?.cancel()
    }

    func load() {
        observationTask?.cancel()
        screenState = .loading
        observationTask = Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let context = try await pairContextProvider.currentContext()
                for try await categories in repository.observeCategories(pairId: context.pairId, year: selectedYear) {
                    apply(categories: categories)
                }
            } catch {
                if Task.isCancelled {
                    return
                }
                screenState = .error("部門一覧を読み込めませんでした。")
            }
        }
    }

    func changeYear(to year: Int) {
        guard selectedYear != year else {
            return
        }
        selectedYear = year
        load()
    }

    func updateInputStatuses(_ statuses: [String: TextCategoryInputStatusPair]) {
        inputStatuses = statuses
        rows = rows.map { row in
            let status = statuses[row.category.id] ?? .notStarted
            return TextCategoryListRowState(
                category: row.category,
                ownInputStatus: status.own,
                partnerInputStatus: status.partner
            )
        }
        screenState = rows.isEmpty ? .empty : .loaded
    }

    private func apply(categories: [TextCategory]) {
        rows = categories
            .sorted { lhs, rhs in
                if lhs.updatedAt == rhs.updatedAt {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhs.updatedAt > rhs.updatedAt
            }
            .map { category in
                let status = inputStatuses[category.id] ?? .notStarted
                return TextCategoryListRowState(
                    category: category,
                    ownInputStatus: status.own,
                    partnerInputStatus: status.partner
                )
            }
        screenState = rows.isEmpty ? .empty : .loaded
    }
}
