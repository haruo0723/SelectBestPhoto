import SwiftUI

struct TextCandidateManagementView: View {
    @StateObject private var viewModel: TextCandidateManagementViewModel
    @State private var deletingCandidateId: String?
    private let makeCandidateManagementViewModel: (Int, String) -> TextCandidateManagementViewModel
    private let makeRankingInputViewModel: (String) -> TextRankingInputViewModel
    private let makeWaitingViewModel: (Int, String) -> TextCategoryWaitingViewModel
    private let makeResultViewModel: (Int, String) -> TextCategoryResultViewModel

    init(
        viewModel: TextCandidateManagementViewModel,
        makeCandidateManagementViewModel: @escaping (Int, String) -> TextCandidateManagementViewModel,
        makeRankingInputViewModel: @escaping (String) -> TextRankingInputViewModel,
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
            .navigationTitle("候補管理")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await viewModel.confirmCategory()
                        }
                    } label: {
                        if viewModel.actionState == .confirming {
                            ProgressView()
                        } else {
                            Label("確定", systemImage: "lock")
                        }
                    }
                    .disabled(!viewModel.canConfirm)
                    .accessibilityIdentifier("text-candidate-confirm")
                }
            }
            .safeAreaInset(edge: .bottom) {
                addCandidateBar
            }
            .confirmationDialog(
                "候補を削除しますか?",
                isPresented: Binding(
                    get: { deletingCandidateId != nil },
                    set: { isPresented in
                        if !isPresented {
                            deletingCandidateId = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    guard let candidateId = deletingCandidateId else {
                        return
                    }
                    Task {
                        await viewModel.deleteCandidate(candidateId: candidateId)
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }
            .navigationDestination(
                isPresented: Binding(
                    get: { viewModel.confirmedCategoryId != nil },
                    set: { isPresented in
                        if !isPresented {
                            viewModel.clearConfirmedCategoryNavigation()
                        }
                    }
                )
            ) {
                if let categoryId = viewModel.confirmedCategoryId {
                    TextRankingInputView(
                        viewModel: makeRankingInputViewModel(categoryId),
                        makeCandidateManagementViewModel: makeCandidateManagementViewModel,
                        makeRankingInputViewModel: { _, categoryId in
                            makeRankingInputViewModel(categoryId)
                        },
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
        case .loaded:
            List {
                summarySection
                messagesSection
                candidateSection
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

    private var summarySection: some View {
        Section {
            LabeledContent("部門", value: viewModel.category?.name ?? "")
            LabeledContent("候補数", value: viewModel.candidateCountText)
            Text(viewModel.confirmationHint)
                .font(.footnote)
                .foregroundStyle(viewModel.canConfirm ? .green : .secondary)
        }
    }

    @ViewBuilder
    private var messagesSection: some View {
        if !viewModel.validationMessages.isEmpty || actionFailureMessage != nil {
            Section {
                ForEach(viewModel.validationMessages, id: \.self) { message in
                    Label(message, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                }
                if let actionFailureMessage {
                    Label(actionFailureMessage, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var candidateSection: some View {
        Section {
            if viewModel.rows.isEmpty {
                ContentUnavailableView("候補がありません", systemImage: "text.badge.plus")
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.rows) { row in
                    candidateRow(row)
                        .accessibilityIdentifier("text-candidate-row-\(row.id)")
                }
            }
        } header: {
            Text("候補")
        }
    }

    private func candidateRow(_ row: TextCandidateRowState) -> some View {
        HStack(spacing: 12) {
            TextCandidateImagePlaceholder()

            TextField(
                "候補名",
                text: Binding(
                    get: { row.draftName },
                    set: { viewModel.updateDraftName($0, forCandidateId: row.id) }
                )
            )
            .disabled(!viewModel.isEditable)
            .textInputAutocapitalization(.never)
            .accessibilityIdentifier("text-candidate-name-\(row.id)")

            if viewModel.isEditable {
                Button {
                    Task {
                        await viewModel.saveCandidateName(candidateId: row.id)
                    }
                } label: {
                    Image(systemName: "checkmark.circle")
                }
                .accessibilityLabel("候補名を保存")

                Button(role: .destructive) {
                    deletingCandidateId = row.id
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("候補を削除")
            }
        }
        .padding(.vertical, 4)
    }

    private var addCandidateBar: some View {
        VStack(spacing: 8) {
            Divider()
            HStack(spacing: 8) {
                TextField("候補を追加", text: $viewModel.newCandidateName)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .disabled(!viewModel.isEditable)
                    .accessibilityIdentifier("text-candidate-new-name")

                Button {
                    Task {
                        await viewModel.addCandidate()
                    }
                } label: {
                    if viewModel.actionState == .saving {
                        ProgressView()
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .disabled(!viewModel.isEditable || viewModel.newCandidateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("候補を追加")
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.bar)
    }

    private var actionFailureMessage: String? {
        if case let .failed(message) = viewModel.actionState {
            message
        } else {
            nil
        }
    }
}
