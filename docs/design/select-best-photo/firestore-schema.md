# SelectBestPhoto Firestoreスキーマ設計

## 1. 方針

- 年/月で分割し、読み取り範囲、Security Rules、リセット範囲を明確にする。🔵
- 個別入力と公開用結果を分離し、両者完了前に相手の入力内容を読めない構造にする。🔵
- Storageファイルは `mediaAssets` で参照管理し、削除時に参照元を確認できるようにする。🔵
- FirestoreのTimestamp、DocumentID、ServerTimestampは実装時にFirebase SDKの型へ合わせる。🟡

## 2. コレクション構成

```text
pairs/{pairId}
├── members/{userId}
├── mediaAssets/{mediaAssetId}
├── years/{year}
│   ├── settings/main
│   ├── customCategories/{categoryId}
│   │   ├── textCandidates/{candidateId}
│   │   ├── mediaInputs/{userId}
│   │   ├── textInputs/{userId}
│   │   └── revealResults/{generationId}
│   ├── annualCandidates/{userId}_{month}
│   ├── annualBestInputs/{userId}
│   ├── revivalPicks/{userId}
│   ├── revealResults/{contestId}
│   └── months/{month}
│       ├── settings/main
│       ├── monthlyBestInputs/{userId}
│       └── revealResults/{generationId}
pairCodes/{pairCodeId}
```

## 3. pairs

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| memberIds | array<string> | ペアに属する最大2人のuid | 🔵 |
| createdAt | timestamp | 作成日時 | 🟡 |
| updatedAt | timestamp | 更新日時 | 🟡 |

- `memberIds` はRulesでペア所属判定に使う。🔵
- 2人利用を前提とし、3人以上の参加は許可しない。🔵

## 4. pairCodes

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| pairId | string | 参加先ペア | 🔵 |
| codeHash | string | ペアコードのハッシュ | 🟡 |
| createdBy | string | 発行ユーザーuid | 🔵 |
| expiresAt | timestamp | 有効期限 | 🔵 |
| usedAt | timestamp? | 使用済み日時 | 🔵 |

- 短期限+使用後失効とする。🔵
- 平文コードはログや永続保存に出さず、照合用ハッシュを保存する。🟡

## 5. members

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| displayName | string | 表示名 | 🔵 |
| iconMediaAssetId | string? | アイコン画像 | 🔵 |
| joinedAt | timestamp | 参加日時 | 🟡 |

## 6. mediaAssets

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| ownerUserId | string | 登録者uid | 🔵 |
| kind | photo/video/livePhoto | メディア種別 | 🔵 |
| displayStoragePath | string | 表示・再生用Storageパス | 🔵 |
| thumbnailStoragePath | string? | サムネイルStorageパス | 🟡 |
| livePhotoMotionStoragePath | string? | Live Photosモーション部分 | 🔵 |
| metadata | map | 撮影日時、サイズ、長さなど | 🔵 |
| referenceScopes | array<map> | 参照元スコープ | 🔵 |
| deletionState | active/pendingDeletion/deleted | 削除状態 | 🟡 |
| createdAt | timestamp | 作成日時 | 🟡 |
| updatedAt | timestamp | 更新日時 | 🟡 |

- GPSなど位置情報は保存しない。🔵
- 参照元がなくなったファイルだけ削除対象にする。🔵

## 7. settings

### years/{year}/settings/main

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| revivalPickLimit | number | 敗者復活枠件数。1-2件 | 🔵 |
| updatedAt | timestamp | 更新日時 | 🟡 |

### months/{month}/settings/main

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| monthlyBestLimit | number | 月間ベスト件数。初期値3 | 🔵 |
| annualCandidateLimit | number | 年間候補へ進める件数。初期値3 | 🔵 |
| updatedAt | timestamp | 更新日時 | 🟡 |

## 8. 月間入力

### months/{month}/monthlyBestInputs/{userId}

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| status | notStarted/inProgress/completed | 入力状態 | 🔵 |
| selections | array<rankedSelection> | 順位付きメディア選択 | 🔵 |
| completedAt | timestamp? | 完了日時 | 🔵 |
| updatedAt | timestamp | 更新日時 | 🟡 |

- ドキュメントIDはuidにし、自分の入力だけ書き込めるようにする。🟡
- 相手の入力ドキュメントは両者完了前に直接読ませない。🔵

## 9. 年間入力

### annualCandidates/{userId}_{month}

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| userId | string | 選択者uid | 🔵 |
| month | number | 対象月 | 🔵 |
| mediaAssetIds | array<string> | 年間候補 | 🔵 |
| updatedAt | timestamp | 更新日時 | 🟡 |

### annualBestInputs/{userId}

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| status | string | 入力状態 | 🔵 |
| selections | array<rankedSelection> | 年間TOP5 | 🔵 |
| completedAt | timestamp? | 完了日時 | 🔵 |
| updatedAt | timestamp | 更新日時 | 🟡 |

### revivalPicks/{userId}

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| mediaAssetIds | array<string> | 敗者復活枠 | 🔵 |
| updatedAt | timestamp | 更新日時 | 🟡 |

## 10. カスタム部門

### customCategories/{categoryId}

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| name | string | 部門名 | 🔵 |
| kind | media/text | 部門種別 | 🔵 |
| textSettings | map? | テキスト候補型設定 | 🔵 |
| createdAt | timestamp | 作成日時 | 🟡 |
| updatedAt | timestamp | 更新日時 | 🟡 |

### textCandidates/{candidateId}

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| name | string | 候補名 | 🔵 |
| imageMediaAssetId | string? | 関連画像 | 🔵 |
| createdAt | timestamp | 作成日時 | 🟡 |
| updatedAt | timestamp | 更新日時 | 🟡 |

### mediaInputs/{userId} / textInputs/{userId}

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| status | string | 入力状態 | 🔵 |
| selections | array<rankedSelection> | 順位付き選択 | 🔵 |
| completedAt | timestamp? | 完了日時 | 🔵 |
| updatedAt | timestamp | 更新日時 | 🟡 |

## 11. 公開結果

### revealResults/{generationId}

| フィールド | 型 | 内容 | 信頼性 |
| --- | --- | --- | --- |
| kind | string | 月間、年間、部門の種別 | 🔵 |
| generation | number | 再入力後の世代 | 🟡 |
| entries | array<revealEntry> | 公開表示用結果 | 🔵 |
| sourceInputIds | array<string> | 元入力ドキュメント | 🟡 |
| createdAt | timestamp | 作成日時 | 🟡 |

- 両者完了後にクライアントがトランザクションで作成する。🔵
- 同じ入力世代から重複生成されないよう、世代IDまたはsourceInputIdsで冪等にする。🟡

## 12. インデックス候補

| 用途 | 対象 | 信頼性 |
| --- | --- | --- |
| 年一覧 | `pairs/{pairId}/years` | 🟡 |
| 月一覧 | `years/{year}/months` | 🟡 |
| メディア削除候補 | `mediaAssets.deletionState` | 🟡 |
| 部門一覧 | `customCategories.kind` | 🟡 |

実際のComposite IndexはFirestoreエラーと画面クエリ確定後に追加する。🟡
