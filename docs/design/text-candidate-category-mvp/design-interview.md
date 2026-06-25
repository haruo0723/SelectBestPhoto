# テキスト候補型カスタム部門MVP 設計ヒアリング記録

**作成日**: 2026-06-25
**ヒアリング実施**: 既存情報ベースの差分ヒアリング

## ヒアリング目的

`docs/spec/text-candidate-category-mvp/` 配下の要件定義、ユーザーストーリー、受け入れ基準、コンテキストノートを確認し、設計出力の範囲とプロジェクト実態に合わせたテンプレート変換方針を確定する。

## 事前確認した既存情報

- `docs/spec/text-candidate-category-mvp/requirements.md`: MVP範囲、Firestore管理、公開条件、MVP対象外が定義済み
- `docs/spec/text-candidate-category-mvp/user-stories.md`: 部門と候補準備、順位入力、結果発表、再入力がMust Haveとして定義済み
- `docs/spec/text-candidate-category-mvp/acceptance-criteria.md`: 31件の受け入れ基準が定義済み
- `docs/spec/text-candidate-category-mvp/note.md`: 既存実装は初期土台のみ、Rulesは全拒否、対象機能未実装と確認済み
- `docs/tech-stack.md`: iOS 18以降、Swift 6、SwiftUI、Firebase Authentication、Cloud Firestore、Swift Package Managerを採用
- `SelectBestPhoto/App/AppDelegate.swift`: Firebase初期化のみ実装済み
- `SelectBestPhoto/Features/Home/HomeView.swift`: 最小ホーム画面のみ実装済み
- `firestore.rules`, `storage.rules`: 初期全拒否

## 質問と回答

### Q1: この設計の作業規模を選んでください。

**質問日時**: 2026-06-25
**カテゴリ**: アーキテクチャ
**背景**: `kairo-design` の出力範囲を、フル設計、軽量設計、カスタムのどれにするか確定するため。

**回答**: フル設計

**信頼性への影響**:

- architecture, dataflow, Swift型、Firestoreスキーマ、Security Rulesまで設計対象にする方針が確定した
- 設計範囲の信頼性が 🔴 から 🔵 に向上した

### Q2: TypeScript/API/SQLテンプレートを、このプロジェクト向けにどう置き換える方針にしますか？

**質問日時**: 2026-06-25
**カテゴリ**: 技術選択
**背景**: スキルの標準テンプレートはWeb/API/SQL寄りだが、対象プロジェクトはSwiftUI + Firebase SDK + Firestore直結のiOSアプリであるため。

**回答**: Swift/Firestore形式

**信頼性への影響**:

- `interfaces.ts` ではなく `interfaces.swift.md` を作成する方針が確定した
- `database-schema.sql` ではなく `firestore-schema.md` を作成する方針が確定した
- `api-endpoints.md` は生成せず、代わりに `security-rules.md` を作成する方針が確定した
- 出力形式の信頼性が 🔴 から 🔵 に向上した

### Q3: 既存実装の詳細分析を設計に含めますか？

**質問日時**: 2026-06-25
**カテゴリ**: 既存実装
**背景**: 対象機能は未実装で、既存コードは初期土台のみのため、詳細コード分析の費用対効果を確認するため。

**回答**: 最小分析

**信頼性への影響**:

- 既存実装分析はApp起点、Firebase初期化、HomeView、Rules初期状態の確認に留める方針が確定した
- 対象機能のモデル、Repository、画面、Rulesは未実装として設計する前提が確定した

## 確認できた事項

- MVPは手入力候補だけで縦に動かす
- CSV / XLSX読み込み、関連画像選択、Cloud Storage連携はMVP対象外
- 関連画像枠またはプレースホルダーはUIに用意する
- テキスト候補型カスタム部門は年間のみ
- 1年あたり30部門程度、1部門あたり100候補、最大50順位を扱う
- 確定後は候補と設定を変更できない
- 同名候補は別候補として許容する
- 両者完了前は相手入力内容と集計結果を表示せず、Firestore Rulesでも保護する

## 設計方針の決定事項

- SwiftUI + MVVM + Service/Repository構成にする
- Firestoreを正本とし、独自APIサーバーは設計しない
- Firestoreパスは `pairs/{pairId}/years/{year}/textCategories/{categoryId}` を中心にする
- ユーザー入力は `inputs/{userId}` として本人単位に分離する
- 結果は `results/{resultId}` に公開用結果として保持する
- Security Rules設計を設計成果物に含める

## 残課題

- 結果発表画面の具体的な演出詳細は、別途UI設計または実装フェーズで具体化する
- CSV / XLSX読み込みと関連画像保存の復帰フェーズは後続計画で決める
- Firestore Rulesの完全な式は実装フェーズでRulesテストと合わせて確定する

## 信頼性レベル分布

**ヒアリング前**:

- 🔵 青信号: 主要要件は定義済み
- 🟡 黄信号: 出力形式、既存実装分析範囲
- 🔴 赤信号: テンプレート変換方針

**ヒアリング後**:

- 🔵 青信号: フル設計、Swift/Firestore形式、最小コード分析が確定
- 🟡 黄信号: Rules式の実装詳細、結果演出詳細
- 🔴 赤信号: なし

## 関連文書

- [architecture.md](architecture.md)
- [dataflow.md](dataflow.md)
- [screen-structure.md](screen-structure.md)
- [interfaces.swift.md](interfaces.swift.md)
- [firestore-schema.md](firestore-schema.md)
- [security-rules.md](security-rules.md)
- [requirements.md](../../spec/text-candidate-category-mvp/requirements.md)
