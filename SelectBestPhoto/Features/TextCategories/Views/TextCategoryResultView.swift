import SwiftUI

struct TextCategoryResultView: View {
    @StateObject private var viewModel: TextCategoryResultViewModel
    private let makeCandidateManagementViewModel: (Int, String) -> TextCandidateManagementViewModel
    private let makeRankingInputViewModel: (Int, String) -> TextRankingInputViewModel
    private let makeWaitingViewModel: (Int, String) -> TextCategoryWaitingViewModel
    private let makeResultViewModel: (Int, String) -> TextCategoryResultViewModel

    init(
        viewModel: TextCategoryResultViewModel,
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
            .navigationTitle("結果")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        viewModel.requestResetConfirmation()
                    } label: {
                        Label("リセット", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(viewModel.screenState != .loaded || viewModel.resetState == .resetting)
                    .accessibilityIdentifier("text-category-result-reset")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.load()
                        }
                    } label: {
                        Label("再表示", systemImage: "arrow.clockwise")
                    }
                }
            }
            .confirmationDialog(
                "部門全体をリセットしますか?",
                isPresented: $viewModel.isResetConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("リセット", role: .destructive) {
                    Task {
                        await viewModel.confirmReset()
                    }
                }
                Button("キャンセル", role: .cancel) {
                    viewModel.cancelResetConfirmation()
                }
            } message: {
                Text(viewModel.resetConfirmationMessage)
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.resetDestinationCategoryId != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.clearResetDestination()
                        }
                    }
                )
            ) {
                if let categoryId = viewModel.resetDestinationCategoryId {
                    TextCandidateManagementView(
                        viewModel: makeCandidateManagementViewModel(viewModel.year, categoryId),
                        makeCandidateManagementViewModel: makeCandidateManagementViewModel,
                        makeRankingInputViewModel: { categoryId in
                            makeRankingInputViewModel(viewModel.year, categoryId)
                        },
                        makeWaitingViewModel: makeWaitingViewModel,
                        makeResultViewModel: makeResultViewModel
                    )
                }
            }
            .task {
                await viewModel.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.screenState {
        case .loading:
            ProgressView("結果を読み込み中")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            List {
                Section {
                    Text(viewModel.title)
                        .font(.headline)
                    if let result = viewModel.result {
                        LabeledContent("発表対象", value: "\(result.entries.count)位まで")
                    }
                }

                Section("発表") {
                    ForEach(viewModel.displayEntries) { state in
                        ResultEntryRow(state: state, userLabel: viewModel.userLabel(for:))
                            .accessibilityIdentifier("text-category-result-entry-\(state.entry.rank)")
                    }
                }

                resetMessageSection
            }
            .listStyle(.insetGrouped)
        case .waitingForPartner:
            ContentUnavailableView {
                Label("まだ公開されていません", systemImage: "lock")
            } description: {
                Text("両方の入力が完了すると結果を表示できます。")
            } actions: {
                Button("再読み込み") {
                    Task {
                        await viewModel.load()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        case let .error(message):
            ContentUnavailableView {
                Label("結果を表示できません", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("再読み込み") {
                    Task {
                        await viewModel.load()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private var resetMessageSection: some View {
        switch viewModel.resetState {
        case .idle:
            EmptyView()
        case .resetting:
            Section {
                Label("リセット中", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(.secondary)
            }
        case let .failed(message):
            Section {
                Label(message, systemImage: "wifi.exclamationmark")
                    .foregroundStyle(.red)
                Button {
                    Task {
                        await viewModel.load()
                    }
                } label: {
                    Label("現在の状態を再読み込み", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}

private struct ResultEntryRow: View {
    let state: TextCategoryResultEntryState
    let userLabel: (String) -> String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TextCandidateImagePlaceholder()

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(state.entry.rank)位")
                        .font(.headline)
                        .foregroundStyle(rankColor)
                    Text(state.entry.candidateName)
                        .font(.headline)
                        .lineLimit(2)
                }

                Label("\(state.entry.totalPoints)ポイント", systemImage: "star.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(state.entry.userBreakdowns) { breakdown in
                    Text(breakdownText(for: breakdown))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(state.accessibilityLabel)
    }

    private var rankColor: Color {
        switch state.entry.rank {
        case 1:
            .yellow
        case 2:
            .gray
        case 3:
            .brown
        default:
            .primary
        }
    }

    private func breakdownText(for breakdown: TextCategoryUserPointBreakdown) -> String {
        let selectedRankText = breakdown.selectedRank.map { "\($0)位" } ?? "未選択"
        return "\(userLabel(breakdown.userId)): \(selectedRankText) / \(breakdown.points)ポイント"
    }
}
