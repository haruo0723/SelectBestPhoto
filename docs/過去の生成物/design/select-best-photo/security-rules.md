# SelectBestPhoto Firebase Security Rules設計

## 1. 方針

- ペアに属するユーザーだけが対象データへアクセスできる。🔵
- 両者入力完了前は、相手の入力内容をFirestore Rulesでも読めないようにする。🔵
- 公開用結果ドキュメントは個別入力から分離する。🔵
- StorageはFirestore `mediaAssets` と対応するペア所属を前提にアクセス制御する。🔵

## 2. Firestore Rulesの考え方

```text
function signedIn() {
  return request.auth != null;
}

function isPairMember(pairId) {
  return signedIn()
    && request.auth.uid in get(/databases/$(database)/documents/pairs/$(pairId)).data.memberIds;
}

function isSelf(userId) {
  return signedIn() && request.auth.uid == userId;
}
```

上記は実装イメージであり、実際のRules構文はFirebaseプロジェクト作成後に検証する。🟡

## 3. アクセス制御

| 対象 | 読み取り | 書き込み | 信頼性 |
| --- | --- | --- | --- |
| `pairs/{pairId}` | ペアメンバーのみ | ペア作成・参加処理のみ | 🔵 |
| `members/{userId}` | ペアメンバーのみ | 本人プロフィールのみ | 🔵 |
| `pairCodes/{codeId}` | 参加検証に必要な範囲 | 発行者、未使用、期限内のみ | 🔵 |
| `monthlyBestInputs/{userId}` | 本人のみ。相手は公開結果経由 | 本人のみ | 🔵 |
| `annualBestInputs/{userId}` | 本人のみ。相手は公開結果経由 | 本人のみ | 🔵 |
| `mediaInputs/{userId}` | 本人のみ。相手は公開結果経由 | 本人のみ | 🔵 |
| `textInputs/{userId}` | 本人のみ。相手は公開結果経由 | 本人のみ | 🔵 |
| `revealResults/{id}` | ペアメンバーのみ | 両者完了条件を満たす場合のみ | 🔵 |
| `mediaAssets/{id}` | ペアメンバーのみ。ただし未公開入力の推測に注意 | 所有者またはリセット処理 | 🟡 |

## 4. 公開用結果作成条件

公開用結果はクライアントのFirestoreトランザクションで作成する。Rulesでは最低限以下を検証する。🔵

- `request.auth.uid` が対象ペアのメンバーである。
- 対象コンテストの両ユーザーの入力状態が `completed` である。
- `sourceInputIds` が対象入力ドキュメントを指している。
- `entries` の順位数が対象コンテストの上限を超えない。
- `createdAt` などのサーバー時刻フィールドは改ざんを許さない。

完全な集計妥当性をRulesだけで検証するのは複雑なため、クライアント実装では冪等な生成ロジックとユニットテストで補強する。🟡

## 5. Storage Rulesの考え方

```text
match /pairs/{pairId}/{allPaths=**} {
  allow read: if isPairMember(pairId);
  allow write: if isPairMember(pairId);
}
```

上記は概念であり、本番Rulesでは以下を追加する。🟡

- `mediaAssetId` がFirestore `mediaAssets` に存在すること。
- `ownerUserId` が `request.auth.uid` と一致すること。
- パスが `pairs/{pairId}/media/{mediaAssetId}/...` の形式に合うこと。
- ファイルサイズとContent-Typeを許容範囲に制限すること。

## 6. ログとプライバシー

- ペアコード、uid、Storageパス、写真メタデータ、個人情報をログへ出さない。🔵
- 位置情報はアップロード前に除外し、Firestoreにも保存しない。🔵
- `GoogleService-Info.plist` のリポジトリ管理方針はFirebaseプロジェクト作成時に決める。🔵

## 7. 検証方針

- Firebase Emulator SuiteでFirestore RulesとStorage Rulesをテストする。🔵
- ペア外ユーザーの読み書き拒否を必須テストにする。🔵
- 両者完了前の相手入力読み取り拒否を必須テストにする。🔵
- 両者完了後の公開結果読み取り許可を必須テストにする。🔵
- Storageパスのペア外アクセス拒否、所有者以外の不正アップロード拒否を検証する。🟡
