# TASK-0003 設定作業実行

## 作業概要

- **タスクID**: TASK-0003
- **作業内容**: App起点、Firebase初期化位置、NavigationStack初期画面、推奨ディレクトリ構成の整備
- **実行日時**: 2026-06-24
- **実行者**: Codex

## 設計文書参照

- `docs/tasks/select-best-photo/TASK-0003.md`
- `docs/tasks/select-best-photo/overview.md`
- `docs/tech-stack.md`
- `docs/design/select-best-photo/architecture.md`

## 実行した作業

### 1. ディレクトリ構成の作成

`SelectBestPhoto` 配下に以下を作成した。

- `Models`
- `Services/Firebase`
- `Services/Media`
- `Services/Cache`
- `Services/Storage`
- `Shared/Components`
- `Shared/Extensions`
- `Shared/Utilities`
- `Features/Pairing`
- `Features/MonthlyBest`
- `Features/AnnualBest`
- `Features/CustomCategories`
- `Features/TextCategories`
- `Features/RevivalPicks`
- `Features/ResultReveal`
- `Features/Settings`

### 2. Firebase初期化起点の追加

`SelectBestPhoto/App/AppDelegate.swift` を追加し、SwiftUI App起点から `UIApplicationDelegateAdaptor` で呼び出す構成にした。

`GoogleService-Info.plist` が未投入の開発初期状態では初期化をスキップし、設定ファイル投入後に `FirebaseApp.configure()` を実行する。

### 3. Xcodeプロジェクト参照の更新

`SelectBestPhoto.xcodeproj/project.pbxproj` を更新し、`AppDelegate.swift` をアプリターゲットの Sources に追加した。推奨ディレクトリもXcodeグループとして参照できるようにした。

### 4. README更新

現在の構成とFirebase初期化位置を `README.md` に記録した。

## 作業結果

- [x] 推奨ディレクトリ構成を作成
- [x] Firebase初期化の起点をApp層に集約
- [x] NavigationStackベースの初期画面を維持
- [x] ViewがFirebase SDKへ直接依存しない構成を維持
- [x] Xcodeプロジェクト参照を更新

## 次のステップ

- `/tsumiki:direct-verify select-best-photo TASK-0003` 相当の検証を実行する。
