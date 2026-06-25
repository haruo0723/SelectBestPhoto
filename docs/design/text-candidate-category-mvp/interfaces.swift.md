# テキスト候補型カスタム部門MVP Swift型設計

**作成日**: 2026-06-25
**関連設計**: [architecture.md](architecture.md)

## 信頼性レベル凡例

- 🔵 **青信号**: EARS要件定義書・設計文書・既存実装を参考にした確実な型定義
- 🟡 **黄信号**: EARS要件定義書・設計文書・既存実装から妥当な推測による型定義
- 🔴 **赤信号**: EARS要件定義書・設計文書・既存実装にない推測による型定義

## 共通型

```swift
// 🔵 REQ-203, REQ-204, REQ-205
enum InputStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case completed
}

// 🔵 REQ-109, REQ-110, REQ-205
enum TextCategoryStatus: String, Codable, Sendable {
    case draft
    case confirmed
    case resultAvailable
}
```

## 部門設定

```swift
// 🔵 REQ-001, REQ-002, REQ-006, REQ-007, REQ-008, REQ-019
struct TextCategory: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var name: String
    var status: TextCategoryStatus
    var settings: TextCategorySettings
    var generation: Int
    var createdByUserId: String
    var confirmedAt: Date?
    var createdAt: Date
    var updatedAt: Date
}

// 🔵 REQ-006, REQ-007, REQ-008
struct TextCategorySettings: Codable, Equatable, Sendable {
    var inputRankLimit: Int
    var revealRankLimit: Int
    var pointsByRank: [RankPoint]
}

// 🔵 REQ-008, EDGE-103
struct RankPoint: Codable, Identifiable, Equatable, Sendable {
    var id: Int { rank }
    var rank: Int
    var points: Int
}
```

**制約**:

- `inputRankLimit`: 1〜50
- `revealRankLimit`: 1〜`inputRankLimit`
- `pointsByRank`: 最大50行、各`points`は1以上
- `generation`: リセットごとにインクリメントし、入力と結果の整合性に使う 🟡

## 候補

```swift
// 🔵 REQ-003, REQ-004, REQ-005, REQ-017, REQ-108, REQ-408
struct TextCandidate: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var categoryId: String
    var name: String
    var imagePlaceholderKind: TextCandidateImagePlaceholderKind
    var createdByUserId: String
    var createdAt: Date
    var updatedAt: Date
}

// 🔵 REQ-017, REQ-407, REQ-408
enum TextCandidateImagePlaceholderKind: String, Codable, Sendable {
    case none
    case futureImageSlot
}
```

**制約**:

- `name` は空にしない
- 同名候補は許容し、`id`で別候補として扱う
- MVPでは画像保存先やStorageパスを持たない

## 順位入力

```swift
// 🔵 REQ-009, REQ-010, REQ-102, REQ-203
struct TextCategoryInput: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var categoryId: String
    var userId: String
    var generation: Int
    var status: InputStatus
    var selections: [RankedTextSelection]
    var completedAt: Date?
    var updatedAt: Date
}

// 🔵 REQ-009, REQ-102
struct RankedTextSelection: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var rank: Int
    var candidateId: String
}
```

**制約**:

- 入力ドキュメントIDは`userId`
- `rank`は1〜`inputRankLimit`
- `candidateId`の重複は許可しない
- 完了時は`selections.count == inputRankLimit`
- `generation`は部門の現世代と一致する必要がある

## 結果

```swift
// 🔵 REQ-011, REQ-012, REQ-104, REQ-205
struct TextCategoryResult: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var categoryId: String
    var generation: Int
    var entries: [TextCategoryResultEntry]
    var sourceUserIds: [String]
    var createdAt: Date
}

// 🔵 REQ-011, REQ-012, UI-009
struct TextCategoryResultEntry: Codable, Identifiable, Sendable {
    var id: String
    var rank: Int
    var candidateId: String
    var candidateName: String
    var totalPoints: Int
    var userBreakdowns: [TextCategoryUserPointBreakdown]
    var imagePlaceholderKind: TextCandidateImagePlaceholderKind
}

// 🔵 UI-009
struct TextCategoryUserPointBreakdown: Codable, Identifiable, Sendable {
    var id: String { userId }
    var userId: String
    var selectedRank: Int?
    var points: Int
}
```

**制約**:

- `entries`は発表対象順位まで
- `sourceUserIds`は2人分
- 結果は両者完了後のみ読み取り可能

## ViewModel状態

```swift
// 🟡 実装時のUI状態整理
enum TextCategoryScreenState: Equatable, Sendable {
    case loading
    case empty
    case editing
    case inputAvailable
    case waitingForPartner
    case resultAvailable
    case error(String)
}

// 🟡 保存失敗時に入力内容を保持するための画面下書き
struct TextCategoryDraft: Equatable, Sendable {
    var name: String
    var inputRankLimit: Int
    var revealRankLimit: Int
    var pointsByRank: [RankPoint]
}
```

## Repository境界

```swift
// 🟡 テスト容易性のためprotocolで境界を切る
protocol TextCategoryRepository: Sendable {
    func observeCategories(pairId: String, year: Int) -> AsyncThrowingStream<[TextCategory], Error>
    func createCategory(_ category: TextCategory) async throws
    func updateDraftCategory(_ category: TextCategory) async throws
    func confirmCategory(pairId: String, year: Int, categoryId: String) async throws
    func resetCategory(pairId: String, year: Int, categoryId: String) async throws

    func observeCandidates(pairId: String, year: Int, categoryId: String) -> AsyncThrowingStream<[TextCandidate], Error>
    func addCandidate(_ candidate: TextCandidate) async throws
    func updateCandidate(_ candidate: TextCandidate) async throws
    func deleteCandidate(pairId: String, year: Int, categoryId: String, candidateId: String) async throws

    func saveInput(_ input: TextCategoryInput) async throws
    func completeInput(_ input: TextCategoryInput) async throws
    func loadResultContext(pairId: String, year: Int, categoryId: String) async throws -> TextCategoryResultContext
    func saveResultIfNeeded(_ result: TextCategoryResult) async throws
}

// 🟡 結果生成に必要なデータをまとめるDTO
struct TextCategoryResultContext: Sendable {
    var category: TextCategory
    var candidates: [TextCandidate]
    var inputs: [TextCategoryInput]
}
```

## 集計境界

```swift
// 🔵 REQ-011, REQ-012, NFR-002
protocol TextCategoryResultCalculating: Sendable {
    func calculate(
        category: TextCategory,
        candidates: [TextCandidate],
        inputs: [TextCategoryInput]
    ) throws -> TextCategoryResult
}
```

## 信頼性レベルサマリー

- 🔵 青信号: 13件 (72%)
- 🟡 黄信号: 5件 (28%)
- 🔴 赤信号: 0件 (0%)

**品質評価**: 高品質。Firestore実装の都合で補完したRepository境界と世代管理は🟡として明示している。
