import Foundation

enum TextCategoryResultScreenState: Equatable {
    case loading
    case loaded
    case waitingForPartner
    case error(String)
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

    let year: Int
    let categoryId: String

    private let repository: TextCategoryRepository
    private let pairContextProvider: PairContextProviding
    private let calculator: TextCategoryResultCalculating
    private var context: PairContext?

    var title: String {
        category?.name ?? "結果"
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
            try await repository.saveResultIfNeeded(result)
            apply(result: result)
        } catch TextCategoryRepositoryError.inputsNotCompleted {
            screenState = .waitingForPartner
        } catch {
            screenState = .error("結果を読み込めませんでした。")
        }
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
