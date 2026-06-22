# select-best-photo タスク概要

**作成日**: 2026-06-22
**推定工数**: 230時間
**総タスク数**: 37件
**タスク粒度**: 基盤は1日単位、Firebase/メディア/UI統合は半日寄りの混在

## 関連文書

- **要件定義**: [requirements.md](../../spec/select-best-photo/requirements.md)
- **受け入れ基準**: [acceptance-criteria.md](../../spec/select-best-photo/acceptance-criteria.md)
- **技術スタック**: [tech-stack.md](../../tech-stack.md)
- **アーキテクチャ**: [architecture.md](../../design/select-best-photo/architecture.md)
- **データフロー**: [dataflow.md](../../design/select-best-photo/dataflow.md)
- **Firestore設計**: [firestore-schema.md](../../design/select-best-photo/firestore-schema.md)
- **Storage設計**: [storage-schema.md](../../design/select-best-photo/storage-schema.md)
- **Security Rules設計**: [security-rules.md](../../design/select-best-photo/security-rules.md)
- **Swift型設計**: [interfaces.swift.md](../../design/select-best-photo/interfaces.swift.md)

## フェーズ構成

| フェーズ | 成果物 | タスク数 | 工数 |
| --- | --- | ---: | ---: |
| Phase 1 基盤構築 | Xcode、Firebase SDK、CI、Emulator | 5 | 32h |
| Phase 2 モデル・サービス基盤 | Swift型、Service境界、Rules | 6 | 38h |
| Phase 3 メディア処理 | PhotosUI、圧縮、Live Photos、Storage | 6 | 44h |
| Phase 4 入力・設定機能 | プロフィール、月間、年間、部門入力 | 9 | 58h |
| Phase 5 公開結果・閲覧UI | 公開制御、結果発表、過去閲覧、リセット | 6 | 36h |
| Phase 6 統合検証 | 単体、Emulator、UI、メディア、CI検証 | 5 | 22h |

## タスク番号管理

- **使用済みタスク番号**: TASK-0001 - TASK-0037
- **次回開始番号**: TASK-0038

## 全体進捗

- [ ] Phase 1: 基盤構築
- [ ] Phase 2: モデル・サービス基盤
- [ ] Phase 3: メディア処理
- [ ] Phase 4: 入力・設定機能
- [ ] Phase 5: 公開結果・閲覧UI
- [ ] Phase 6: 統合検証

## Phase 1: 基盤構築

- [x] [TASK-0001: Xcodeプロジェクト作成とiOS設定](TASK-0001.md) - 8h (DIRECT) 🔵 - 完了: 2026-06-22
- [ ] [TASK-0002: Firebase SDK初期導入](TASK-0002.md) - 6h (DIRECT) 🔵
- [ ] [TASK-0003: App起点とディレクトリ構成整備](TASK-0003.md) - 6h (DIRECT) 🔵
- [ ] [TASK-0004: Lint/Format/CI初期設定](TASK-0004.md) - 6h (DIRECT) 🔵
- [ ] [TASK-0005: Firebase Emulator検証環境](TASK-0005.md) - 6h (DIRECT) 🔵

## Phase 2: モデル・サービス基盤

- [ ] [TASK-0006: 共通ドメインモデルとFirestore Codableモデル](TASK-0006.md) - 8h (TDD) 🔵
- [ ] [TASK-0007: 共通エラー、ログ制御、ユーティリティ](TASK-0007.md) - 6h (TDD) 🔵
- [ ] [TASK-0008: Auth/PairServiceとペアコード](TASK-0008.md) - 8h (TDD) 🔵
- [ ] [TASK-0009: Firestore参照パスとRepository境界](TASK-0009.md) - 6h (TDD) 🔵
- [ ] [TASK-0010: Firestore Rules初期実装とEmulatorテスト](TASK-0010.md) - 6h (DIRECT) 🔵
- [ ] [TASK-0011: Storage Rules初期実装とEmulatorテスト](TASK-0011.md) - 4h (DIRECT) 🟡

## Phase 3: メディア処理

