# テキスト候補型カスタム部門MVP Security Rules設計

**作成日**: 2026-06-25
**関連設計**: [architecture.md](architecture.md)
**関連スキーマ**: [firestore-schema.md](firestore-schema.md)

## 信頼性レベル凡例

- 🔵 **青信号**: EARS要件定義書・設計文書・既存Rules方針を参考にした確実な定義
- 🟡 **黄信号**: EARS要件定義書・設計文書・既存Rules方針から妥当な推測による定義
- 🔴 **赤信号**: EARS要件定義書・設計文書・既存Rules方針にない推測による定義

## 方針 🔵

**信頼性**: 🔵 `REQ-402`〜`REQ-405`, `NFR-101`, `NFR-102`

- Firebase Authenticationで認証済みのユーザーだけを許可する
- `pairs/{pairId}.memberIds` に含まれる2人だけがペア配下へアクセスできる
- 入力ドキュメントは本人だけが作成・更新できる
- 両者完了前は相手の入力内容を読めない
- 結果は両者完了後のみ読める
- MVPではStorage読み書きを許可しない

## 既存Rules状態 🔵

**信頼性**: 🔵 `firestore.rules`, `storage.rules`

現状はFirestore / Storageとも全拒否である。

```text
allow read, write: if false;
```

MVP実装時は、この全拒否をペアスコープの許可ルールへ置き換える。

## Firestoreルール構造 🔵

**信頼性**: 🔵 `REQ-402`〜`REQ-405`, `NFR-101`, `NFR-102`, ユーザー確認2026-06-25

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function pairDoc(pairId) {
      return get(/databases/$(database)/documents/pairs/$(pairId));
    }

    function isPairMember(pairId) {
      return signedIn()
        && pairDoc(pairId).data.memberIds.hasAny([request.auth.uid]);
    }

    match /pairs/{pairId} {
      allow read: if isPairMember(pairId);

      match /years/{year}/textCategories/{categoryId} {
        allow read: if isPairMember(pairId);
        allow create, update, delete: if isPairMember(pairId);

        match /candidates/{candidateId} {
          allow read: if isPairMember(pairId);
          allow create, update, delete: if isPairMember(pairId);
        }

        match /inputs/{userId} {
          allow read: if isOwnInput(userId) || bothInputsCompleted(pairId, year, categoryId);
          allow create, update: if isOwnInput(userId);
          allow delete: if isPairMember(pairId);
        }

        match /results/{resultId} {
          allow read: if isPairMember(pairId) && resultIsPublic(pairId, year, categoryId);
          allow create: if isPairMember(pairId) && bothInputsCompleted(pairId, year, categoryId);
          allow update, delete: if isPairMember(pairId);
        }
      }
    }
  }
}
```

上記は実装時の骨子であり、実際のRulesではFirestore Rulesで利用可能な式に合わせて関数を調整する。

## アクセス制御要件

### 部門 🔵

**信頼性**: 🔵 `REQ-001`, `REQ-401`, `NFR-101`

- ペアメンバーは部門を読める
- ペアメンバーは部門を作成できる
- `draft`状態の部門のみ設定更新できる
- `confirmed`以降の設定変更は拒否する
- リセットは入力と結果の無効化を伴うため、実装ではRepository側のバッチ処理とRules検証を組み合わせる

### 候補 🔵

**信頼性**: 🔵 `REQ-003`〜`REQ-005`, `REQ-107`, `REQ-110`

- ペアメンバーは候補を読める
- 親部門が`draft`の場合のみ候補を作成、更新、削除できる
- 親部門が`confirmed`または`resultAvailable`の場合は候補変更を拒否する
- 同名候補は禁止しない
- MVPでは画像Storageパスを候補へ書き込ませない

### 入力 🔵

**信頼性**: 🔵 `REQ-010`, `REQ-102`, `REQ-402`, `REQ-403`, `REQ-405`

- `inputs/{userId}` の`userId`は `request.auth.uid` と一致する必要がある
- 本人だけが自分の入力を作成・更新できる
- 相手の入力は編集できない
- 両者完了前は相手の入力を読めない
- 両者完了後は結果表示に必要な範囲で読める

### 結果 🔵

**信頼性**: 🔵 `REQ-103`, `REQ-104`, `NFR-102`

- 結果はペアメンバーのみ読める
- 結果は両者完了後のみ読める
- 両者完了前の結果作成と読み取りは拒否する
- `generation`が親部門の現世代と一致する結果だけを有効とする

## データ検証

### 部門ドキュメント 🔵

**信頼性**: 🔵 `REQ-006`〜`REQ-008`, `EDGE-102`, `EDGE-103`

RulesまたはRepositoryで以下を検証する。

- `name` は空ではない
- `inputRankLimit` は1〜50
- `revealRankLimit` は1〜`inputRankLimit`
- `pointsByRank` は最大50件
- 各ポイントは1以上

Firestore Rulesで複雑な配列検証が難しい場合は、Repositoryと単体テストで補完し、Rulesでは型と上限の最低限を守る。🟡

### 入力ドキュメント 🔵

**信頼性**: 🔵 `REQ-101`, `REQ-102`

RulesまたはRepositoryで以下を検証する。

- `userId` は認証uidと一致
- `selections` は最大50件
- 完了時に重複候補がない
- 完了時に入力対象順位分の候補が選択されている

重複候補検証はRulesで表現が難しい場合があるため、RepositoryとRulesテストの組み合わせで実装する。🟡

## Storage Rules 🔵

**信頼性**: 🔵 `REQ-407`

MVPでは関連画像の選択・保存・Cloud Storage書き込みを行わないため、Storage Rulesは全拒否を維持する。

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## Rulesテスト方針 🔵

**信頼性**: 🔵 `TC-NFR-101-01`, `tests/firebase/rules.test.mjs`

実装フェーズでは、Firebase Emulator Suiteで以下を検証する。

- ペア外ユーザーは部門、候補、入力、結果を読めない
- ペアメンバーは部門と候補を読める
- 本人は自分の入力を書ける
- 相手の入力は書けない
- 両者完了前は相手入力を読めない
- 両者完了前は結果を読めない
- 両者完了後は結果を読める
- Storage書き込みは拒否される

## 信頼性レベルサマリー

- 🔵 青信号: 11件 (85%)
- 🟡 黄信号: 2件 (15%)
- 🔴 赤信号: 0件 (0%)

**品質評価**: 高品質。アクセス制御方針、公開条件、世代一致は確認済み。Firestore Rulesで表現しづらい配列検証と重複検証だけを実装時検証項目として残している。
