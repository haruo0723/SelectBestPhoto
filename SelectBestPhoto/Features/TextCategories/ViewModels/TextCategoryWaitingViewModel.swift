import Foundation

enum TextCategoryWaitingScreenState: Equatable {
    case loading
    case waiting
    case resultAvailable
    case error(String)
}

struct TextCategoryWaitingStatusItem: Identifiable, Equatable {
    var id: String
    var title: String
    var status: InputStatus

    var statusText: String {
        switch status {
        case .notStarted:
            "未入力"
        case .inProgress:
            "入力中"
        case .completed:
            "完了"
        }
    }

    var systemImage: String {
        switch status {
        case .notStarted:
            "circle"
        case .inProgress:
            "pencil.circle"
        case .completed:
            "checkmark.circle.fill"
        }
    }
}

@MainActor
final class TextCategoryWaitingViewModel: ObservableObject {
    @Published private(set) var screenState: TextCategoryWaitingScreenState = .loading
    @Published private(set) var category: TextCategory?
    @Published private(set) var statusItems: [TextCategoryWaitingStatusItem] = []
    @Published private(set) var resultCategoryId: String?

    let year: Int
    let categoryId: String

    private let repository: TextCategoryRepository
    private let pairContextProvider: PairContextProviding
    private var observationTask: Task<Void, Never>?
    private var context: PairContext?

    var title: String {
        category?.name ?? "待機"
    }

    var canShowResult: Bool {
        screenState == .resultAvailable
    }

    init(
        repository: TextCategoryRepository,
        pairContextProvider: PairContextProviding,
        year: Int,
        categoryId: String
    ) {
        self.repository = repository
        self.pairContextProvider = pairContextProvider
        self.year = year
        self.categoryId = categoryId
    }

    deinit {
        observationTask?.cancel()
    }

    func load() {
        observationTask?.cancel()
        screenState = .loading
        resultCategoryId = nil
        observationTask = Task { [weak self] in
            guard let self else {
                return
            }
            do {
                let context = try await pairContextProvider.currentContext()
                guard context.partnerUserId != nil else {
                    screenState = .error("ペア設定を確認できませんでした。")
                    return
                }
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
                screenState = .error("入力状況を読み込めませんでした。")
            }
        }
    }

    func showResult() {
        guard canShowResult else {
            return
        }
        resultCategoryId = categoryId
    }

    func clearResultDestination() {
        resultCategoryId = nil
    }

    private func apply(category: TextCategory, context: PairContext) {
        self.category = category
        let ownStatus = category.inputStatuses[context.userId] ?? .notStarted
        let partnerStatus = context.partnerUserId.flatMap { category.inputStatuses[$0] } ?? .notStarted
        statusItems = [
            TextCategoryWaitingStatusItem(id: "own", title: "自分", status: ownStatus),
            TextCategoryWaitingStatusItem(id: "partner", title: "相手", status: partnerStatus),
        ]
        if category.status == .resultAvailable || (ownStatus == .completed && partnerStatus == .completed) {
            screenState = .resultAvailable
        } else {
            screenState = .waiting
        }
    }
}
