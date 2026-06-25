# text-candidate-category-mvp タスク概要

**作成日**: 2026-06-25
**プロジェクト期間**: 2026-06-25 - 2026-07-14（14作業日想定）
**推定工数**: 100時間
**総タスク数**: 14件

## 関連文書

- **要件定義書**: [requirements.md](../../spec/text-candidate-category-mvp/requirements.md)
- **受け入れ基準**: [acceptance-criteria.md](../../spec/text-candidate-category-mvp/acceptance-criteria.md)
- **設計文書**: [architecture.md](../../design/text-candidate-category-mvp/architecture.md)
- **データフロー図**: [dataflow.md](../../design/text-candidate-category-mvp/dataflow.md)
- **Firestore設計**: [firestore-schema.md](../../design/text-candidate-category-mvp/firestore-schema.md)
- **Security Rules設計**: [security-rules.md](../../design/text-candidate-category-mvp/security-rules.md)
- **Swift型設計**: [interfaces.swift.md](../../design/text-candidate-category-mvp/interfaces.swift.md)
- **画面構成設計**: [screen-structure.md](../../design/text-candidate-category-mvp/screen-structure.md)
- **コンテキストノート**: [note.md](../../spec/text-candidate-category-mvp/note.md)

## ヒアリング記録

| 質問日時 | カテゴリ | 質問内容 | 回答 | 信頼性への影響 |
| --- | --- | --- | --- | --- |
| 2026-06-25 | 作業規模 | タスク分割の作業規模 | AskUserQuestionツールが利用できないため、スキル推奨の詳細タスク分割を採用 | 詳細な実装手順、テスト、UI/UX、依存関係を含める前提を🟡として記録 |
| 2026-06-25 | タスク粒度 | 1日単位でよいか | 追加確認なし。AGENTS.mdの自律実行方針とスキル標準に合わせ、1日以内の粒度を採用 | 各タスク4〜8時間に分割し、実装可能性を維持 |
| 2026-06-25 | 優先順位 | 実装順序 | 設計文書のレイヤーに合わせ、ドメイン基盤 -> Firestore同期 -> SwiftUI UI -> 統合検証の順に設定 | 依存関係を明確化 |

## フェーズ構成