- [ ] [TASK-0012: PhotosUI選択とアップロード前確認UI](TASK-0012.md) - 6h (TDD) 🔵
- [ ] [TASK-0013: 写真圧縮、サムネイル生成、位置情報除外](TASK-0013.md) - 8h (TDD) 🔵
- [ ] [TASK-0014: 動画圧縮、サムネイル生成、再生確認](TASK-0014.md) - 8h (TDD) 🔵
- [ ] [TASK-0015: Live Photos保存・再生方式](TASK-0015.md) - 10h (TDD) 🔵
- [ ] [TASK-0016: MediaAssetServiceとStorageアップロード](TASK-0016.md) - 8h (TDD) 🔵
- [ ] [TASK-0017: 参照スコープ更新と派生ファイル削除](TASK-0017.md) - 4h (TDD) 🔵

## Phase 4: 入力・設定機能

- [ ] [TASK-0018: プロフィールと年月別設定画面](TASK-0018.md) - 6h (TDD) 🔵
- [ ] [TASK-0019: 月間ベスト入力フロー](TASK-0019.md) - 8h (TDD) 🔵
- [ ] [TASK-0020: 年間候補選択フロー](TASK-0020.md) - 6h (TDD) 🔵
- [ ] [TASK-0021: 年間TOP5入力フロー](TASK-0021.md) - 6h (TDD) 🔵
- [ ] [TASK-0022: 敗者復活枠入力・編集・リセット](TASK-0022.md) - 6h (TDD) 🔵
- [ ] [TASK-0023: メディア型カスタム部門](TASK-0023.md) - 6h (TDD) 🔵
- [ ] [TASK-0024: テキスト候補型カスタム部門設定](TASK-0024.md) - 8h (TDD) 🔵
- [ ] [TASK-0025: CSV/手入力候補管理と関連画像](TASK-0025.md) - 8h (TDD) 🔵
- [ ] [TASK-0026: XLSX読み込み技術検証](TASK-0026.md) - 4h (DIRECT) 🔵

## Phase 5: 公開結果・閲覧UI

- [ ] [TASK-0027: 入力状態同期と相手入力非表示制御](TASK-0027.md) - 6h (TDD) 🔵
- [ ] [TASK-0028: RevealResult生成トランザクション](TASK-0028.md) - 8h (TDD) 🔵
- [ ] [TASK-0029: 結果発表画面](TASK-0029.md) - 8h (TDD) 🔵
- [ ] [TASK-0030: 過去結果一覧と再視聴](TASK-0030.md) - 4h (TDD) 🔵
- [ ] [TASK-0031: リセット確認UIと世代管理](TASK-0031.md) - 6h (TDD) 🔵
- [ ] [TASK-0032: アクセシビリティとiPhone表示確認](TASK-0032.md) - 4h (DIRECT) 🔵

## Phase 6: 統合検証

- [ ] [TASK-0033: ユニットテスト整備](TASK-0033.md) - 6h (DIRECT) 🟡
- [ ] [TASK-0034: Firebase Emulator統合テスト](TASK-0034.md) - 6h (DIRECT) 🔵
- [ ] [TASK-0035: XCUITest主要フロー](TASK-0035.md) - 4h (DIRECT) 🟡
- [ ] [TASK-0036: メディア処理の実機/Simulator検証](TASK-0036.md) - 4h (DIRECT) 🔵
- [ ] [TASK-0037: ビルド、Lint、Format、CI最終確認](TASK-0037.md) - 2h (DIRECT) 🔵

## クリティカルパス

```text
TASK-0001 -> TASK-0002 -> TASK-0003 -> TASK-0006 -> TASK-0008 -> TASK-0009 -> TASK-0010
  -> TASK-0016 -> TASK-0019 -> TASK-0027 -> TASK-0028 -> TASK-0029 -> TASK-0034 -> TASK-0037
```

## 信頼性レベルサマリー

- 🔵 青信号: 35件
- 🟡 黄信号: 2件
- 🔴 赤信号: 0件
- **品質評価**: 高品質。主要タスクは要件定義、設計文書、ヒアリング記録に基づく。

## 次のステップ

- 全タスク順番に実装: `/tsumiki:kairo-implement`
- 特定タスクを実装: `/tsumiki:kairo-implement TASK-0001`
