import SwiftUI

struct TextCategoryWaitingView: View {
    @StateObject private var viewModel: TextCategoryWaitingViewModel
    private let makeCandidateManagementViewModel: (Int, String) -> TextCandidateManagementViewModel
    private let makeRankingInputViewModel: (Int, String) -> TextRankingInputViewModel
    private let makeWaitingViewModel: (Int, String) -> TextCategoryWaitingViewModel
    private let makeResultViewModel: (Int, String) -> TextCategoryResultViewModel

    init(
        viewModel: TextCategoryWaitingViewModel,
        makeCandidateManagementViewModel: @escaping (Int, String) -> TextCandidateManagementViewModel,
        makeRankingInputViewModel: @escaping (Int, String) -> TextRankingInputViewModel,
        makeWaitingViewModel: @escaping (Int, String) -> TextCategoryWaitingViewModel,
        makeResultViewModel: @escaping (Int, String) -> TextCategoryResultViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeCandidateManagementViewModel = makeCandidateManagementViewModel
        self.makeRankingInputViewModel = makeRankingInputViewModel
        self.makeWaitingViewModel = makeWaitingViewModel
        self.makeResultViewModel = makeResultViewModel
    }

    var body: some View {
        content
            .navigationTitle("待機")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.load()
                    } label: {
                        Label("再読み込み", systemImage: "arrow.clockwise")
                    }
                }
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.resultCategoryId != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.clearResultDestination()
                        }
                    }
                )
            ) {
                if let categoryId = viewModel.resultCategoryId {
                    TextCategoryResultView(
                        viewModel: makeResultViewModel(viewModel.year, categoryId),
                        makeCandidateManagementViewModel: makeCandidateManagementViewModel,
                        makeRankingInputViewModel: makeRankingInputViewModel,
                        makeWaitingViewModel: makeWaitingViewModel,
                        makeResultViewModel: makeResultViewModel
                    )
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
        case .waiting, .resultAvailable:
            List {
                Section {
                    Text(viewModel.title)
                        .font(.headline)
                    Text("相手の入力内容と集計結果は、両方の入力が完了するまで表示されません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("入力状況") {
                    ForEach(viewModel.statusItems) { item in
                        LabeledContent {
                            Label(item.statusText, systemImage: item.systemImage)
                        } label: {
                            Text(item.title)
                        }
                    }
                }

                Section {
                    Button {
                        viewModel.showResult()
                    } label: {
                        Label("結果を見る", systemImage: "trophy")
                    }
                    .disabled(!viewModel.canShowResult)
                    .accessibilityIdentifier("text-category-waiting-show-result")
                } footer: {
                    Text(viewModel.canShowResult ? "結果を表示できます。" : "相手の入力完了を待っています。")
                }
            }
            .listStyle(.insetGrouped)
        case let .error(message):
            ContentUnavailableView {
                Label("入力状況を確認できません", systemImage: "exclamationmark.triangle")
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
