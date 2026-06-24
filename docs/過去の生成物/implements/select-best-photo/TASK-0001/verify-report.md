# TASK-0001 設定確認・動作テスト

## 確認概要

- **タスクID**: TASK-0001
- **確認内容**: Xcodeプロジェクト、Scheme、iOS設定、テストターゲット、ドキュメント更新の確認
- **実行日時**: 2026-06-22 15:17:03 JST
- **実行者**: Codex

## 設定確認結果

- [x] `SelectBestPhoto.xcodeproj/project.pbxproj` が存在する
- [x] `SelectBestPhoto.xcodeproj/xcshareddata/xcschemes/SelectBestPhoto.xcscheme` が存在する
- [x] `SelectBestPhoto/App/SelectBestPhotoApp.swift` が存在する
- [x] `SelectBestPhotoTests/SelectBestPhotoTests.swift` が存在する
- [x] `SelectBestPhotoUITests/SelectBestPhotoUITests.swift` が存在する
- [x] `IPHONEOS_DEPLOYMENT_TARGET = 18.0` が設定されている
- [x] `TARGETED_DEVICE_FAMILY = 1` が設定されている
- [x] `PRODUCT_BUNDLE_IDENTIFIER = com.hirotokouno.SelectBestPhoto` が設定されている
- [x] README/AGENTS にビルド・テストコマンドが記録されている

## 構文確認

```bash
plutil -lint SelectBestPhoto.xcodeproj/project.pbxproj
xmllint --noout SelectBestPhoto.xcodeproj/xcshareddata/xcschemes/SelectBestPhoto.xcscheme
```

結果:

- `project.pbxproj`: OK
- `SelectBestPhoto.xcscheme`: XML構文 OK

## ビルド・テスト確認

最初に指定された iPhone 16 Simulator 向けコマンドは、現在の開発者ディレクトリが Command Line Tools を向いていたため失敗しました。その後、Xcode本体を `DEVELOPER_DIR` で指定し、DerivedDataをワークスペース内に出す形で検証しました。

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/DerivedData build-for-testing
```

結果:

- アプリ本体ビルド: 成功
- `SelectBestPhotoTests` / `SelectBestPhotoUITests` の `build-for-testing`: 成功

対応したビルドエラー:

- `#Preview` マクロの外部実装解決に失敗したため、初期画面から preview ブロックを削除

未実行:

- Simulator上の `xcodebuild test` は sandbox 外で実行したが、テストランナー起動時に `NSMachErrorDomain Code=-308` で停止
- `simctl install booted .build/DerivedData/Build/Products/Debug-iphonesimulator/SelectBestPhoto.app` も停止し、CoreSimulatorService再起動後も改善しなかったため、ローカルSimulatorランタイムのinstall/launch経路に問題が残っている
- ローカルMacの負荷を抑える方針のため、今後のSimulator上テスト実行はCIまたは必要時に限定する

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild test -project SelectBestPhoto.xcodeproj -scheme SelectBestPhoto -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath .build/DerivedData
```

## 完了条件

- [x] `SelectBestPhoto.xcodeproj` が作成されている
- [x] Bundle Identifier、Deployment Target iOS 18、iPhone専用設定が反映されている
- [x] `SelectBestPhotoTests` と `SelectBestPhotoUITests` が作成されている
- [x] READMEまたはAGENTSのビルド/テストコマンド更新候補が確認できる

## 残リスク

- この環境では CoreSimulator の install/launch 経路が応答不全になっているため、ローカルSimulator上のUnit/UIテスト実行は未確認。
- Simulator上のテスト実行は、CI導入時に改めて確認する。
- 署名設定とTeam IDは個人環境依存のため未設定。

## 次の推奨タスク

- TASK-0002: Firebase SDK初期導入
