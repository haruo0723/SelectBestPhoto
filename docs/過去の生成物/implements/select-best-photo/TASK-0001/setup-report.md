# TASK-0001 設定作業実行

## 作業概要

- **タスクID**: TASK-0001
- **作業内容**: Xcodeプロジェクト作成とiOS設定
- **実行日時**: 2026-06-22 15:17:03 JST
- **実行者**: Codex

## 設計文書参照

- `docs/tasks/select-best-photo/TASK-0001.md`
- `docs/tasks/select-best-photo/overview.md`
- `docs/spec/select-best-photo/requirements.md`
- `docs/design/select-best-photo/architecture.md`
- `docs/tech-stack.md`

## 実行した作業

### 1. Xcodeプロジェクト作成

- `SelectBestPhoto.xcodeproj` を作成
- 共有Scheme `SelectBestPhoto` を作成
- Bundle Identifier を `com.hirotokouno.SelectBestPhoto` に設定
- Deployment Target を iOS 18.0 に設定
- iPhone専用として `TARGETED_DEVICE_FAMILY = 1` を設定

### 2. 最小アプリ構成

- `SelectBestPhoto/App/SelectBestPhotoApp.swift` を追加
- `SelectBestPhoto/Features/Home/HomeView.swift` を追加
- SwiftUI + NavigationStack の最小起動画面を追加
- Xcode CLI環境で `#Preview` マクロ解決に失敗したため、初期構成では preview ブロックを含めない

### 3. テストターゲット

- `SelectBestPhotoTests` を追加
- `SelectBestPhotoUITests` を追加
- Swift Testing の最小ユニットテストを追加
- XCUITest の最小起動確認を追加

### 4. ドキュメント更新

- `README.md` に開発環境、ビルド、テストコマンドを追記
- `AGENTS.md` のビルド/テストコマンドとディレクトリ構成を更新
- Xcode本体を `DEVELOPER_DIR` で指定し、DerivedDataを `.build/DerivedData` に出すコマンドを記録

## 作業結果

- [x] `SelectBestPhoto.xcodeproj` 作成完了
- [x] iOS 18.0 設定完了
- [x] iPhone専用設定完了
- [x] Unit/UI test target 作成完了
- [x] README/AGENTS 更新完了

## 遭遇した問題と解決方法

### Xcode本体未選択とSimulator未検出

- **発生状況**: `xcodebuild -showsdks` 実行時
- **エラーメッセージ**: `xcode-select: error: tool 'xcodebuild' requires Xcode, but active developer directory '/Library/Developer/CommandLineTools' is a command line tools instance`
- **対応**: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` を指定して Xcode 本体を使用
- **追加対応**: この sandbox では具体的な iPhone 16 Simulator が見つからないため、`generic/platform=iOS Simulator` と `.build/DerivedData` を使ってビルド確認を実施

## 次のステップ

- 具体的なiPhone Simulatorが使える環境で `xcodebuild test` を実行する
- TASK-0002 で Firebase SDK を Swift Package Manager により追加する
