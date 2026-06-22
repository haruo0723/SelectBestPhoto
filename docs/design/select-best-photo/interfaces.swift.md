# SelectBestPhoto Swift型設計

この文書は実装前の設計用Swift型である。実際のファイル名、Firestore Codable対応、Firebase SDK型の扱いはXcodeプロジェクト作成時に調整する。

## 1. 共通型

```swift
// 🔵 入力状態は要件定義に基づく
enum InputStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case completed
}

// 🔵 写真、動画、Live Photosを扱う
enum MediaKind: String, Codable, Sendable {
    case photo
    case video
    case livePhoto
}

// 🟡 公開結果を入力種別ごとに分離するための分類
enum ContestKind: String, Codable, Sendable {
    case monthlyBest
    case annualBest
    case mediaCustomCategory
    case textCustomCategory
}

// 🔵 下位から入力し、順位付きで保存する
struct RankedSelection: Codable, Identifiable, Sendable {
    var id: String
    var rank: Int
    var targetId: String
    var createdAt: Date
    var updatedAt: Date
}
```

## 2. ペアとメンバー

```swift
// 🔵 Firebase Anonymous Authentication + ペアコード
struct Pair: Codable, Identifiable, Sendable {
    var id: String
    var memberIds: [String]
    var createdAt: Date
    var updatedAt: Date
}

// 🔵 表示名とアイコンを設定できる
struct PairMember: Codable, Identifiable, Sendable {
    var id: String
    var displayName: String
    var iconMediaAssetId: String?
    var joinedAt: Date
}

// 🔵 短期限+使用後失効はヒアリング決定
struct PairCode: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var codeHash: String
    var expiresAt: Date
    var usedAt: Date?
    var createdBy: String
}
```

## 3. メディア資産

```swift
// 🔵 Storageメディアを参照管理する
struct MediaAsset: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var ownerUserId: String
    var kind: MediaKind
    var originalFilename: String?
    var displayStoragePath: String
    var thumbnailStoragePath: String?
    var livePhotoMotionStoragePath: String?
    var metadata: MediaMetadata
    var referenceScopes: [MediaReferenceScope]
    var deletionState: MediaDeletionState
    var createdAt: Date
    var updatedAt: Date
}

// 🔵 メタデータは原則保持し、位置情報は除外
struct MediaMetadata: Codable, Sendable {
    var capturedAt: Date?
    var width: Int?
    var height: Int?
    var durationSeconds: Double?
    var fileSizeBytes: Int64?
    var containsLocationMetadata: Bool
}

// 🟡 巻き込み削除を避けるため参照元を記録
struct MediaReferenceScope: Codable, Hashable, Sendable {
    var scopeKind: String
    var year: Int?
    var month: Int?
    var categoryId: String?
}

enum MediaDeletionState: String, Codable, Sendable {
    case active
    case pendingDeletion
    case deleted
}
```

## 4. 設定

```swift
// 🔵 月間ベスト件数、年間候補件数、敗者復活枠件数を設定できる
struct YearSettings: Codable, Identifiable, Sendable {
    var id: String
    var year: Int
    var revivalPickLimit: Int
    var updatedAt: Date
}

struct MonthSettings: Codable, Identifiable, Sendable {
    var id: String
    var year: Int
    var month: Int
    var monthlyBestLimit: Int
    var annualCandidateLimit: Int
    var updatedAt: Date
}
```

## 5. 月間・年間入力

```swift
// 🔵 月間ベストはユーザーごと、年月ごとに順位付き保存
struct MonthlyBestInput: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var month: Int
    var userId: String
    var status: InputStatus
    var selections: [RankedSelection]
    var completedAt: Date?
    var updatedAt: Date
}

// 🔵 月間ベストから年間候補を選ぶ
struct AnnualCandidateSelection: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var month: Int
    var userId: String
    var mediaAssetIds: [String]
    var updatedAt: Date
}

// 🔵 年間TOP5
struct AnnualBestInput: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var userId: String
    var status: InputStatus
    var selections: [RankedSelection]
    var completedAt: Date?
    var updatedAt: Date
}

// 🔵 年ごとに1-2件
struct RevivalPickInput: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var userId: String
    var mediaAssetIds: [String]
    var updatedAt: Date
}
```

## 6. カスタム部門

```swift
// 🔵 年ごとに複数作成できる
struct CustomCategory: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var name: String
    var kind: CustomCategoryKind
    var textSettings: TextCategorySettings?
    var createdAt: Date
    var updatedAt: Date
}

enum CustomCategoryKind: String, Codable, Sendable {
    case media
    case text
}

// 🔵 メディア型はTOP3
struct MediaCategoryInput: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var categoryId: String
    var userId: String
    var status: InputStatus
    var selections: [RankedSelection]
    var completedAt: Date?
    var updatedAt: Date
}

// 🔵 テキスト候補型の設定
struct TextCategorySettings: Codable, Sendable {
    var inputRankLimit: Int
    var revealRankLimit: Int
    var pointsByRank: [Int: Int]
}

struct TextCandidate: Codable, Identifiable, Sendable {
    var id: String
    var categoryId: String
    var name: String
    var imageMediaAssetId: String?
    var createdAt: Date
    var updatedAt: Date
}

struct TextCategoryInput: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var year: Int
    var categoryId: String
    var userId: String
    var status: InputStatus
    var selections: [RankedSelection]
    var completedAt: Date?
    var updatedAt: Date
}
```

## 7. 公開結果

```swift
// 🔵 公開用結果は個別入力から分離
struct RevealResult: Codable, Identifiable, Sendable {
    var id: String
    var pairId: String
    var kind: ContestKind
    var year: Int
    var month: Int?
    var categoryId: String?
    var generation: Int
    var entries: [RevealEntry]
    var sourceInputIds: [String]
    var createdAt: Date
}

struct RevealEntry: Codable, Identifiable, Sendable {
    var id: String
    var rank: Int
    var userId: String?
    var targetId: String
    var points: Int?
}
```

## 8. Service境界

```swift
// 🟡 実装時のテスト容易性のためprotocolで境界を切る
protocol PairService {
    func signInAnonymouslyIfNeeded() async throws -> String
    func createPairCode() async throws -> String
    func joinPair(code: String) async throws
}

protocol MediaProcessingService {
    func prepareUpload(from item: PhotoPickerItem) async throws -> PreparedMediaUpload
}

protocol MediaAssetService {
    func upload(_ media: PreparedMediaUpload, scope: MediaReferenceScope) async throws -> MediaAsset
    func markUnusedAssetsForDeletion(in scope: MediaReferenceScope) async throws
}

protocol RevealResultService {
    func createRevealResultIfReady(kind: ContestKind, year: Int, month: Int?, categoryId: String?) async throws -> RevealResult
}
```

`PhotoPickerItem` と `PreparedMediaUpload` は、Xcodeプロジェクト作成時にPhotosUI/AVFoundationの具体型に合わせて定義する。🟡