| フェーズ | 期間 | 成果物 | タスク数 | 工数 | ファイル |
|---------|------|--------|----------|------|----------|
| Phase 1 | 3日 | モデル、Repository境界、集計ロジック | 3件 | 18h | [TASK-0001〜0003](#phase-1-ドメイン基盤) |
| Phase 2 | 3日 | Firestore Repository、Security Rules | 3件 | 24h | [TASK-0004〜0006](#phase-2-firestore同期) |
| Phase 3 | 6日 | SwiftUI主要画面、状態制御、エラー表示 | 6件 | 46h | [TASK-0007〜0012](#phase-3-swiftui-ui) |
| Phase 4 | 2日 | 統合テスト、ビルド確認、完了検証 | 2件 | 12h | [TASK-0013〜0014](#phase-4-統合検証) |

## タスク番号管理

**使用済みタスク番号**: TASK-0001〜TASK-0014
**次回開始番号**: TASK-0015

## 全体進捗

- [ ] Phase 1: ドメイン基盤
- [ ] Phase 2: Firestore同期
- [ ] Phase 3: SwiftUI UI
- [ ] Phase 4: 統合検証

## マイルストーン

- **M1: ドメイン基盤完成** (2026-06-27): モデル、Repository境界、集計ロジック完了
- **M2: Firestore同期完成** (2026-07-02): Repository、Rules、Rulesテスト完了
- **M3: UI完成** (2026-07-10): 一覧、設定、候補、順位入力、待機、結果、リセット完了
- **M4: MVP検証完了** (2026-07-14): 統合テスト、ビルド、Rules検証完了

---

## Phase 1: ドメイン基盤

**期間**: 3日
**目標**: FirestoreやUIから独立したドメイン型と集計ロジックを固める
**成果物**: モデル、バリデーション、Repository protocol、PairContext、ResultCalculator

### タスク一覧

- [ ] [TASK-0001: テキスト候補型モデルと入力制約を実装する](TASK-0001.md) - 6h (TDD) 🔵
- [ ] [TASK-0002: Repository境界とPairContextを実装する](TASK-0002.md) - 6h (TDD) 🟡
- [ ] [TASK-0003: ポイント集計ロジックを実装する](TASK-0003.md) - 6h (TDD) 🔵

### 依存関係

```text
TASK-0001 -> TASK-0002
TASK-0001 -> TASK-0003
```

---

## Phase 2: Firestore同期

**期間**: 3日
**目標**: 部門、候補、入力、結果、リセットをFirestoreで同期し、公開条件をRulesで保護する
**成果物**: Firestore Repository、Security Rules、Rulesテスト

### タスク一覧

- [ ] [TASK-0004: 部門・候補のFirestore Repositoryを実装する](TASK-0004.md) - 8h (TDD) 🔵
- [ ] [TASK-0005: 入力・結果・リセットのFirestore Repositoryを実装する](TASK-0005.md) - 8h (TDD) 🔵
- [ ] [TASK-0006: Firestore Security RulesとRulesテストを実装する](TASK-0006.md) - 8h (TDD) 🔵

### 依存関係

```text
TASK-0001 + TASK-0002 -> TASK-0004
TASK-0003 + TASK-0004 -> TASK-0005
TASK-0005 -> TASK-0006
```

---

## Phase 3: SwiftUI UI

**期間**: 6日
**目標**: MVPの主要画面と一連の操作フローを実装する
**成果物**: フッタータブ、年別部門一覧、部門設定、候補管理、順位入力、待機、結果、リセット確認

### タスク一覧

- [ ] [TASK-0007: フッタータブと年別部門一覧を実装する](TASK-0007.md) - 8h (TDD) 🔵
- [ ] [TASK-0008: 部門作成・設定画面を実装する](TASK-0008.md) - 8h (TDD) 🔵
- [ ] [TASK-0009: 候補管理と画像プレースホルダーを実装する](TASK-0009.md) - 8h (TDD) 🔵
- [ ] [TASK-0010: 順位入力画面を実装する](TASK-0010.md) - 8h (TDD) 🔵
- [ ] [TASK-0011: 待機画面と結果表示画面を実装する](TASK-0011.md) - 8h (TDD) 🔵
- [ ] [TASK-0012: リセット確認と共通エラー表示を実装する](TASK-0012.md) - 6h (TDD) 🔵

### 依存関係

```text
TASK-0002 -> TASK-0007
TASK-0004 + TASK-0007 -> TASK-0008
TASK-0004 + TASK-0008 -> TASK-0009
TASK-0005 + TASK-0009 -> TASK-0010
TASK-0003 + TASK-0005 + TASK-0010 -> TASK-0011
TASK-0005 + TASK-0011 -> TASK-0012
```

---

## Phase 4: 統合検証

**期間**: 2日
**目標**: 受け入れ基準、公開条件、ビルドを確認しMVP完了状態にする
**成果物**: 統合テスト、Rulesテスト、ビルド確認、未検証リスク整理

### タスク一覧

- [ ] [TASK-0013: MVP主要フローの統合テストを実装する](TASK-0013.md) - 8h (TDD) 🔵
- [ ] [TASK-0014: ビルド確認とMVP完了検証を実施する](TASK-0014.md) - 4h (DIRECT) 🔵

### 依存関係

```text
TASK-0006 + TASK-0011 + TASK-0012 -> TASK-0013
TASK-0013 -> TASK-0014
```

---

## 信頼性レベルサマリー

### 全タスク統計

- **総タスク数**: 14件
- 🔵 **青信号**: 13件 (93%)
- 🟡 **黄信号**: 1件 (7%)
- 🔴 **赤信号**: 0件 (0%)

### フェーズ別信頼性

| フェーズ | 🔵 青 | 🟡 黄 | 🔴 赤 | 合計 |
|---------|-------|-------|-------|------|
| Phase 1 | 2 | 1 | 0 | 3 |
| Phase 2 | 3 | 0 | 0 | 3 |
| Phase 3 | 6 | 0 | 0 | 6 |
| Phase 4 | 2 | 0 | 0 | 2 |

**品質評価**: 高品質。要件定義、設計文書、画面構成、Firestore/Rules設計に基づくタスクが大半で、Repository境界とPairContextのみ実装都合の補完として🟡にしている。

## クリティカルパス

```text
TASK-0001 -> TASK-0002 -> TASK-0004 -> TASK-0005 -> TASK-0010 -> TASK-0011 -> TASK-0012 -> TASK-0013 -> TASK-0014
```

**クリティカルパス工数**: 64時間
**並行作業可能工数**: 36時間

## 洗い出し記録

- 基盤タスク: 3件
- Firestore/Rulesタスク: 3件
- フロントエンドタスク: 6件
- 統合タスク: 2件
- 洗い出したタスク総数: 14件
- 作成したタスクファイル数: 14件

## 次のステップ

タスクを実装するには:

- 全タスクを順番に実装: `/tsumiki:kairo-implement`
- 特定タスクを実装: `/tsumiki:kairo-implement TASK-0001`
