import SwiftUI

struct TextRankingInputView: View {
    @StateObject private var viewModel: TextRankingInputViewModel
    @State private var selectingRank: Int?
    @State private var candidateSearchText = ""
    private let makeWaitingViewModel: (Int, String) -> TextCategoryWaitingViewModel
    private let makeResultViewModel: (Int, String) -> TextCategoryResultViewModel

    init(
        viewModel: TextRankingInputViewModel,
        makeWaitingViewModel: @escaping (Int, String) -> TextCategoryWaitingViewModel,
        makeResultViewModel: @escaping (Int, String) -> TextCategoryResultViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeWaitingViewModel = makeWaitingViewModel
        self.makeResultViewModel = makeResultViewModel
    }

    var body: some View {
        content
            .navigationTitle("順位入力")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.completeInput()
                        }
                    } label: {
                        if viewModel.saveState == .completing {
                            ProgressView()
                        } else {
                            Label("完了", systemImage: "checkmark.circle")
                        }
                    }
                    .disabled(!viewModel.canComplete)
                    .accessibilityIdentifier("text-ranking-complete")
                }
            }
            .sheet(
                isPresented: Binding(
                    get: { selectingRank != nil },
                    set: { isPresented in
                        if !isPresented {
                            selectingRank = nil
                            candidateSearchText = ""
                        }
                    }
                )
            ) {
                candidateSelectionSheet
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.completionDestination != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.clearCompletionDestination()
                        }
                    }
                )
            ) {
                if let destination = viewModel.completionDestination {
                    switch destination {
                    case let .waiting(categoryId):
                        TextCategoryWaitingView(
                            viewModel: makeWaitingViewModel(viewModel.year, categoryId),
                            makeResultViewModel: { year, categoryId in
                                makeResultViewModel(year, categoryId)
                            }
                        )
                    case let .result(categoryId):
                        TextCategoryResultView(
                            viewModel: makeResultViewModel(viewModel.year, categoryId)
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
        case .loaded:
            List {
                summarySection
                messagesSection
                slotsSection
            }
            .listStyle(.insetGrouped)
        case let .error(message):
            ContentUnavailableView {
                Label("順位入力できません", systemImage: "exclamationmark.triangle")
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

    private var summarySection: some View {
        Section {
            LabeledContent("部門", value: viewModel.title)
            LabeledContent("入力状況", value: viewModel.progressText)
            LabeledContent("候補数", value: "\(viewModel.candidates.count)件")
            if viewModel.saveState == .saving {
                Label("保存中", systemImage: "icloud.and.arrow.up")
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var messagesSection: some View {
        if !viewModel.validationMessages.isEmpty || saveFailureMessage != nil {
            Section {
                ForEach(viewModel.validationMessages, id: \.self) { message in
                    Label(message, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                }
                if let saveFailureMessage {
                    Label(saveFailureMessage, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var slotsSection: some View {
        Section {
            ForEach(viewModel.slots) { slot in
                RankSlotRow(
                    slot: slot,
                    action: {
                        selectingRank = slot.rank
                    },
                    clearAction: {
                        Task {
                            await viewModel.clearSelection(forRank: slot.rank)
                        }
                    }
                )
                .accessibilityIdentifier("text-ranking-slot-\(slot.rank)")
            }
        } header: {
            Text("順位")
        } footer: {
            Text("同じ候補を複数の順位に選ぶことはできません。")
        }
    }

    private var candidateSelectionSheet: some View {
        NavigationStack {
            List(filteredCandidates) { candidate in
                Button {
                    guard let selectingRank else {
                        return
                    }
                    Task {
                        await viewModel.selectCandidate(candidate.id, forRank: selectingRank)
                        self.selectingRank = nil
                        candidateSearchText = ""
                    }
                } label: {
                    HStack(spacing: 12) {
                        TextCandidateImagePlaceholder()
                        VStack(alignment: .leading, spacing: 4) {
                            Text(candidate.name)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            if let selectingRank, viewModel.isCandidateSelectedElsewhere(candidate.id, forRank: selectingRank) {
                                Text("他の順位から移動します")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .accessibilityIdentifier("text-ranking-candidate-\(candidate.id)")
            }
            .navigationTitle(selectingRank.map { "\($0)位の候補" } ?? "候補")
            .searchable(text: $candidateSearchText, prompt: "候補を検索")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        selectingRank = nil
                        candidateSearchText = ""
                    }
                }
            }
        }
    }

    private var filteredCandidates: [TextCandidate] {
        let query = candidateSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return viewModel.candidates
        }
        return viewModel.candidates.filter { candidate in
            candidate.name.localizedStandardContains(query)
        }
    }

    private var saveFailureMessage: String? {
        if case let .failed(message) = viewModel.saveState {
            message
        } else {
            nil
        }
    }
}
