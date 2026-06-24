# TASK-0004 設定作業実行

## 作業概要

- **タスクID**: TASK-0004
- **作業内容**: Lint/Format/CI初期設定
- **実行日**: 2026-06-24
- **実行者**: Codex

## 参照文書

- `docs/tasks/select-best-photo/TASK-0004.md`
- `docs/tasks/select-best-photo/overview.md`
- `docs/tech-stack.md`
- `docs/design/select-best-photo/architecture.md`

## 実行した作業

### 1. SwiftLint設定

**作成ファイル**: `.swiftlint.yml`

- `.build` と `SelectBestPhoto.xcodeproj` を除外
- 初期開発で過度に厳しくならないよう、行長やファイル長は緩めに設定
- レポーターはXcode向けに設定

### 2. SwiftFormat設定

**作成ファイル**: `.swiftformat`

- Swift 6.0を指定
- インデントと改行コードを明示
- `.build` と `SelectBestPhoto.xcodeproj` を除外

### 3. GitHub Actions設定確認

**確認ファイル**: `.github/workflows/ci.yml`

- 既存workflowにbuild/test/lint/formatチェックの土台があることを確認
- `pull_request` と主要ブランチへの `push` を対象に設定済み
- `xcodebuild build`
- `xcodebuild test`
- `.swiftlint.yml` がある場合の `swiftlint`
- `.swiftformat` がある場合の `swiftformat --lint .`

### 4. README更新

**更新ファイル**: `README.md`

- SwiftLint / SwiftFormatのローカル実行コマンドを追記
- Homebrewによる導入コマンドを追記
- CI設定ファイルの場所と実行内容を追記

## 作業結果

- [x] SwiftLint設定ファイルを追加
- [x] SwiftFormat設定ファイルを追加
- [x] GitHub Actions workflowのbuild/test/lint/format土台を確認
- [x] READMEへローカル実行コマンドを反映

## 注意事項

- 軽量対応のため、既存Swiftファイルへの自動整形は実行していない。
- ローカル環境に `swiftlint` / `swiftformat` は未導入だったため、インストールを伴う検証は行っていない。
