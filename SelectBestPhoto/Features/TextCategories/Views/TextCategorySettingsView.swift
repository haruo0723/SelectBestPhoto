import SwiftUI

struct TextCategorySettingsView: View {
    @StateObject private var viewModel: TextCategorySettingsViewModel
    private let makeCandidateManagementViewModel: (String) -> TextCandidateManagementViewModel
    private let makeRankingInputViewModel: (String) -> TextRankingInputViewModel
    private let makeWaitingViewModel: (Int, String) -> TextCategoryWaitingViewModel
    private let makeResultViewModel: (Int, String) -> TextCategoryResultViewModel
    @State private var savedCategoryId: String?

    init(
        viewModel: TextCategorySettingsViewModel,
        makeCandidateManagementViewModel: @escaping (String) -> TextCandidateManagementViewModel,
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
        Form {
            Section("基本設定") {
                TextField("部門名", text: $viewModel.draft.name)
                    .textInputAutocapitalization(.never)
                    .accessibilityIdentifier("text-category-settings-name")

                Stepper(
                    value: Binding(
                        get: { viewModel.draft.inputRankLimit },
                        set: { viewModel.setInputRankLimit($0) }
                    ),
                    in: TextCategoryValidator.rankLimitRange
                ) {
                    LabeledContent("入力対象順位", value: "\(viewModel.draft.inputRankLimit)位まで")
                }

                Stepper(
                    value: Binding(
                        get: { viewModel.draft.revealRankLimit },
                        set: { viewModel.setRevealRankLimit($0) }
                    ),
                    in: 1 ... max(viewModel.draft.inputRankLimit, 1)
                ) {
                    LabeledContent("発表対象順位", value: "\(viewModel.draft.revealRankLimit)位まで")
                }
            }

            if !viewModel.validationMessages.isEmpty {
                Section {
                    ForEach(viewModel.validationMessages, id: \.self) { message in
                        Label(message, systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                    }
                }
            }

            Section {
                ForEach(viewModel.draft.pointsByRank) { point in
                    Stepper(
                        value: Binding(
                            get: { point.points },
                            set: { viewModel.setPoints($0, forRank: point.rank) }
                        ),
                        in: 0 ... 999
                    ) {
                        LabeledContent("\(point.rank)位", value: "\(point.points)pt")
                    }
                    .accessibilityIdentifier("text-category-settings-rank-\(point.rank)-points")
                }
            } header: {
                Text("順位別ポイント")
            } footer: {
                Text("ポイントは1以上で保存できます。")
            }

            if case let .failed(message) = viewModel.saveState {
                Section {
                    Label(message, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("部門設定")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task {
                        await viewModel.saveDraft()
                        if case let .saved(categoryId) = viewModel.saveState {
                            savedCategoryId = categoryId
                        }
                    }
                } label: {
                    if viewModel.saveState == .saving {
                        ProgressView()
                    } else {
                        Label("保存", systemImage: "checkmark")
                    }
                }
                .disabled(!viewModel.canSave)
                .accessibilityIdentifier("text-category-settings-save")
            }
        }
        .navigationDestination(
            isPresented: Binding(
                get: { savedCategoryId != nil },
                set: { isPresented in
                    if !isPresented {
                        savedCategoryId = nil
                    }
                }
            )
        ) {
            let categoryId = savedCategoryId ?? ""
            TextCandidateManagementView(
                viewModel: makeCandidateManagementViewModel(categoryId),
                makeRankingInputViewModel: makeRankingInputViewModel,
                makeWaitingViewModel: makeWaitingViewModel,
                makeResultViewModel: makeResultViewModel
            )
        }
    }
}
