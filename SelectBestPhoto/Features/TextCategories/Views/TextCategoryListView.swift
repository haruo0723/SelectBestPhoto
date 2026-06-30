import SwiftUI

struct TextCategoryListView: View {
    @StateObject private var viewModel: TextCategoryListViewModel
    private let makeSettingsViewModel: (Int) -> TextCategorySettingsViewModel
    private let makeCandidateManagementViewModel: (Int, String) -> TextCandidateManagementViewModel
    private let makeRankingInputViewModel: (Int, String) -> TextRankingInputViewModel
    private let makeWaitingViewModel: (Int, String) -> TextCategoryWaitingViewModel
    private let makeResultViewModel: (Int, String) -> TextCategoryResultViewModel

    init(
        viewModel: TextCategoryListViewModel,
        makeSettingsViewModel: @escaping (Int) -> TextCategorySettingsViewModel,
        makeCandidateManagementViewModel: @escaping (Int, String) -> TextCandidateManagementViewModel,
        makeRankingInputViewModel: @escaping (Int, String) -> TextRankingInputViewModel,
        makeWaitingViewModel: @escaping (Int, String) -> TextCategoryWaitingViewModel,
        makeResultViewModel: @escaping (Int, String) -> TextCategoryResultViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeSettingsViewModel = makeSettingsViewModel
        self.makeCandidateManagementViewModel = makeCandidateManagementViewModel
        self.makeRankingInputViewModel = makeRankingInputViewModel
        self.makeWaitingViewModel = makeWaitingViewModel
        self.makeResultViewModel = makeResultViewModel
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("カスタム部門")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            ForEach(viewModel.availableYears, id: \.self) { year in
                                Button("\(year)年") {
                                    viewModel.changeYear(to: year)
                                }
                            }
                        } label: {
                            Label("\(viewModel.selectedYear)年", systemImage: "calendar")
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(value: TextCategoryListRoute.categorySettings("new")) {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("部門を作成")
                    }
                }
                .navigationDestination(for: TextCategoryListRoute.self) { route in
                    switch route {
                    case .categorySettings:
                        TextCategorySettingsView(
                            viewModel: makeSettingsViewModel(viewModel.selectedYear),
                            makeCandidateManagementViewModel: { categoryId in
                                makeCandidateManagementViewModel(viewModel.selectedYear, categoryId)
                            },
                            makeRankingInputViewModel: { categoryId in
                                makeRankingInputViewModel(viewModel.selectedYear, categoryId)
                            },
                            makeWaitingViewModel: { year, categoryId in
                                makeWaitingViewModel(year, categoryId)
                            },
                            makeResultViewModel: { year, categoryId in
                                makeResultViewModel(year, categoryId)
                            }
                        )
                    case let .candidateManagement(categoryId):
                        TextCandidateManagementView(
                            viewModel: makeCandidateManagementViewModel(viewModel.selectedYear, categoryId),
                            makeCandidateManagementViewModel: makeCandidateManagementViewModel,
                            makeRankingInputViewModel: { categoryId in
                                makeRankingInputViewModel(viewModel.selectedYear, categoryId)
                            },
                            makeWaitingViewModel: { year, categoryId in
                                makeWaitingViewModel(year, categoryId)
                            },
                            makeResultViewModel: { year, categoryId in
                                makeResultViewModel(year, categoryId)
                            }
                        )
                    case let .rankingInput(categoryId):
                        TextRankingInputView(
                            viewModel: makeRankingInputViewModel(viewModel.selectedYear, categoryId),
                            makeCandidateManagementViewModel: makeCandidateManagementViewModel,
                            makeRankingInputViewModel: makeRankingInputViewModel,
                            makeWaitingViewModel: { year, categoryId in
                                makeWaitingViewModel(year, categoryId)
                            },
                            makeResultViewModel: { year, categoryId in
                                makeResultViewModel(year, categoryId)
                            }
                        )
                    case let .waiting(categoryId):
                        TextCategoryWaitingView(
                            viewModel: makeWaitingViewModel(viewModel.selectedYear, categoryId),
                            makeCandidateManagementViewModel: makeCandidateManagementViewModel,
                            makeRankingInputViewModel: makeRankingInputViewModel,
                            makeWaitingViewModel: makeWaitingViewModel,
                            makeResultViewModel: { year, categoryId in
                                makeResultViewModel(year, categoryId)
                            }
                        )
                    case let .result(categoryId):
                        TextCategoryResultView(
                            viewModel: makeResultViewModel(viewModel.selectedYear, categoryId),
                            makeCandidateManagementViewModel: makeCandidateManagementViewModel,
                            makeRankingInputViewModel: makeRankingInputViewModel,
                            makeWaitingViewModel: makeWaitingViewModel,
                            makeResultViewModel: makeResultViewModel
                        )
                    }
                }
        }
        .task {
            viewModel.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.screenState {
        case .loading:
            ProgressView("読み込み中")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            ContentUnavailableView {
                Label("部門がありません", systemImage: "text.badge.plus")
            } description: {
                Text("\(viewModel.selectedYear)年のテキスト候補型カスタム部門を作成できます。")
            } actions: {
                NavigationLink(value: TextCategoryListRoute.categorySettings("new")) {
                    Label("新規作成", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        case .loaded:
            List(viewModel.rows) { row in
                NavigationLink(value: row.route) {
                    TextCategoryRowView(row: row)
                }
                .accessibilityIdentifier("text-category-row-\(row.category.id)")
            }
            .listStyle(.insetGrouped)
        case let .error(message):
            ContentUnavailableView {
                Label("読み込めませんでした", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("再読み込み") {
                    viewModel.load()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct TextCategoryRowView: View {
    let row: TextCategoryListRowState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(row.category.name)
                    .font(.headline)
                    .lineLimit(2)

                Spacer(minLength: 8)

                Text(row.statusText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusBackground)
                    .foregroundStyle(statusForeground)
                    .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                Label(row.ownInputText, systemImage: iconName(for: row.ownInputStatus))
                Label(row.partnerInputText, systemImage: iconName(for: row.partnerInputStatus))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)

            Label(row.resultAvailabilityText, systemImage: row.canShowResult ? "party.popper" : "lock")
                .font(.footnote)
                .foregroundStyle(row.canShowResult ? .green : .secondary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }

    private var statusBackground: Color {
        switch row.category.status {
        case .draft:
            Color.orange.opacity(0.15)
        case .confirmed:
            Color.blue.opacity(0.15)
        case .resultAvailable:
            Color.green.opacity(0.15)
        }
    }

    private var statusForeground: Color {
        switch row.category.status {
        case .draft:
            .orange
        case .confirmed:
            .blue
        case .resultAvailable:
            .green
        }
    }

    private func iconName(for status: InputStatus) -> String {
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

struct TextCategoryPlaceholderView: View {
    let route: TextCategoryListRoute

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text("この画面は後続タスクで実装します。"))
            .navigationTitle(title)
    }

    private var title: String {
        switch route {
        case .categorySettings:
            "部門設定"
        case .candidateManagement:
            "候補管理"
        case .rankingInput:
            "順位入力"
        case .waiting:
            "待機"
        case .result:
            "結果"
        }
    }

    private var systemImage: String {
        switch route {
        case .categorySettings:
            "slider.horizontal.3"
        case .candidateManagement:
            "list.bullet.rectangle"
        case .rankingInput:
            "checklist"
        case .waiting:
            "hourglass"
        case .result:
            "trophy"
        }
    }
}
