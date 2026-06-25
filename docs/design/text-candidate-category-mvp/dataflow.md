# テキスト候補型カスタム部門MVP データフロー図

**作成日**: 2026-06-25
**関連アーキテクチャ**: [architecture.md](architecture.md)
**関連要件定義**: [requirements.md](../../spec/text-candidate-category-mvp/requirements.md)

## 信頼性レベル凡例

- 🔵 **青信号**: EARS要件定義書・設計文書・ユーザヒアリングを参考にした確実なフロー
- 🟡 **黄信号**: EARS要件定義書・設計文書・ユーザヒアリングから妥当な推測によるフロー
- 🔴 **赤信号**: EARS要件定義書・設計文書・ユーザヒアリングにない推測によるフロー

## 全体データフロー 🔵

**信頼性**: 🔵 `REQ-001`〜`REQ-019`, `REQ-401`〜`REQ-405`

```mermaid
flowchart TD
    User[ユーザー] --> View[SwiftUI View]
    View --> VM[ViewModel]
    VM --> Repo[TextCategoryRepository]
    Repo --> Firestore[(Cloud Firestore)]
    Firestore --> Rules[Security Rules]
    VM --> Calc[ResultCalculator]
    Calc --> VM
    VM --> View
    View --> User
```

- 画面はViewModelへ操作を渡す
- ViewModelはRepository経由でFirestoreを読み書きする
- Security Rulesはペア所属、本人入力、結果公開条件を検証する
- 集計はクライアント内の計算器で行い、両者完了後に公開結果として保存する

## 機能別フロー

### 部門作成・設定 🔵

**信頼性**: 🔵 `REQ-001`, `REQ-002`, `REQ-006`〜`REQ-008`, `UI-005`

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant V as 部門作成画面
    participant VM as ViewModel
    participant R as Repository
    participant F as Firestore

    U->>V: 年・部門名・順位数・ポイントを入力
    V->>VM: createCategory(draft)
    VM->>VM: 入力値を検証
    VM->>R: saveCategory(category)
    R->>F: textCategories/{categoryId} を作成
    F-->>R: 保存成功
    R-->>VM: TextCategory
    VM-->>V: 一覧へ反映
```

**検証**:

- 部門名は空にしない
- 入力対象順位、発表対象順位は1〜50
- 発表対象順位は入力対象順位以下
- 順位別ポイントは1以上

### 候補追加・編集・削除 🔵

**信頼性**: 🔵 `REQ-003`〜`REQ-005`, `REQ-107`, `REQ-108`, `REQ-110`

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant V as 候補管理画面
    participant VM as ViewModel
    participant R as Repository
    participant F as Firestore

    U->>V: 候補名を追加
    V->>VM: addCandidate(name)
    VM->>VM: 未確定状態と空文字を検証
    VM->>R: addCandidate(categoryId, name)
    R->>F: candidates/{autoId} を作成
    F-->>R: 保存成功
    R-->>VM: TextCandidate
    VM-->>V: 候補一覧更新
```

- 候補は自動IDで別候補として保存する
- 同名候補を禁止しない
- 確定済み部門では追加、編集、削除を拒否する
- 候補削除は確認UIを通す

### 候補・設定確定 🔵

**信頼性**: 🔵 `REQ-019`, `REQ-101`, `REQ-109`, `REQ-110`

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant V as 候補管理画面
    participant VM as ViewModel
    participant R as Repository
    participant F as Firestore

    U->>V: 候補・設定を確定
    V->>VM: confirmCategory()
    VM->>R: loadCategoryAndCandidates()
    R->>F: category と candidates を取得
    F-->>R: データ
    R-->>VM: 部門・候補
    VM->>VM: 候補数 >= 入力対象順位を検証
    VM->>R: markConfirmed()
    R->>F: confirmedAt と status を更新
    F-->>R: 更新成功
    R-->>VM: 確定済み部門
    VM-->>V: 順位入力へ遷移可能
```

- 候補数が入力対象順位未満の場合は確定できない
- 確定後は候補と設定を変更できない
- 既存入力との整合性を守るため、変更したい場合は部門全体リセットを行う

### 順位入力・入力完了 🔵

**信頼性**: 🔵 `REQ-009`, `REQ-010`, `REQ-102`, `REQ-203`

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant V as 順位入力画面
    participant VM as ViewModel
    participant R as Repository
    participant F as Firestore

    U->>V: 候補を順位スロットへ選択
    V->>VM: updateSelection(rank, candidateId)
    VM->>VM: 重複選択を検証
    VM->>R: saveDraftInput(userId, selections)
    R->>F: inputs/{userId} を upsert
    U->>V: 入力完了
    V->>VM: completeInput()
    VM->>VM: 順位数・重複を検証
    VM->>R: markInputCompleted(userId)
    R->>F: status=completed を保存
```

