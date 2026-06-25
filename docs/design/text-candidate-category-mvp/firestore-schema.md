# テキスト候補型カスタム部門MVP Firestoreスキーマ設計

**作成日**: 2026-06-25
**関連設計**: [architecture.md](architecture.md)
**関連要件定義**: [requirements.md](../../spec/text-candidate-category-mvp/requirements.md)

## 信頼性レベル凡例

- 🔵 **青信号**: EARS要件定義書・設計文書・既存DBスキーマを参考にした確実な定義
- 🟡 **黄信号**: EARS要件定義書・設計文書・既存DBスキーマから妥当な推測による定義
- 🔴 **赤信号**: EARS要件定義書・設計文書・既存DBスキーマにない推測による定義

## 方針 🔵

**信頼性**: 🔵 `REQ-401`〜`REQ-405`, `NFR-101`, `NFR-102`

- FirestoreをMVPデータの正本にする
- ペア配下、年配下、部門配下でデータを分割する
- 個人入力は`inputs/{userId}`に分離し、本人だけが編集できる構造にする
- 両者完了前に相手入力と結果を読めないよう、入力と結果を別ドキュメントにする
- MVPではCloud Storage関連フィールドを必須にしない

## コレクション構成 🔵

**信頼性**: 🔵 `REQ-001`, `REQ-002`, `REQ-010`, `REQ-401`

```text
pairs/{pairId}
├── memberIds: string[]
└── years/{year}
    └── textCategories/{categoryId}
        ├── candidates/{candidateId}
        ├── inputs/{userId}
        └── results/{resultId}
```

## `textCategories/{categoryId}` 🔵

**信頼性**: 🔵 `REQ-001`, `REQ-006`〜`REQ-008`, `REQ-019`, `REQ-110`

| フィールド | 型 | 必須 | 内容 | 信頼性 |
| --- | --- | --- | --- | --- |
| `pairId` | string | yes | ペアID | 🔵 |
| `year` | number | yes | 対象年 | 🔵 |
| `name` | string | yes | 部門名 | 🔵 |
| `status` | string | yes | `draft` / `confirmed` / `resultAvailable` | 🔵 |
| `inputRankLimit` | number | yes | 入力対象順位。1〜50 | 🔵 |
| `revealRankLimit` | number | yes | 発表対象順位。1〜50かつ入力対象順位以下 | 🔵 |
| `pointsByRank` | array<map> | yes | `{ rank, points }` の配列。最大50件 | 🔵 |
| `generation` | number | yes | リセット世代 | 🔵 |
| `createdByUserId` | string | yes | 作成者uid | 🔵 |
| `confirmedAt` | timestamp | no | 候補・設定確定日時 | 🔵 |
| `createdAt` | timestamp | yes | 作成日時 | 🔵 |
| `updatedAt` | timestamp | yes | 更新日時 | 🔵 |

### 制約 🔵

- `name` は空文字不可
- `inputRankLimit` は1〜50
- `revealRankLimit` は1〜`inputRankLimit`
- `pointsByRank[].rank` は1〜50
- `pointsByRank[].points` は1以上
- `status == confirmed`以降は、候補と設定を変更しない

## `candidates/{candidateId}` 🔵

**信頼性**: 🔵 `REQ-003`〜`REQ-005`, `REQ-017`, `REQ-018`, `REQ-108`, `REQ-408`

| フィールド | 型 | 必須 | 内容 | 信頼性 |
| --- | --- | --- | --- | --- |
| `pairId` | string | yes | ペアID | 🔵 |
| `year` | number | yes | 対象年 | 🔵 |
| `categoryId` | string | yes | 部門ID | 🔵 |
| `name` | string | yes | 候補名 | 🔵 |
| `imagePlaceholderKind` | string | yes | `none` / `futureImageSlot` | 🔵 |
| `createdByUserId` | string | yes | 作成者uid | 🔵 |
| `createdAt` | timestamp | yes | 作成日時 | 🔵 |
| `updatedAt` | timestamp | yes | 更新日時 | 🔵 |

### 制約 🔵

- `name` は空文字不可
- 同名候補は許可する
- 1部門あたり100件程度を想定する
- MVPではStorageパス、画像ID、画像メタデータを保存しない
- 親部門が`draft`の場合のみ作成、更新、削除できる

## `inputs/{userId}` 🔵

