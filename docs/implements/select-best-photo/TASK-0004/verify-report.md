# TASK-0004 設定確認・動作テスト

## 確認概要

- **タスクID**: TASK-0004
- **確認内容**: Lint/Format/CI初期設定の確認
- **確認日**: 2026-06-24
- **確認者**: Codex

## 確認項目

### 設定ファイル

- [x] `.swiftlint.yml` が存在する
- [x] `.swiftformat` が存在する
- [x] `.github/workflows/ci.yml` が存在し、build/test/lint/formatチェックの土台がある
- [x] `README.md` にローカル実行コマンドが記載されている

### 構文・設定確認

- [x] GitHub Actions workflowはYAMLとして読める構成
- [x] Xcode project、scheme、deployment targetの名称は既存プロジェクトに合っている
- [x] `TASK-0001` が完了済みであることを確認

### 実行確認

- [x] `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -version`
- [x] `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData build`
- [x] `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swiftlint`
- [x] `swiftformat --lint .`

確認結果:

```text
Xcode 26.3
Build version 17C529
```

Build確認結果:

```text
** BUILD SUCCEEDED **
```

Lint/Format確認結果:

```text
swiftlint: Found 0 violations, 0 serious in 5 files.
swiftformat --lint .: 0/5 files require formatting, 61 files skipped.
```

未実行:

- `xcodebuild test`: Simulator実行はCIまたは必要時に限定

## 発見事項

- 現在の `xcode-select` はCommand Line Toolsを指しているため、`xcodebuild` 実行時はREADME記載どおり `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` を指定する。
- `swiftlint` もSourceKit参照のため、同じく `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` 指定で確認した。
- GitHub Actionsでは既定のXcodeでbuild/testを実行する既存土台がある。

## 完了判定

- [x] SwiftLint設定ファイルが追加されている
- [x] SwiftFormat設定ファイルが追加されている
- [x] GitHub Actionsでbuild/test/lint/formatチェックの土台がある
- [x] ローカル実行コマンドがREADMEへ反映されている

## 次の推奨タスク

- TASK-0005: Firebase Emulator検証環境
