import Foundation

enum TextCategoryResultScreenState: Equatable {
    case loading
    case loaded
    case waitingForPartner
    case error(String)
}

enum TextCategoryResetState: Equatable {
    case idle
    case resetting
    case failed(String)
}

struct TextCategoryResultEntryState: Identifiable, Equatable {
    var id: String {
        entry.id
    }

    var entry: TextCategoryResultEntry

    var accessibilityLabel: String {
        "\(entry.rank)位、\(entry.candidateName)、合計\(entry.totalPoints)ポイント"
    }
}

@MainActor
final class TextCategoryResultViewModel: ObservableObject {
    @Published private(set) var screenState: TextCategoryResultScreenState = .loading
    @Published private(set) var category: TextCategory?
    @Published private(set) var result: TextCategoryResult?
    @Published private(set) var displayEntries: [TextCategoryResultEntryState] = []
    @Published private(set) var resetState: TextCategoryResetState = .idle
    @Published private(set) var resetDestinationCategoryId: String?
    @Published var isResetConfirmationPresented = false

    let year: Int
    let categoryId: String

    private let repository: TextCategoryRepository
    private let pairContextProvider: PairContextProviding
    private let calculator: TextCategoryResultCalculating
    private var context: PairContext?

    var title: String {
        category?.name ?? "結果"
    }

    var resetConfirmationMessage: String {
        "この部門全体をリセットします。候補と部門設定は残りますが、2人分の順位入力、入力状態、生成済み結果は削除または無効化されます。"
    }

    init(
        repository: TextCategoryRepository,
        pairContextProvider: PairContextProviding,
        calculator: TextCategoryResultCalculating = TextCategoryResultCalculator(),
        year: Int,
        categoryId: String
    ) {
        self.repository = repository
        self.pairContextProvider = pairContextProvider
        self.calculator = calculator
        self.year = year
        self.categoryId = categoryId
    }

    func load() async {
        screenState = .loading
        resetState = .idle
        do {
            let context = try await pairContextProvider.currentContext()
            self.context = context
            let resultContext = try await repository.loadResultContext(
                pairId: context.pairId,
                year: year,
                categoryId: categoryId
            )
            category = resultContext.category
            let result = try calculator.calculate(
                category: resultContext.category,
                candidates: resultContext.candidates,
                inputs: resultContext.inputs
            )
            let savedResult = try await repository.saveResultIfNeeded(result)
            apply(result: savedResult)
        } catch TextCategoryRepositoryError.inputsNotCompleted {
            screenState = .waitingForPartner
        } catch {
            screenState = .error("結果を読み込めませんでした。")
        }
    }

    func requestResetConfirmation() {
        guard screenState == .loaded else {
            return
        }
        isResetConfirmationPresented = true
    }

    func cancelResetConfirmation() {
        isResetConfirmationPresented = false
    }

    func confirmReset() async {
        isResetConfirmationPresented = false
        guard resetState != .resetting else {
            return
        }
        do {
            let context = try await pairContextProvider.currentContext()
            resetState = .resetting
            try await repository.resetCategory(pairId: context.pairId, year: year, categoryId: categoryId)
            resetState = .idle
            resetDestinationCategoryId = categoryId
        } catch {
            resetState = .failed("リセットできませんでした。現在の状態を再読み込みするか、もう一度お試しください。")
        }
    }

    func clearResetDestination() {
        resetDestinationCategoryId = nil
    }

    func userLabel(for userId: String) -> String {
        guard let context else {
            return "ユーザー"
        }
        if userId == context.userId {
            return "自分"
        }
        if userId == context.partnerUserId {
            return "相手"
        }
        return "ユーザー"
    }

    private func apply(result: TextCategoryResult) {
        self.result = result
        displayEntries = result.entries
            .sorted { lhs, rhs in
                lhs.rank > rhs.rank
            }
            .map(TextCategoryResultEntryState.init(entry:))
        screenState = .loaded
    }
}