**信頼性**: 🔵 `REQ-009`, `REQ-010`, `REQ-102`, `REQ-402`, `REQ-403`

| フィールド | 型 | 必須 | 内容 | 信頼性 |
| --- | --- | --- | --- | --- |
| `pairId` | string | yes | ペアID | 🔵 |
| `year` | number | yes | 対象年 | 🔵 |
| `categoryId` | string | yes | 部門ID | 🔵 |
| `userId` | string | yes | 入力者uid。ドキュメントIDと一致 | 🔵 |
| `generation` | number | yes | 部門世代 | 🔵 |
| `status` | string | yes | `notStarted` / `inProgress` / `completed` | 🔵 |
| `selections` | array<map> | yes | `{ rank, candidateId }` の配列 | 🔵 |
| `completedAt` | timestamp | no | 完了日時 | 🔵 |
| `updatedAt` | timestamp | yes | 更新日時 | 🔵 |

### 制約 🔵

- ドキュメントIDは`request.auth.uid`
- 本人のみ作成・更新できる
- `candidateId`は同一入力内で重複不可
- 完了時は`selections.count == inputRankLimit`
- 完了時は全`rank`が1〜`inputRankLimit`
- `generation`は親部門の`generation`と一致する

## `results/{resultId}` 🔵

**信頼性**: 🔵 `REQ-011`, `REQ-012`, `REQ-015`, `REQ-104`, `REQ-205`

| フィールド | 型 | 必須 | 内容 | 信頼性 |
| --- | --- | --- | --- | --- |
| `pairId` | string | yes | ペアID | 🔵 |
| `year` | number | yes | 対象年 | 🔵 |
| `categoryId` | string | yes | 部門ID | 🔵 |
| `generation` | number | yes | 部門世代 | 🔵 |
| `entries` | array<map> | yes | 発表対象順位までの結果 | 🔵 |
| `sourceUserIds` | array<string> | yes | 集計対象ユーザー2人 | 🔵 |
| `createdAt` | timestamp | yes | 作成日時 | 🔵 |

### `entries`構造 🔵

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| `rank` | number | 結果順位 | 🔵 |
| `candidateId` | string | 候補ID | 🔵 |
| `candidateName` | string | 表示用候補名 | 🔵 |
| `totalPoints` | number | 合計ポイント | 🔵 |
| `userBreakdowns` | array<map> | ユーザー別の選択順位とポイント | 🔵 |
| `imagePlaceholderKind` | string | 画像枠表示種別 | 🔵 |

### 制約 🔵

- 両者完了後のみ作成・読み取り可能
- `entries.count <= revealRankLimit`
- リセット後は旧世代結果を削除または読み取り対象外にする

## リセット時の更新 🔵

**信頼性**: 🔵 `REQ-013`, `REQ-014`, `REQ-106`

リセット確定時は同じ操作単位で以下を行う。

- `inputs/{userId}` を削除または旧世代として無効化する
- `results/{resultId}` を削除または旧世代として無効化する
- 親部門の`status`を`draft`へ戻す
- 親部門の`confirmedAt`を削除する
- 親部門の`generation`をインクリメントする
- 候補と部門設定は残す

## インデックス候補 🟡

**信頼性**: 🟡 画面クエリからの推測

| 用途 | 対象 | 備考 |
| --- | --- | --- |
| 年別部門一覧 | `textCategories` の `year`, `updatedAt` | 年配下に置くため単一フィールドで足りる可能性が高い |
| 状態別表示 | `textCategories.status` | 確定/結果表示可能な部門を絞る場合 |
| 候補一覧 | `candidates.createdAt` | 候補作成順の安定表示 |

Composite IndexはFirestoreの実クエリ確定後に追加する。

## MVP対象外フィールド 🔵

**信頼性**: 🔵 `REQ-301`, `REQ-302`, `REQ-407`

以下はMVPでは保存しない。

- CSV / XLSX読み込み元ファイル情報
- 関連画像のStorageパス
- 関連画像のメディアID
- Cloud Storage削除状態

## 信頼性レベルサマリー

- 🔵 青信号: 13件 (93%)
- 🟡 黄信号: 1件 (7%)
- 🔴 赤信号: 0件 (0%)

**品質評価**: 高品質。Firestore階層、候補、入力、結果、リセット方針、世代管理はユーザー確認済み。インデックス候補だけを実クエリ確定後に最終化する項目として🟡にしている。
