# テキスト候補型カスタム部門MVP コンテキストノート

**作成日**: 2026-06-24
**要件名**: text-candidate-category-mvp

## 参照した現行情報

- `docs/requirements.md`: アプリ全体の要件正本。特に 6.3 結果発表、6.6 テキスト候補型カスタム部門、6.10 バックエンド、6.11 設定、8 受け入れ基準、9 決定事項を参照。
- `docs/tech-stack.md`: iOS 18以降、Swift 6、SwiftUI、Firebase Authentication、Cloud Firestore、Cloud Storage、Swift Package Manager、Firebase Emulator Suite 方針を参照。
- `README.md`: 現在の構成、Firebase Emulator、GoogleService-Info.plist の扱い、ビルド・テスト方針を参照。
- 現行実装: `SelectBestPhoto/App/AppDelegate.swift`、`SelectBestPhoto/App/SelectBestPhotoApp.swift`、`SelectBestPhoto/Features/Home/HomeView.swift`、`firestore.rules`、`storage.rules`、`tests/firebase/rules.test.mjs` を確認。

## 参照対象外

- `docs/過去の生成物/` 配下の過去生成ドキュメントは、今回の要件定義の根拠として使用しない。
- 以前 `requirements.md` 全体で回した要件・設計・タスク成果物は参照せず、新しいMVP仕様として作り直す。

## 現在の実装状況

- TASK-0001〜0005相当の環境構築フェーズのみ実装済みというユーザー申告を前提にする。🔵 *ユーザヒアリング2026-06-24*
- Xcodeプロジェクト、アプリ起点、最小HomeView、Firebase SDK導入、Firebase EmulatorとRulesテスト土台が存在する。🔵 *現行実装確認*
- Firestore Rules / Storage Rules は初期状態で全拒否。ペア単位のアクセス制御や結果公開条件は未実装。🔵 *現行実装確認*
- テキスト候補型カスタム部門のモデル、Repository、画面、同期、結果表示は未実装。🔵 *現行実装確認*

## MVPスコープ方針

- MVPでは「テキスト候補型カスタム部門」を単独で縦に動かす。
- 対象は年ごとの複数部門作成、候補の手入力管理、候補・部門設定の確定、順位入力、部門別ポイント設定、2人の入力状態同期、両者完了後の結果表示、部門リセットまで。
- CSV / XLSX 読み込み、関連画像添付、Cloud Storage連携は後続フェーズへ分離する。🔵 *ユーザヒアリング2026-06-24*
- 月間ベスト、年間ベスト、メディア型カスタム部門、敗者復活枠は今回のMVP対象外。ただしペア、ユーザー、年、入力状態、結果公開条件の共通基盤は将来機能と競合しない設計にする。🔵 *ユーザー指定スコープ外*

## 技術制約

- 対象は iOS 18以降、iPhone専用、SwiftUI。🔵 *AGENTS.md / docs/tech-stack.md*
- バックエンドは Firebase Anonymous Authentication + ペアコード、Cloud Firestore。🔵 *docs/requirements.md 6.10 / docs/tech-stack.md*
- MVP本体で関連画像の選択・保存・アップロードを扱わないため、Cloud StorageはMVPの必須データ経路に含めない。ただし候補一覧、候補編集、結果画面には関連画像枠のUIを用意する。🔵 *ユーザヒアリング2026-06-24*
- 結果発表の公開条件は、クライアント表示だけでなくFirestore Rulesでも保護する設計を前提にする。🔵 *docs/tech-stack.md*

## 未決定として残す事項

- CSV / XLSX 読み込みをどのフェーズで復帰させるか。🟡
- 関連画像添付とCloud Storage保存をどのフェーズで復帰させるか。🟡
- 結果発表画面の具体的な演出詳細。🔵 *docs/requirements.md 10*