- 入力ドキュメントIDは`userId`
- 自分の入力だけ編集できる
- 同じ候補を複数順位に選べない
- 入力完了には入力対象順位分の選択が必要

### 待機・公開条件 🔵

**信頼性**: 🔵 `REQ-103`, `REQ-204`, `NFR-102`

```mermaid
flowchart TD
    A[自分の入力完了] --> B{相手も完了?}
    B -->|No| C[待機画面]
    C --> D[相手の入力状況だけ表示]
    C --> E[相手入力内容は読まない]
    C --> F[結果は表示しない]
    B -->|Yes| G[結果生成へ進む]
```

- 待機中は入力状況だけを表示する
- 相手の選択候補、順位、ポイント由来情報は表示しない
- Firestore Rulesでも両者完了前の相手入力と結果読み取りを拒否する

### 結果生成・表示 🔵

**信頼性**: 🔵 `REQ-011`, `REQ-012`, `REQ-104`, `REQ-205`

```mermaid
sequenceDiagram
    participant V as 結果画面
    participant VM as ViewModel
    participant R as Repository
    participant C as ResultCalculator
    participant F as Firestore

    V->>VM: openResult(categoryId)
    VM->>R: loadInputsIfBothCompleted()
    R->>F: category, candidates, inputs を取得
    F-->>R: 両者完了データ
    R-->>VM: 入力と設定
    VM->>C: calculate(inputs, pointsByRank)
    C-->>VM: TextCategoryResult
    VM->>R: saveResultIfNeeded(result)
    R->>F: results/{resultId} を保存
    VM-->>V: 発表対象順位まで表示
```

- 結果は発表対象順位まで表示する
- 候補名、合計ポイント、各ユーザーの順位由来ポイント、画像枠を表示する
- リセットなしで再表示できるよう結果を保持する
- 保存済み結果が現在世代と一致する場合は再利用する。現在世代とは、部門リセットごとに更新される `generation` が現在の部門・入力・結果で一致している状態を指す

### 部門全体リセット 🔵

**信頼性**: 🔵 `REQ-013`, `REQ-014`, `REQ-105`, `REQ-106`

```mermaid
sequenceDiagram
    participant U as ユーザー
    participant V as リセット確認
    participant VM as ViewModel
    participant R as Repository
    participant F as Firestore

    U->>V: リセット操作
    V->>U: 対象部門全体のリセット確認
    U->>V: 確定
    V->>VM: resetCategory()
    VM->>R: resetCategory(categoryId)
    R->>F: inputs と results を削除または無効化
    R->>F: category を未確定状態へ更新
    F-->>R: 更新成功
    R-->>VM: リセット後状態
    VM-->>V: 候補・設定編集へ戻す
```

- 候補と部門設定は残す
- 2人分の順位入力、入力状態、生成済み結果を削除または無効化する
- 部門は確定前状態へ戻る
- 再確定後、2人が再入力できる

## エラーハンドリングフロー 🔵

**信頼性**: 🔵 `EDGE-001`, `EDGE-002`

```mermaid
flowchart TD
    A[Firestore操作] --> B{成功?}
    B -->|Yes| C[画面状態を更新]
    B -->|No| D[ユーザー向けエラー表示]
    D --> E[入力中ローカル状態を保持]
    E --> F{再試行可能?}
    F -->|Yes| G[再試行導線]
    F -->|No| H[再取得導線]
```

- 保存失敗時は入力中の内容を可能な限り保持する
- リセット失敗時は削除済みに見せず、現状態を再取得する
- 内部エラー詳細、ペアコード、ユーザーID、候補内容を不要にログ出力しない

## データ整合性 🔵

**信頼性**: 🔵 `REQ-107`, `REQ-110`, `EDGE-003`

- 候補追加は自動IDで作成し、同時追加を失わない
- 確定後は候補と設定変更を禁止する
- 入力完了時に候補ID重複と順位数を検証する
- 結果生成時は、対象部門が確定済みで2人分の入力が完了していることを確認する
- リセット時は入力と結果を同じ操作単位で無効化し、部門だけ確定前へ戻す

## 関連文書

- [architecture.md](architecture.md)
- [screen-structure.md](screen-structure.md)
- [interfaces.swift.md](interfaces.swift.md)
- [firestore-schema.md](firestore-schema.md)
- [security-rules.md](security-rules.md)
- [requirements.md](../../spec/text-candidate-category-mvp/requirements.md)

## 信頼性レベルサマリー

- 🔵 青信号: 14件 (100%)
- 🟡 黄信号: 0件 (0%)
- 🔴 赤信号: 0件 (0%)

**品質評価**: 高品質。主要フローと結果再利用条件は要件、設計、ユーザー確認に直接紐づいている。
